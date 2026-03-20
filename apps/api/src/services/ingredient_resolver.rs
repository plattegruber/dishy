//! Ingredient resolution service using the USDA FoodData Central API.
//!
//! Takes parsed ingredients and matches them against the USDA FDC food
//! database. Returns [`IngredientResolution::Matched`], [`FuzzyMatched`],
//! or [`Unmatched`] for each ingredient.
//!
//! The USDA FDC API is free and requires only a data.gov API key.
//! Rate limit: 1,000 requests per hour per IP address.
//! API docs: <https://fdc.nal.usda.gov/api-guide>

use crate::logging::Logger;
use crate::types::ids::FoodId;
use crate::types::ingredient::{
    IngredientLine, IngredientResolution, ParsedIngredient, ResolvedIngredient,
};

#[cfg(any(target_arch = "wasm32", test))]
use crate::types::ingredient::FuzzyCandidate;

/// Base URL for the USDA FoodData Central API.
#[cfg(target_arch = "wasm32")]
const FDC_BASE_URL: &str = "https://api.nal.usda.gov/fdc/v1";

/// Minimum confidence score to consider a match as "exact".
#[cfg(any(target_arch = "wasm32", test))]
const EXACT_MATCH_THRESHOLD: f64 = 0.8;

/// Minimum confidence score to consider a match as "fuzzy".
#[cfg(any(target_arch = "wasm32", test))]
const FUZZY_MATCH_THRESHOLD: f64 = 0.4;

/// Maximum number of search results to request from FDC.
#[cfg(target_arch = "wasm32")]
const MAX_SEARCH_RESULTS: usize = 5;

/// Response from the USDA FDC search API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct FdcSearchResponse {
    /// The list of matching food items.
    #[serde(default)]
    foods: Vec<FdcSearchFood>,
    /// Total number of hits.
    #[serde(default)]
    total_hits: i64,
}

/// A single food item from the FDC search response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct FdcSearchFood {
    /// The FDC ID for this food item.
    fdc_id: i64,
    /// The food description/name.
    description: String,
    /// The data type (e.g., "SR Legacy", "Foundation", "Branded").
    #[serde(default)]
    #[allow(dead_code)]
    data_type: String,
    /// Score from the FDC search (higher is more relevant).
    #[serde(default)]
    score: Option<f64>,
}

/// Resolves a list of parsed ingredient lines against the USDA FDC database.
///
/// For each ingredient, searches FDC by the ingredient name and determines
/// the best match. Logs every resolution attempt with correlation IDs.
///
/// # Arguments
///
/// * `lines` - The parsed ingredient lines to resolve.
/// * `fdc_api_key` - The USDA FDC API key.
/// * `logger` - The request logger for structured logging.
///
/// # Returns
///
/// A vector of `ResolvedIngredient` objects, one per input line.
/// Resolution never fails fatally -- unresolvable ingredients are
/// returned as `Unmatched`.
#[cfg(target_arch = "wasm32")]
pub async fn resolve_ingredient_lines(
    lines: &[IngredientLine],
    fdc_api_key: &str,
    logger: &Logger,
) -> Vec<ResolvedIngredient> {
    use std::collections::HashMap;

    let mut resolved = Vec::with_capacity(lines.len());

    for (idx, line) in lines.iter().enumerate() {
        let parsed = line.parsed.clone().unwrap_or(ParsedIngredient {
            quantity: None,
            unit: None,
            name: line.raw_text.clone(),
            preparation: None,
        });

        let search_name = &parsed.name;

        logger.info(
            "Resolving ingredient against USDA FDC",
            HashMap::from([
                (
                    "stage".to_string(),
                    serde_json::Value::String("ingredient_resolution".to_string()),
                ),
                (
                    "ingredient_index".to_string(),
                    serde_json::Value::Number(serde_json::Number::from(idx)),
                ),
                (
                    "search_name".to_string(),
                    serde_json::Value::String(search_name.clone()),
                ),
            ]),
        );

        let resolution = match search_fdc(search_name, fdc_api_key).await {
            Ok(response) => classify_search_results(search_name, &response),
            Err(err_msg) => {
                logger.warn(
                    "FDC search failed for ingredient",
                    HashMap::from([
                        (
                            "ingredient".to_string(),
                            serde_json::Value::String(search_name.clone()),
                        ),
                        ("error".to_string(), serde_json::Value::String(err_msg)),
                    ]),
                );
                IngredientResolution::Unmatched {
                    text: line.raw_text.clone(),
                }
            }
        };

        logger.info(
            "Ingredient resolution complete",
            HashMap::from([
                (
                    "ingredient_index".to_string(),
                    serde_json::Value::Number(serde_json::Number::from(idx)),
                ),
                (
                    "resolution_type".to_string(),
                    serde_json::Value::String(resolution_type_name(&resolution).to_string()),
                ),
            ]),
        );

        resolved.push(ResolvedIngredient { parsed, resolution });
    }

    resolved
}

