//! Nutrition computation service using USDA FoodData Central.
//!
//! Takes resolved ingredients and computes per-recipe and per-serving
//! nutrition facts by fetching nutrient data from the USDA FDC API.
//! Handles partial matches gracefully -- if some ingredients are unmatched,
//! the status is set to `Estimated` rather than failing entirely.
//!
//! USDA FDC nutrient IDs for primary macros:
//! - Energy (kcal): nutrient number 208
//! - Protein: nutrient number 203
//! - Total lipid (fat): nutrient number 204
//! - Carbohydrate: nutrient number 205

use crate::logging::Logger;
use crate::types::ingredient::{IngredientResolution, ResolvedIngredient};
use crate::types::nutrition::{NutritionComputation, NutritionFacts, NutritionStatus};

/// Base URL for the USDA FoodData Central API.
#[cfg(target_arch = "wasm32")]
const FDC_BASE_URL: &str = "https://api.nal.usda.gov/fdc/v1";

/// USDA nutrient number for energy (kcal).
#[cfg(any(target_arch = "wasm32", test))]
const NUTRIENT_ENERGY: &str = "208";

/// USDA nutrient number for protein.
#[cfg(any(target_arch = "wasm32", test))]
const NUTRIENT_PROTEIN: &str = "203";

/// USDA nutrient number for total lipid (fat).
#[cfg(any(target_arch = "wasm32", test))]
const NUTRIENT_FAT: &str = "204";

/// USDA nutrient number for carbohydrate.
#[cfg(any(target_arch = "wasm32", test))]
const NUTRIENT_CARBS: &str = "205";

/// Response from the USDA FDC food detail endpoint.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct FdcFoodDetail {
    /// The FDC ID.
    #[allow(dead_code)]
    fdc_id: i64,
    /// The food description.
    #[allow(dead_code)]
    description: String,
    /// Nutrient data for this food.
    #[serde(default)]
    food_nutrients: Vec<FdcNutrient>,
}

/// A single nutrient value from the FDC response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct FdcNutrient {
    /// The nutrient details.
    #[serde(default)]
    nutrient: Option<FdcNutrientInfo>,
    /// The amount of this nutrient per 100g of the food.
    #[serde(default)]
    amount: Option<f64>,
}

/// Nutrient metadata from the FDC response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct FdcNutrientInfo {
    /// The nutrient number (e.g., "208" for energy).
    #[serde(default)]
    number: Option<String>,
    /// The nutrient name.
    #[serde(default)]
    #[allow(dead_code)]
    name: Option<String>,
    /// The unit of measurement.
    #[serde(default)]
    #[allow(dead_code)]
    unit_name: Option<String>,
}

/// Per-100g nutrition facts extracted from an FDC food detail response.
#[derive(Debug, Clone, Default)]
struct NutrientsPer100g {
    /// Calories per 100g.
    calories: f64,
    /// Protein per 100g in grams.
    protein: f64,
    /// Carbs per 100g in grams.
    carbs: f64,
    /// Fat per 100g in grams.
    fat: f64,
}

