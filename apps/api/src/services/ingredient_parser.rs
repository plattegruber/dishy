//! Ingredient parsing service using the Anthropic Claude API.
//!
//! Parses free-text ingredient lines into structured [`ParsedIngredient`] objects
//! using Claude's tool_use for reliable, deterministic extraction. Handles edge
//! cases like "a pinch of salt", "2-3 cloves garlic, minced", and "1 cup
//! all-purpose flour, sifted".
//!
//! This service is called during the `parse_ingredients` pipeline stage.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;
use crate::types::ingredient::{IngredientLine, ParsedIngredient};

/// The Claude model to use for ingredient parsing.
#[cfg(any(target_arch = "wasm32", test))]
const CLAUDE_MODEL: &str = "claude-sonnet-4-20250514";

/// Maximum tokens in the Claude response for ingredient parsing.
#[cfg(any(target_arch = "wasm32", test))]
const MAX_TOKENS: u32 = 4096;

/// Request body for the Anthropic Messages API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct MessagesRequest {
    /// The Claude model identifier.
    model: String,
    /// Maximum output tokens.
    max_tokens: u32,
    /// Tools available to the model.
    tools: Vec<Tool>,
    /// Instruction to force tool use.
    tool_choice: ToolChoice,
    /// The conversation messages.
    messages: Vec<Message>,
    /// System prompt.
    system: String,
}

/// A tool definition for the Messages API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct Tool {
    /// Tool name.
    name: String,
    /// Human-readable description.
    description: String,
    /// JSON Schema for the tool's input parameters.
    input_schema: serde_json::Value,
}

/// Forces the model to use a specific tool.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct ToolChoice {
    /// The type of tool choice constraint.
    #[serde(rename = "type")]
    choice_type: String,
    /// The name of the required tool.
    name: String,
}

/// A single message in the conversation.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct Message {
    /// The role (user, assistant).
    role: String,
    /// The message content.
    content: String,
}

/// Response from the Anthropic Messages API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[allow(dead_code)]
struct MessagesResponse {
    /// The content blocks in the response.
    content: Vec<ContentBlock>,
}

/// A single content block in the response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(tag = "type")]
#[allow(dead_code)]
enum ContentBlock {
    /// A text block.
    #[serde(rename = "text")]
    Text {
        /// The text content.
        #[allow(dead_code)]
        text: String,
    },
    /// A tool use block containing the structured parsing result.
    #[serde(rename = "tool_use")]
    ToolUse {
        /// The tool name.
        #[allow(dead_code)]
        name: String,
        /// The tool's structured input.
        input: serde_json::Value,
    },
}

/// The parsed ingredients response from Claude's tool_use.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
struct ParsedIngredientsResult {
    /// The list of parsed ingredient objects.
    ingredients: Vec<ParsedIngredientJson>,
}

/// A single parsed ingredient from Claude's output.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[allow(dead_code)]
struct ParsedIngredientJson {
    /// The original raw text of the ingredient line.
    raw_text: String,
    /// Numeric quantity, if present.
    quantity: Option<f64>,
    /// Unit of measurement, if present.
    unit: Option<String>,
    /// The ingredient name.
    name: String,
    /// Preparation instructions, if present.
    preparation: Option<String>,
}