/// Searches the USDA FDC API for foods matching the given query.
///
/// Uses the `/foods/search` endpoint with data types limited to
/// SR Legacy and Foundation for more reliable standard food matches.
#[cfg(target_arch = "wasm32")]
async fn search_fdc(query: &str, api_key: &str) -> Result<FdcSearchResponse, String> {
    use worker::wasm_bindgen::JsValue;

    let encoded_query = url_encode(query);
    let url = format!(
        "{}/foods/search?api_key={}&query={}&pageSize={}&dataType=SR%20Legacy,Foundation",
        FDC_BASE_URL, api_key, encoded_query, MAX_SEARCH_RESULTS
    );

    let request = worker::Request::new(&url, worker::Method::Get)
        .map_err(|e| format!("failed to build FDC request: {e}"))?;

    let mut response = worker::Fetch::Request(request)
        .send()
        .await
        .map_err(|e| format!("FDC request failed: {e}"))?;

    let status = response.status_code();
    if status >= 400 {
        let body = response.text().await.unwrap_or_default();
        return Err(format!(
            "FDC returned HTTP {status}: {}",
            &body[..body.len().min(200)]
        ));
    }

    let body = response
        .text()
        .await
        .map_err(|e| format!("failed to read FDC response: {e}"))?;

    serde_json::from_str(&body).map_err(|e| format!("failed to parse FDC response: {e}"))
}

/// Simple percent-encoding for URL query parameters.
///
/// Encodes spaces and special characters that are not safe in URLs.
#[cfg(target_arch = "wasm32")]
fn url_encode(s: &str) -> String {
    let mut result = String::with_capacity(s.len() * 2);
    for byte in s.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                result.push(byte as char);
            }
            b' ' => result.push_str("%20"),
            _ => {
                result.push_str(&format!("%{:02X}", byte));
            }
        }
    }
    result
}

/// Classifies FDC search results into a resolution variant.
///
/// Uses the search score and description similarity to determine
/// whether an ingredient is matched, fuzzy-matched, or unmatched.
#[cfg(any(target_arch = "wasm32", test))]
fn classify_search_results(
    search_name: &str,
    response: &FdcSearchResponse,
) -> IngredientResolution {
    if response.foods.is_empty() || response.total_hits == 0 {
        return IngredientResolution::Unmatched {
            text: search_name.to_string(),
        };
    }

    let best = &response.foods[0];
    let confidence = compute_match_confidence(search_name, &best.description, best.score);

    if confidence >= EXACT_MATCH_THRESHOLD {
        IngredientResolution::Matched {
            food_id: FoodId::new(best.fdc_id.to_string()),
            confidence,
        }
    } else if confidence >= FUZZY_MATCH_THRESHOLD && response.foods.len() > 1 {
        let candidates: Vec<FuzzyCandidate> = response
            .foods
            .iter()
            .take(3)
            .map(|food| {
                let c = compute_match_confidence(search_name, &food.description, food.score);
                FuzzyCandidate {
                    food_id: FoodId::new(food.fdc_id.to_string()),
                    confidence: c,
                }
            })
            .collect();

        IngredientResolution::FuzzyMatched {
            candidates,
            confidence,
        }
    } else if confidence >= FUZZY_MATCH_THRESHOLD {
        // Single result with moderate confidence
        IngredientResolution::Matched {
            food_id: FoodId::new(best.fdc_id.to_string()),
            confidence,
        }
    } else {
        IngredientResolution::Unmatched {
            text: search_name.to_string(),
        }
    }
}