/// Computes nutrition facts from a list of resolved ingredients.
///
/// For each ingredient with a matched FDC food ID, fetches the nutrient
/// data and aggregates across all ingredients. Computes per-serving
/// values when the serving count is known.
///
/// # Arguments
///
/// * `ingredients` - The resolved ingredients to compute nutrition for.
/// * `servings` - Optional serving count for per-serving calculation.
/// * `fdc_api_key` - The USDA FDC API key.
/// * `logger` - The request logger for structured logging.
///
/// # Returns
///
/// A `NutritionComputation` with aggregated facts and an appropriate
/// status based on how many ingredients were successfully looked up.
#[cfg(target_arch = "wasm32")]
pub async fn compute_nutrition_from_ingredients(
    ingredients: &[ResolvedIngredient],
    servings: Option<i32>,
    fdc_api_key: &str,
    logger: &Logger,
) -> NutritionComputation {
    use std::collections::HashMap;

    if ingredients.is_empty() {
        return NutritionComputation {
            per_recipe: NutritionFacts {
                calories: 0.0,
                protein: 0.0,
                carbs: 0.0,
                fat: 0.0,
            },
            per_serving: None,
            status: NutritionStatus::Unavailable,
        };
    }

    let mut total = NutrientsPer100g::default();
    let mut matched_count = 0usize;
    let mut total_count = ingredients.len();

    for (idx, ingredient) in ingredients.iter().enumerate() {
        let food_id = match &ingredient.resolution {
            IngredientResolution::Matched { food_id, .. } => Some(food_id.as_str()),
            IngredientResolution::FuzzyMatched { candidates, .. } => {
                candidates.first().map(|c| c.food_id.as_str())
            }
            IngredientResolution::Unmatched { .. } => None,
        };

        let fdc_id = match food_id {
            Some(id) => id,
            None => continue,
        };

        logger.debug(
            "Fetching nutrition for ingredient",
            HashMap::from([
                (
                    "ingredient_index".to_string(),
                    serde_json::Value::Number(serde_json::Number::from(idx)),
                ),
                (
                    "fdc_id".to_string(),
                    serde_json::Value::String(fdc_id.to_string()),
                ),
            ]),
        );

        match fetch_food_nutrients(fdc_id, fdc_api_key).await {
            Ok(nutrients) => {
                // Scale nutrients based on quantity if available
                // FDC nutrients are per 100g; we use a rough estimate
                // that 1 "serving" of an ingredient is ~100g unless
                // we have better conversion data
                let scale = ingredient.parsed.quantity.unwrap_or(1.0);

                total.calories += nutrients.calories * scale;
                total.protein += nutrients.protein * scale;
                total.carbs += nutrients.carbs * scale;
                total.fat += nutrients.fat * scale;
                matched_count += 1;
            }
            Err(err_msg) => {
                logger.warn(
                    "Failed to fetch nutrition for ingredient",
                    HashMap::from([
                        (
                            "fdc_id".to_string(),
                            serde_json::Value::String(fdc_id.to_string()),
                        ),
                        ("error".to_string(), serde_json::Value::String(err_msg)),
                    ]),
                );
            }
        }
    }

    let per_recipe = NutritionFacts {
        calories: round2(total.calories),
        protein: round2(total.protein),
        carbs: round2(total.carbs),
        fat: round2(total.fat),
    };

    let per_serving = servings.filter(|&s| s > 0).map(|s| {
        let sf = f64::from(s);
        NutritionFacts {
            calories: round2(total.calories / sf),
            protein: round2(total.protein / sf),
            carbs: round2(total.carbs / sf),
            fat: round2(total.fat / sf),
        }
    });

    let status = if matched_count == 0 {
        NutritionStatus::Unavailable
    } else if matched_count == total_count {
        NutritionStatus::Calculated
    } else {
        NutritionStatus::Estimated
    };

    logger.info(
        "Nutrition computation complete",
        HashMap::from([
            (
                "matched_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(matched_count)),
            ),
            (
                "total_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(total_count)),
            ),
            (
                "status".to_string(),
                serde_json::Value::String(format!("{status:?}")),
            ),
            (
                "total_calories".to_string(),
                serde_json::json!(per_recipe.calories),
            ),
        ]),
    );

    // Suppress unused variable warning
    let _ = total_count;

    NutritionComputation {
        per_recipe,
        per_serving,
        status,
    }
}

/// Fetches nutrient data for a single food item from the FDC API.
#[cfg(target_arch = "wasm32")]
async fn fetch_food_nutrients(fdc_id: &str, api_key: &str) -> Result<NutrientsPer100g, String> {
    let url = format!("{}/food/{}?api_key={}", FDC_BASE_URL, fdc_id, api_key);

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

    let detail: FdcFoodDetail =
        serde_json::from_str(&body).map_err(|e| format!("failed to parse FDC food detail: {e}"))?;

    Ok(extract_macros(&detail.food_nutrients))
}

/// Extracts the four primary macronutrients from an FDC nutrient list.
#[cfg(any(target_arch = "wasm32", test))]
fn extract_macros(nutrients: &[FdcNutrient]) -> NutrientsPer100g {
    let mut result = NutrientsPer100g::default();

    for nutrient in nutrients {
        let number = nutrient
            .nutrient
            .as_ref()
            .and_then(|n| n.number.as_deref())
            .unwrap_or_default();

        let amount = nutrient.amount.unwrap_or(0.0);

        match number {
            n if n == NUTRIENT_ENERGY => result.calories = amount,
            n if n == NUTRIENT_PROTEIN => result.protein = amount,
            n if n == NUTRIENT_FAT => result.fat = amount,
            n if n == NUTRIENT_CARBS => result.carbs = amount,
            _ => {}
        }
    }

    result
}

/// Rounds a float to 2 decimal places.
fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