/// Builds the JSON schema for the ingredient parsing tool.
///
/// This schema constrains Claude to return a structured array of parsed
/// ingredients matching our domain types.
#[cfg(any(target_arch = "wasm32", test))]
fn build_parsing_tool() -> Tool {
    Tool {
        name: "parse_ingredients".to_string(),
        description: "Parse a list of free-text ingredient lines into structured ingredient data. For each line, extract the quantity, unit, ingredient name, and preparation method.".to_string(),
        input_schema: serde_json::json!({
            "type": "object",
            "properties": {
                "ingredients": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "raw_text": {
                                "type": "string",
                                "description": "The original ingredient line text, exactly as provided."
                            },
                            "quantity": {
                                "type": "number",
                                "description": "The numeric quantity. Convert fractions to decimals (1/2 = 0.5, 1/4 = 0.25). For ranges like '2-3', use the lower value. For 'a pinch', use null. For 'a dozen', use 12."
                            },
                            "unit": {
                                "type": "string",
                                "description": "The unit of measurement (e.g., 'cup', 'tbsp', 'tsp', 'oz', 'lb', 'g', 'ml', 'clove', 'slice', 'piece'). Use singular lowercase form. Null if no unit (e.g., '3 eggs')."
                            },
                            "name": {
                                "type": "string",
                                "description": "The ingredient name without quantity, unit, or preparation. Use the common name (e.g., 'all-purpose flour', 'garlic', 'salt')."
                            },
                            "preparation": {
                                "type": "string",
                                "description": "Any preparation instructions (e.g., 'minced', 'diced', 'sifted', 'room temperature', 'softened'). Null if no preparation mentioned."
                            }
                        },
                        "required": ["raw_text", "name"]
                    },
                    "description": "Array of parsed ingredient objects, one per input line."
                }
            },
            "required": ["ingredients"]
        }),
    }
}

/// Builds the system prompt for ingredient parsing.
#[cfg(any(target_arch = "wasm32", test))]
fn parsing_system_prompt() -> String {
    "You are an ingredient parsing assistant. Given a list of ingredient lines from a recipe, \
     parse each one into structured data using the parse_ingredients tool. \
     Be precise: extract the quantity as a number, the unit in singular lowercase, \
     the ingredient name (without quantity/unit/preparation), and any preparation method. \
     Handle edge cases carefully: \
     - 'a pinch of salt' -> quantity: null, unit: null, name: 'salt', preparation: null \
     - '2-3 cloves garlic, minced' -> quantity: 2, unit: 'clove', name: 'garlic', preparation: 'minced' \
     - '1 cup all-purpose flour, sifted' -> quantity: 1, unit: 'cup', name: 'all-purpose flour', preparation: 'sifted' \
     - '3 large eggs' -> quantity: 3, unit: null, name: 'eggs', preparation: null \
     - '1/2 cup butter, softened' -> quantity: 0.5, unit: 'cup', name: 'butter', preparation: 'softened' \
     - '1 (14 oz) can diced tomatoes' -> quantity: 1, unit: 'can', name: 'diced tomatoes', preparation: null \
     Return exactly one parsed ingredient per input line, in the same order."
        .to_string()
}