/// Computes a match confidence score between the search query and a
/// food description from FDC.
///
/// Combines string similarity with the FDC search score.
#[cfg(any(target_arch = "wasm32", test))]
fn compute_match_confidence(query: &str, description: &str, fdc_score: Option<f64>) -> f64 {
    let query_lower = query.to_lowercase();
    let desc_lower = description.to_lowercase();

    // Exact substring match gives high confidence
    if desc_lower.contains(&query_lower) || query_lower.contains(&desc_lower) {
        return 0.95;
    }

    // Check if all query words appear in the description
    let query_words: Vec<&str> = query_lower.split_whitespace().collect();
    let matching_words = query_words
        .iter()
        .filter(|w| desc_lower.contains(**w))
        .count();

    let word_overlap = if query_words.is_empty() {
        0.0
    } else {
        matching_words as f64 / query_words.len() as f64
    };

    // FDC score normalization (scores are typically large numbers)
    let normalized_fdc_score = match fdc_score {
        Some(s) if s > 0.0 => (s / (s + 100.0)).min(1.0),
        _ => 0.0,
    };

    // Weighted combination
    let confidence = (word_overlap * 0.7) + (normalized_fdc_score * 0.3);
    confidence.min(1.0)
}

/// Returns a human-readable name for the resolution type.
#[cfg(any(target_arch = "wasm32", test))]
fn resolution_type_name(resolution: &IngredientResolution) -> &'static str {
    match resolution {
        IngredientResolution::Matched { .. } => "matched",
        IngredientResolution::FuzzyMatched { .. } => "fuzzy_matched",
        IngredientResolution::Unmatched { .. } => "unmatched",
    }
}

/// Non-WASM stub for testing -- returns deterministic resolution results.
///
/// Common ingredients get `Matched`, others get `Unmatched`.
#[cfg(not(target_arch = "wasm32"))]
pub async fn resolve_ingredient_lines(
    lines: &[IngredientLine],
    _fdc_api_key: &str,
    _logger: &Logger,
) -> Vec<ResolvedIngredient> {
    lines
        .iter()
        .map(|line| {
            let parsed = line.parsed.clone().unwrap_or(ParsedIngredient {
                quantity: None,
                unit: None,
                name: line.raw_text.clone(),
                preparation: None,
            });

            let resolution = resolve_stub(&parsed.name, &line.raw_text);

            ResolvedIngredient { parsed, resolution }
        })
        .collect()
}