/// Non-WASM stub for testing -- returns deterministic nutrition results.
///
/// For testing, computes nutrition from the stub-resolved ingredients
/// using hardcoded per-100g values for known FDC IDs.
#[cfg(not(target_arch = "wasm32"))]
pub async fn compute_nutrition_from_ingredients(
    ingredients: &[ResolvedIngredient],
    servings: Option<i32>,
    _fdc_api_key: &str,
    _logger: &Logger,
) -> NutritionComputation {
    if ingredients.is_empty() {
        return NutritionComputation {
            per_recipe: NutritionFacts {
                calories: 0.0,
                protein: 0.0,
                carbs: 0.0,
                fat: 0.0,
            },
            per_serving: None,
            status: NutritionStatus::Unavailable,
        };
    }

    let mut total = NutrientsPer100g::default();
    let mut matched_count = 0usize;
    let total_count = ingredients.len();

    for ingredient in ingredients {
        let food_id = match &ingredient.resolution {
            IngredientResolution::Matched { food_id, .. } => Some(food_id.as_str()),
            IngredientResolution::FuzzyMatched { candidates, .. } => {
                candidates.first().map(|c| c.food_id.as_str())
            }
            IngredientResolution::Unmatched { .. } => None,
        };

        if food_id.is_none() {
            continue;
        }

        // Stub: use rough per-100g values for common foods
        let nutrients = stub_nutrients_per_100g(food_id.unwrap_or_default());
        let scale = ingredient.parsed.quantity.unwrap_or(1.0);

        total.calories += nutrients.calories * scale;
        total.protein += nutrients.protein * scale;
        total.carbs += nutrients.carbs * scale;
        total.fat += nutrients.fat * scale;
        matched_count += 1;
    }

    let per_recipe = NutritionFacts {
        calories: round2(total.calories),
        protein: round2(total.protein),
        carbs: round2(total.carbs),
        fat: round2(total.fat),
    };

    let per_serving = servings.filter(|&s| s > 0).map(|s| {
        let sf = f64::from(s);
        NutritionFacts {
            calories: round2(total.calories / sf),
            protein: round2(total.protein / sf),
            carbs: round2(total.carbs / sf),
            fat: round2(total.fat / sf),
        }
    });

    let status = if matched_count == 0 {
        NutritionStatus::Unavailable
    } else if matched_count == total_count {
        NutritionStatus::Calculated
    } else {
        NutritionStatus::Estimated
    };

    NutritionComputation {
        per_recipe,
        per_serving,
        status,
    }
}