/// Parses a list of free-text ingredient lines into structured ingredients
/// using the Claude API with tool_use.
///
/// # Arguments
///
/// * `ingredient_lines` - The raw ingredient text lines to parse.
/// * `api_key` - The Anthropic API key.
/// * `logger` - The request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::IngredientResolutionFailed` if the API call fails
/// or the response cannot be parsed.
#[cfg(target_arch = "wasm32")]
pub async fn parse_ingredient_lines(
    ingredient_lines: &[String],
    api_key: &str,
    logger: &Logger,
) -> Result<Vec<IngredientLine>, PipelineError> {
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    if ingredient_lines.is_empty() {
        return Ok(vec![]);
    }

    logger.info(
        "Starting Claude ingredient parsing",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ingredient_parsing".to_string()),
            ),
            (
                "line_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(ingredient_lines.len())),
            ),
        ]),
    );

    let lines_text = ingredient_lines
        .iter()
        .enumerate()
        .map(|(i, line)| format!("{}. {}", i + 1, line))
        .collect::<Vec<_>>()
        .join("\n");

    let request_body = MessagesRequest {
        model: CLAUDE_MODEL.to_string(),
        max_tokens: MAX_TOKENS,
        tools: vec![build_parsing_tool()],
        tool_choice: ToolChoice {
            choice_type: "tool".to_string(),
            name: "parse_ingredients".to_string(),
        },
        messages: vec![Message {
            role: "user".to_string(),
            content: format!("Parse the following ingredient lines:\n\n{}", lines_text),
        }],
        system: parsing_system_prompt(),
    };

    let body_json = serde_json::to_string(&request_body).map_err(|e| {
        PipelineError::IngredientResolutionFailed {
            message: format!("failed to serialize request: {e}"),
        }
    })?;

    let headers = worker::Headers::new();
    headers
        .set("x-api-key", api_key)
        .map_err(|e| PipelineError::IngredientResolutionFailed {
            message: format!("failed to set api key header: {e}"),
        })?;
    headers
        .set("anthropic-version", "2023-06-01")
        .map_err(|e| PipelineError::IngredientResolutionFailed {
            message: format!("failed to set version header: {e}"),
        })?;
    headers
        .set("content-type", "application/json")
        .map_err(|e| PipelineError::IngredientResolutionFailed {
            message: format!("failed to set content type header: {e}"),
        })?;

    let request = worker::Request::new_with_init(
        "https://api.anthropic.com/v1/messages",
        worker::RequestInit::new()
            .with_method(worker::Method::Post)
            .with_headers(headers)
            .with_body(Some(JsValue::from_str(&body_json))),
    )
    .map_err(|e| PipelineError::IngredientResolutionFailed {
        message: format!("failed to build request: {e}"),
    })?;

    let mut response = worker::Fetch::Request(request).send().await.map_err(|e| {
        PipelineError::IngredientResolutionFailed {
            message: format!("API request failed: {e}"),
        }
    })?;

    let status = response.status_code();
    let response_text =
        response
            .text()
            .await
            .map_err(|e| PipelineError::IngredientResolutionFailed {
                message: format!("failed to read response body: {e}"),
            })?;

    if status >= 400 {
        logger.error(
            "Claude API returned error during ingredient parsing",
            HashMap::from([
                (
                    "status".to_string(),
                    serde_json::Value::Number(serde_json::Number::from(status)),
                ),
                (
                    "body".to_string(),
                    serde_json::Value::String(response_text.chars().take(500).collect::<String>()),
                ),
            ]),
        );
        return Err(PipelineError::IngredientResolutionFailed {
            message: format!("Claude API returned HTTP {status}"),
        });
    }

    let api_response: MessagesResponse = serde_json::from_str(&response_text).map_err(|e| {
        PipelineError::IngredientResolutionFailed {
            message: format!("failed to parse API response: {e}"),
        }
    })?;

    let tool_input = api_response
        .content
        .into_iter()
        .find_map(|block| match block {
            ContentBlock::ToolUse { input, .. } => Some(input),
            ContentBlock::Text { .. } => None,
        })
        .ok_or_else(|| PipelineError::IngredientResolutionFailed {
            message: "no tool_use block in response".to_string(),
        })?;

    let parsed_result: ParsedIngredientsResult =
        serde_json::from_value(tool_input).map_err(|e| {
            PipelineError::IngredientResolutionFailed {
                message: format!("failed to parse ingredient result: {e}"),
            }
        })?;

    logger.info(
        "Claude ingredient parsing complete",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ingredient_parsing".to_string()),
            ),
            (
                "parsed_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(
                    parsed_result.ingredients.len(),
                )),
            ),
        ]),
    );

    // Map results back to IngredientLine structs, matching by position
    let result: Vec<IngredientLine> = if parsed_result.ingredients.len() == ingredient_lines.len() {
        // Perfect 1:1 mapping
        ingredient_lines
            .iter()
            .zip(parsed_result.ingredients.iter())
            .map(|(raw, parsed)| IngredientLine {
                raw_text: raw.clone(),
                parsed: Some(ParsedIngredient {
                    quantity: parsed.quantity,
                    unit: parsed.unit.clone(),
                    name: parsed.name.clone(),
                    preparation: parsed.preparation.clone(),
                }),
            })
            .collect()
    } else {
        // Fallback: use raw_text matching or positional fallback
        ingredient_lines
            .iter()
            .map(|raw| {
                let matching_parsed = parsed_result
                    .ingredients
                    .iter()
                    .find(|p| p.raw_text == *raw);

                match matching_parsed {
                    Some(parsed) => IngredientLine {
                        raw_text: raw.clone(),
                        parsed: Some(ParsedIngredient {
                            quantity: parsed.quantity,
                            unit: parsed.unit.clone(),
                            name: parsed.name.clone(),
                            preparation: parsed.preparation.clone(),
                        }),
                    },
                    None => IngredientLine {
                        raw_text: raw.clone(),
                        parsed: None,
                    },
                }
            })
            .collect()
    };

    Ok(result)
}