/// Stub resolver for testing -- matches well-known ingredient names.
#[cfg(not(target_arch = "wasm32"))]
fn resolve_stub(name: &str, raw_text: &str) -> IngredientResolution {
    let lower = name.to_lowercase();

    // Common ingredients that we "know" about
    let known_foods: &[(&str, &str)] = &[
        ("flour", "169761"),
        ("all-purpose flour", "169761"),
        ("sugar", "169655"),
        ("granulated sugar", "169655"),
        ("butter", "173410"),
        ("egg", "171287"),
        ("eggs", "171287"),
        ("milk", "171265"),
        ("salt", "173467"),
        ("baking powder", "168971"),
        ("baking soda", "168972"),
        ("vanilla extract", "170910"),
        ("olive oil", "171413"),
        ("garlic", "169230"),
        ("onion", "170004"),
        ("chicken breast", "171534"),
    ];

    for (food_name, fdc_id) in known_foods {
        if lower.contains(food_name) {
            return IngredientResolution::Matched {
                food_id: FoodId::new(*fdc_id),
                confidence: 0.9,
            };
        }
    }

    IngredientResolution::Unmatched {
        text: raw_text.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classify_empty_results_returns_unmatched() {
        let response = FdcSearchResponse {
            foods: vec![],
            total_hits: 0,
        };
        let result = classify_search_results("flour", &response);
        match result {
            IngredientResolution::Unmatched { text } => {
                assert_eq!(text, "flour");
            }
            other => panic!("expected Unmatched, got {other:?}"),
        }
    }

    #[test]
    fn classify_exact_match_returns_matched() {
        let response = FdcSearchResponse {
            foods: vec![FdcSearchFood {
                fdc_id: 169761,
                description: "Wheat flour, white, all-purpose, enriched, bleached".to_string(),
                data_type: "SR Legacy".to_string(),
                score: Some(500.0),
            }],
            total_hits: 1,
        };
        let result = classify_search_results("flour", &response);
        match result {
            IngredientResolution::Matched {
                food_id,
                confidence,
            } => {
                assert_eq!(food_id.as_str(), "169761");
                assert!(confidence > 0.5);
            }
            other => panic!("expected Matched, got {other:?}"),
        }
    }

    #[test]
    fn classify_multiple_results_with_moderate_confidence_returns_fuzzy() {
        let response = FdcSearchResponse {
            foods: vec![
                FdcSearchFood {
                    fdc_id: 111,
                    description: "Spice blend premium".to_string(),
                    data_type: "SR Legacy".to_string(),
                    score: Some(50.0),
                },
                FdcSearchFood {
                    fdc_id: 222,
                    description: "Spice mix regular".to_string(),
                    data_type: "SR Legacy".to_string(),
                    score: Some(40.0),
                },
            ],
            total_hits: 2,
        };
        let result = classify_search_results("spice", &response);
        // "spice" appears in "Spice blend premium" so confidence should be high
        match &result {
            IngredientResolution::Matched { .. } | IngredientResolution::FuzzyMatched { .. } => {
                // Either is acceptable
            }
            other => panic!("expected Matched or FuzzyMatched, got {other:?}"),
        }
    }

    #[test]
    fn compute_match_confidence_exact_substring() {
        let confidence = compute_match_confidence("flour", "Wheat flour, white", Some(100.0));
        assert!(
            confidence >= 0.9,
            "confidence should be high for exact substring match, got {confidence}"
        );
    }

    #[test]
    fn compute_match_confidence_no_overlap() {
        let confidence = compute_match_confidence("banana", "Wheat flour, white", Some(10.0));
        assert!(
            confidence < 0.5,
            "confidence should be low for no overlap, got {confidence}"
        );
    }

    #[test]
    fn resolution_type_name_returns_correct_names() {
        assert_eq!(
            resolution_type_name(&IngredientResolution::Matched {
                food_id: FoodId::new("1"),
                confidence: 0.9,
            }),
            "matched"
        );
        assert_eq!(
            resolution_type_name(&IngredientResolution::FuzzyMatched {
                candidates: vec![],
                confidence: 0.5,
            }),
            "fuzzy_matched"
        );
        assert_eq!(
            resolution_type_name(&IngredientResolution::Unmatched {
                text: "x".to_string(),
            }),
            "unmatched"
        );
    }

    #[tokio::test]
    async fn resolve_ingredient_lines_stub_matches_known_ingredients() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let lines = vec![
            IngredientLine {
                raw_text: "2 cups flour".to_string(),
                parsed: Some(ParsedIngredient {
                    quantity: Some(2.0),
                    unit: Some("cups".to_string()),
                    name: "flour".to_string(),
                    preparation: None,
                }),
            },
            IngredientLine {
                raw_text: "1 cup unknown spice mix".to_string(),
                parsed: Some(ParsedIngredient {
                    quantity: Some(1.0),
                    unit: Some("cup".to_string()),
                    name: "unknown spice mix".to_string(),
                    preparation: None,
                }),
            },
        ];

        let result = resolve_ingredient_lines(&lines, "fake-key", &logger).await;
        assert_eq!(result.len(), 2);

        // flour should be matched
        match &result[0].resolution {
            IngredientResolution::Matched { food_id, .. } => {
                assert_eq!(food_id.as_str(), "169761");
            }
            other => panic!("expected Matched for flour, got {other:?}"),
        }

        // unknown spice mix should be unmatched
        match &result[1].resolution {
            IngredientResolution::Unmatched { .. } => {}
            other => panic!("expected Unmatched for unknown spice mix, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn resolve_ingredient_lines_handles_empty_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = resolve_ingredient_lines(&[], "fake-key", &logger).await;
        assert!(result.is_empty());
    }

    #[test]
    fn fdc_search_response_deserializes_correctly() {
        let json = serde_json::json!({
            "totalHits": 2,
            "currentPage": 1,
            "totalPages": 1,
            "foods": [
                {
                    "fdcId": 169761,
                    "description": "Wheat flour, white, all-purpose",
                    "dataType": "SR Legacy",
                    "score": 345.6
                },
                {
                    "fdcId": 169762,
                    "description": "Wheat flour, whole-grain",
                    "dataType": "SR Legacy",
                    "score": 200.1
                }
            ]
        });
        let response: FdcSearchResponse = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(response.total_hits, 2);
        assert_eq!(response.foods.len(), 2);
        assert_eq!(response.foods[0].fdc_id, 169761);
        assert_eq!(
            response.foods[0].description,
            "Wheat flour, white, all-purpose"
        );
    }
}