/// Returns approximate per-100g nutrition for known FDC IDs (test stub).
#[cfg(not(target_arch = "wasm32"))]
fn stub_nutrients_per_100g(fdc_id: &str) -> NutrientsPer100g {
    match fdc_id {
        "169761" => NutrientsPer100g {
            // flour
            calories: 364.0,
            protein: 10.3,
            carbs: 76.3,
            fat: 1.0,
        },
        "169655" => NutrientsPer100g {
            // sugar
            calories: 387.0,
            protein: 0.0,
            carbs: 100.0,
            fat: 0.0,
        },
        "173410" => NutrientsPer100g {
            // butter
            calories: 717.0,
            protein: 0.85,
            carbs: 0.06,
            fat: 81.1,
        },
        "171287" => NutrientsPer100g {
            // eggs
            calories: 155.0,
            protein: 13.0,
            carbs: 1.1,
            fat: 11.0,
        },
        _ => NutrientsPer100g {
            calories: 100.0,
            protein: 5.0,
            carbs: 15.0,
            fat: 3.0,
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::ids::FoodId;
    use crate::types::ingredient::{IngredientResolution, ParsedIngredient};

    #[test]
    fn extract_macros_from_fdc_nutrients() {
        let nutrients = vec![
            FdcNutrient {
                nutrient: Some(FdcNutrientInfo {
                    number: Some("208".to_string()),
                    name: Some("Energy".to_string()),
                    unit_name: Some("kcal".to_string()),
                }),
                amount: Some(364.0),
            },
            FdcNutrient {
                nutrient: Some(FdcNutrientInfo {
                    number: Some("203".to_string()),
                    name: Some("Protein".to_string()),
                    unit_name: Some("g".to_string()),
                }),
                amount: Some(10.3),
            },
            FdcNutrient {
                nutrient: Some(FdcNutrientInfo {
                    number: Some("204".to_string()),
                    name: Some("Total lipid (fat)".to_string()),
                    unit_name: Some("g".to_string()),
                }),
                amount: Some(1.0),
            },
            FdcNutrient {
                nutrient: Some(FdcNutrientInfo {
                    number: Some("205".to_string()),
                    name: Some("Carbohydrate, by difference".to_string()),
                    unit_name: Some("g".to_string()),
                }),
                amount: Some(76.3),
            },
            FdcNutrient {
                nutrient: Some(FdcNutrientInfo {
                    number: Some("291".to_string()),
                    name: Some("Fiber, total dietary".to_string()),
                    unit_name: Some("g".to_string()),
                }),
                amount: Some(2.7),
            },
        ];

        let macros = extract_macros(&nutrients);
        assert_eq!(macros.calories, 364.0);
        assert_eq!(macros.protein, 10.3);
        assert_eq!(macros.fat, 1.0);
        assert_eq!(macros.carbs, 76.3);
    }

    #[test]
    fn extract_macros_handles_empty_nutrients() {
        let macros = extract_macros(&[]);
        assert_eq!(macros.calories, 0.0);
        assert_eq!(macros.protein, 0.0);
        assert_eq!(macros.fat, 0.0);
        assert_eq!(macros.carbs, 0.0);
    }

    #[test]
    fn round2_rounds_correctly() {
        assert_eq!(round2(1.234), 1.23);
        assert_eq!(round2(1.235), 1.24);
        assert_eq!(round2(1.0), 1.0);
        assert_eq!(round2(0.0), 0.0);
    }

    #[tokio::test]
    async fn compute_nutrition_empty_ingredients() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = compute_nutrition_from_ingredients(&[], None, "fake-key", &logger).await;
        assert_eq!(result.status, NutritionStatus::Unavailable);
        assert_eq!(result.per_recipe.calories, 0.0);
        assert!(result.per_serving.is_none());
    }

    #[tokio::test]
    async fn compute_nutrition_all_matched() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let ingredients = vec![
            ResolvedIngredient {
                parsed: ParsedIngredient {
                    quantity: Some(2.0),
                    unit: Some("cups".to_string()),
                    name: "flour".to_string(),
                    preparation: None,
                },
                resolution: IngredientResolution::Matched {
                    food_id: FoodId::new("169761"),
                    confidence: 0.95,
                },
            },
            ResolvedIngredient {
                parsed: ParsedIngredient {
                    quantity: Some(1.0),
                    unit: Some("cup".to_string()),
                    name: "sugar".to_string(),
                    preparation: None,
                },
                resolution: IngredientResolution::Matched {
                    food_id: FoodId::new("169655"),
                    confidence: 0.9,
                },
            },
        ];

        let result =
            compute_nutrition_from_ingredients(&ingredients, Some(8), "fake-key", &logger).await;
        assert_eq!(result.status, NutritionStatus::Calculated);
        assert!(result.per_recipe.calories > 0.0);
        assert!(result.per_serving.is_some());
        let per_serving = result.per_serving.expect("should have per_serving");
        assert!(per_serving.calories > 0.0);
    }

    #[tokio::test]
    async fn compute_nutrition_partial_match_returns_estimated() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let ingredients = vec![
            ResolvedIngredient {
                parsed: ParsedIngredient {
                    quantity: Some(1.0),
                    unit: Some("cup".to_string()),
                    name: "flour".to_string(),
                    preparation: None,
                },
                resolution: IngredientResolution::Matched {
                    food_id: FoodId::new("169761"),
                    confidence: 0.95,
                },
            },
            ResolvedIngredient {
                parsed: ParsedIngredient {
                    quantity: None,
                    unit: None,
                    name: "secret spice".to_string(),
                    preparation: None,
                },
                resolution: IngredientResolution::Unmatched {
                    text: "secret spice".to_string(),
                },
            },
        ];

        let result =
            compute_nutrition_from_ingredients(&ingredients, None, "fake-key", &logger).await;
        assert_eq!(result.status, NutritionStatus::Estimated);
    }

    #[tokio::test]
    async fn compute_nutrition_no_matches_returns_unavailable() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let ingredients = vec![ResolvedIngredient {
            parsed: ParsedIngredient {
                quantity: None,
                unit: None,
                name: "mystery ingredient".to_string(),
                preparation: None,
            },
            resolution: IngredientResolution::Unmatched {
                text: "mystery ingredient".to_string(),
            },
        }];

        let result =
            compute_nutrition_from_ingredients(&ingredients, Some(4), "fake-key", &logger).await;
        assert_eq!(result.status, NutritionStatus::Unavailable);
    }

    #[test]
    fn fdc_food_detail_deserializes() {
        let json = serde_json::json!({
            "fdcId": 169761,
            "description": "Wheat flour, white, all-purpose",
            "foodNutrients": [
                {
                    "nutrient": {
                        "number": "208",
                        "name": "Energy",
                        "unitName": "kcal"
                    },
                    "amount": 364.0
                },
                {
                    "nutrient": {
                        "number": "203",
                        "name": "Protein",
                        "unitName": "g"
                    },
                    "amount": 10.3
                }
            ]
        });

        let detail: FdcFoodDetail = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(detail.fdc_id, 169761);
        assert_eq!(detail.food_nutrients.len(), 2);

        let macros = extract_macros(&detail.food_nutrients);
        assert_eq!(macros.calories, 364.0);
        assert_eq!(macros.protein, 10.3);
    }
}