/// Non-WASM stub for testing -- returns deterministic parsed results.
///
/// In unit tests (running on the host platform), the Worker Fetch API
/// is not available. This stub allows pipeline tests to exercise the
/// code paths without making real API calls.
#[cfg(not(target_arch = "wasm32"))]
pub async fn parse_ingredient_lines(
    ingredient_lines: &[String],
    _api_key: &str,
    _logger: &Logger,
) -> Result<Vec<IngredientLine>, PipelineError> {
    Ok(ingredient_lines
        .iter()
        .map(|raw| {
            let parsed = parse_ingredient_heuristic(raw);
            IngredientLine {
                raw_text: raw.clone(),
                parsed: Some(parsed),
            }
        })
        .collect())
}

/// Simple heuristic parser used as a fallback when the Claude API is not
/// available (e.g., in tests or when the API key is missing).
///
/// This is a best-effort parser that handles common patterns. It does NOT
/// replace the Claude-based parser for production use.
pub fn parse_ingredient_heuristic(text: &str) -> ParsedIngredient {
    let text = text.trim();

    // Try to extract preparation (after comma)
    let (main_part, preparation) = if let Some(comma_pos) = text.rfind(", ") {
        let prep = text[comma_pos + 2..].trim();
        let main = text[..comma_pos].trim();
        // Only treat as preparation if it looks like a verb/adjective
        if is_preparation_word(prep) {
            (main.to_string(), Some(prep.to_string()))
        } else {
            (text.to_string(), None)
        }
    } else {
        (text.to_string(), None)
    };

    // Try to extract quantity and unit from the beginning
    let parts: Vec<&str> = main_part.split_whitespace().collect();
    if parts.is_empty() {
        return ParsedIngredient {
            quantity: None,
            unit: None,
            name: text.to_string(),
            preparation,
        };
    }

    // Try parsing the first token as a number
    let (quantity, rest_start) = match parse_quantity(parts[0]) {
        Some(q) => (Some(q), 1),
        None => (None, 0),
    };

    if rest_start >= parts.len() {
        return ParsedIngredient {
            quantity,
            unit: None,
            name: text.to_string(),
            preparation,
        };
    }

    // Try parsing the next token as a unit
    let (unit, name_start) = if rest_start < parts.len() && is_unit_word(parts[rest_start]) {
        (Some(parts[rest_start].to_lowercase()), rest_start + 1)
    } else {
        (None, rest_start)
    };

    // Remaining tokens form the ingredient name
    let name_parts: Vec<&str> = parts[name_start..].to_vec();
    let name = if name_parts.is_empty() {
        main_part.clone()
    } else {
        // Remove leading "of" if present (e.g., "a pinch of salt")
        if name_parts.first().map(|s| s.eq_ignore_ascii_case("of")) == Some(true) {
            name_parts[1..].join(" ")
        } else {
            name_parts.join(" ")
        }
    };

    ParsedIngredient {
        quantity,
        unit,
        name: if name.is_empty() { main_part } else { name },
        preparation,
    }
}

/// Attempts to parse a token as a numeric quantity.
///
/// Handles integers, decimals, and simple fractions.
fn parse_quantity(s: &str) -> Option<f64> {
    // Try direct float parse
    if let Ok(v) = s.parse::<f64>() {
        return Some(v);
    }

    // Try fraction (e.g., "1/2")
    if let Some(slash_pos) = s.find('/') {
        let num = s[..slash_pos].parse::<f64>().ok()?;
        let den = s[slash_pos + 1..].parse::<f64>().ok()?;
        if den != 0.0 {
            return Some(num / den);
        }
    }

    None
}

/// Returns true if the word is a common cooking unit.
fn is_unit_word(s: &str) -> bool {
    matches!(
        s.to_lowercase().as_str(),
        "cup"
            | "cups"
            | "tbsp"
            | "tablespoon"
            | "tablespoons"
            | "tsp"
            | "teaspoon"
            | "teaspoons"
            | "oz"
            | "ounce"
            | "ounces"
            | "lb"
            | "lbs"
            | "pound"
            | "pounds"
            | "g"
            | "gram"
            | "grams"
            | "kg"
            | "kilogram"
            | "kilograms"
            | "ml"
            | "milliliter"
            | "milliliters"
            | "l"
            | "liter"
            | "liters"
            | "clove"
            | "cloves"
            | "slice"
            | "slices"
            | "piece"
            | "pieces"
            | "can"
            | "cans"
            | "package"
            | "packages"
            | "bunch"
            | "bunches"
            | "pinch"
            | "dash"
            | "head"
            | "heads"
            | "stalk"
            | "stalks"
            | "sprig"
            | "sprigs"
    )
}

/// Returns true if the word looks like a preparation instruction.
fn is_preparation_word(s: &str) -> bool {
    let lower = s.to_lowercase();
    matches!(
        lower.as_str(),
        "diced"
            | "minced"
            | "chopped"
            | "sliced"
            | "sifted"
            | "softened"
            | "melted"
            | "crushed"
            | "grated"
            | "shredded"
            | "julienned"
            | "peeled"
            | "seeded"
            | "deveined"
            | "thawed"
            | "drained"
            | "rinsed"
            | "halved"
            | "quartered"
            | "divided"
            | "packed"
            | "sieved"
            | "toasted"
            | "roasted"
            | "room temperature"
            | "at room temperature"
            | "finely chopped"
            | "finely diced"
            | "finely minced"
            | "roughly chopped"
            | "thinly sliced"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_parsing_tool_has_correct_name() {
        let tool = build_parsing_tool();
        assert_eq!(tool.name, "parse_ingredients");
    }

    #[test]
    fn build_parsing_tool_schema_has_required_fields() {
        let tool = build_parsing_tool();
        let required = tool.input_schema["required"]
            .as_array()
            .expect("required should be an array");
        let required_strs: Vec<&str> = required.iter().filter_map(|v| v.as_str()).collect();
        assert!(required_strs.contains(&"ingredients"));
    }

    #[test]
    fn parsing_system_prompt_is_not_empty() {
        let prompt = parsing_system_prompt();
        assert!(!prompt.is_empty());
    }

    #[test]
    fn heuristic_parses_simple_ingredient() {
        let result = parse_ingredient_heuristic("2 cups flour");
        assert_eq!(result.quantity, Some(2.0));
        assert_eq!(result.unit.as_deref(), Some("cups"));
        assert_eq!(result.name, "flour");
        assert!(result.preparation.is_none());
    }

    #[test]
    fn heuristic_parses_ingredient_with_preparation() {
        let result = parse_ingredient_heuristic("1 cup butter, softened");
        assert_eq!(result.quantity, Some(1.0));
        assert_eq!(result.unit.as_deref(), Some("cup"));
        assert_eq!(result.name, "butter");
        assert_eq!(result.preparation.as_deref(), Some("softened"));
    }

    #[test]
    fn heuristic_parses_fraction() {
        let result = parse_ingredient_heuristic("1/2 cup sugar");
        assert_eq!(result.quantity, Some(0.5));
        assert_eq!(result.unit.as_deref(), Some("cup"));
        assert_eq!(result.name, "sugar");
    }

    #[test]
    fn heuristic_parses_unitless_ingredient() {
        let result = parse_ingredient_heuristic("3 eggs");
        assert_eq!(result.quantity, Some(3.0));
        assert!(result.unit.is_none());
        assert_eq!(result.name, "eggs");
    }

    #[test]
    fn heuristic_parses_name_only() {
        let result = parse_ingredient_heuristic("salt");
        assert!(result.quantity.is_none());
        assert!(result.unit.is_none());
        assert_eq!(result.name, "salt");
    }

    #[test]
    fn heuristic_parses_pinch() {
        let result = parse_ingredient_heuristic("1 pinch salt");
        assert_eq!(result.quantity, Some(1.0));
        assert_eq!(result.unit.as_deref(), Some("pinch"));
        assert_eq!(result.name, "salt");
    }

    #[test]
    fn heuristic_handles_empty_string() {
        let result = parse_ingredient_heuristic("");
        assert_eq!(result.name, "");
    }

    #[tokio::test]
    async fn parse_ingredient_lines_returns_parsed_for_each_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let lines = vec!["2 cups flour".to_string(), "1 egg".to_string()];
        let result = parse_ingredient_lines(&lines, "fake-key", &logger).await;
        assert!(result.is_ok());
        let parsed = result.expect("should succeed");
        assert_eq!(parsed.len(), 2);
        assert_eq!(parsed[0].raw_text, "2 cups flour");
        assert!(parsed[0].parsed.is_some());
        assert_eq!(parsed[1].raw_text, "1 egg");
        assert!(parsed[1].parsed.is_some());
    }

    #[tokio::test]
    async fn parse_ingredient_lines_returns_empty_for_empty_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = parse_ingredient_lines(&[], "fake-key", &logger).await;
        assert!(result.is_ok());
        assert!(result.expect("should succeed").is_empty());
    }

    #[test]
    fn parse_quantity_handles_integer() {
        assert_eq!(parse_quantity("3"), Some(3.0));
    }

    #[test]
    fn parse_quantity_handles_decimal() {
        assert_eq!(parse_quantity("1.5"), Some(1.5));
    }

    #[test]
    fn parse_quantity_handles_fraction() {
        assert_eq!(parse_quantity("1/2"), Some(0.5));
        assert_eq!(parse_quantity("1/4"), Some(0.25));
    }

    #[test]
    fn parse_quantity_rejects_non_number() {
        assert_eq!(parse_quantity("flour"), None);
    }

    #[test]
    fn is_unit_word_recognizes_common_units() {
        assert!(is_unit_word("cup"));
        assert!(is_unit_word("cups"));
        assert!(is_unit_word("tbsp"));
        assert!(is_unit_word("tsp"));
        assert!(is_unit_word("oz"));
        assert!(is_unit_word("lb"));
        assert!(is_unit_word("g"));
        assert!(is_unit_word("ml"));
        assert!(is_unit_word("clove"));
    }

    #[test]
    fn is_unit_word_rejects_non_units() {
        assert!(!is_unit_word("flour"));
        assert!(!is_unit_word("butter"));
        assert!(!is_unit_word("egg"));
    }

    #[test]
    fn messages_request_serializes_correctly() {
        let req = MessagesRequest {
            model: CLAUDE_MODEL.to_string(),
            max_tokens: MAX_TOKENS,
            tools: vec![build_parsing_tool()],
            tool_choice: ToolChoice {
                choice_type: "tool".to_string(),
                name: "parse_ingredients".to_string(),
            },
            messages: vec![Message {
                role: "user".to_string(),
                content: "test".to_string(),
            }],
            system: parsing_system_prompt(),
        };

        let json = serde_json::to_value(&req).expect("should serialize");
        assert_eq!(json["model"], CLAUDE_MODEL);
        assert_eq!(json["tool_choice"]["type"], "tool");
        assert_eq!(json["tool_choice"]["name"], "parse_ingredients");
    }

    #[test]
    fn parsed_ingredients_result_deserializes() {
        let json = serde_json::json!({
            "ingredients": [
                {
                    "raw_text": "2 cups flour",
                    "quantity": 2.0,
                    "unit": "cup",
                    "name": "flour",
                    "preparation": null
                },
                {
                    "raw_text": "1 cup butter, softened",
                    "quantity": 1.0,
                    "unit": "cup",
                    "name": "butter",
                    "preparation": "softened"
                }
            ]
        });
        let result: ParsedIngredientsResult =
            serde_json::from_value(json).expect("should deserialize");
        assert_eq!(result.ingredients.len(), 2);
        assert_eq!(result.ingredients[0].name, "flour");
        assert_eq!(
            result.ingredients[1].preparation.as_deref(),
            Some("softened")
        );
    }
}
