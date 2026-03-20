//! Recipe extraction service using the Anthropic Claude API.
//!
//! Calls Claude's Messages API with a tool_use schema to extract structured
//! recipe data from raw text. Uses tool_use (structured output) to get
//! deterministic, well-typed extraction results.
//!
//! The extraction service is called during the `extract_recipe` pipeline stage
//! for `CaptureInput::Manual` inputs.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;
use crate::types::capture::StructuredRecipeCandidate;

// Types and constants used only in the wasm32 build path (real API calls).
// On non-wasm targets these are unused, so they are gated to avoid dead_code warnings.

/// The Claude model to use for extraction.
#[cfg(any(target_arch = "wasm32", test))]
const CLAUDE_MODEL: &str = "claude-sonnet-4-20250514";

/// Maximum tokens in the Claude response.
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
struct MessagesResponse {
    /// The content blocks in the response.
    content: Vec<ContentBlock>,
    /// The reason the model stopped generating.
    #[allow(dead_code)]
    stop_reason: Option<String>,
}

/// A single content block in the response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(tag = "type")]
enum ContentBlock {
    /// A text block.
    #[serde(rename = "text")]
    Text {
        /// The text content.
        #[allow(dead_code)]
        text: String,
    },
    /// A tool use block containing the structured extraction.
    #[serde(rename = "tool_use")]
    ToolUse {
        /// The tool name.
        #[allow(dead_code)]
        name: String,
        /// The tool's structured input.
        input: serde_json::Value,
    },
}

/// The extracted recipe data from Claude's tool_use response.
///
/// This matches the JSON schema provided to Claude in the tool definition.
/// All fields are used either directly (in the wasm32 extraction path) or
/// in deserialization tests, so dead_code warnings are suppressed.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[allow(dead_code)]
struct ExtractedRecipe {
    /// The recipe title.
    title: Option<String>,
    /// List of ingredient lines.
    ingredients: Vec<String>,
    /// List of instruction steps.
    steps: Vec<String>,
    /// Number of servings.
    servings: Option<i32>,
    /// Total time in minutes.
    time_minutes: Option<i32>,
    /// Tags or categories.
    tags: Vec<String>,
    /// Confidence score (0.0 to 1.0).
    confidence: f64,
}

/// Builds the JSON schema for the recipe extraction tool.
///
/// This schema is provided to Claude so it returns structured data
/// that maps directly to `StructuredRecipeCandidate`.
#[cfg(any(target_arch = "wasm32", test))]
fn build_extraction_tool() -> Tool {
    Tool {
        name: "extract_recipe".to_string(),
        description: "Extract structured recipe data from raw text. Parse the text to identify the recipe title, ingredients, steps, servings, time, and tags.".to_string(),
        input_schema: serde_json::json!({
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "The recipe title. If not explicitly stated, infer a reasonable title from the content."
                },
                "ingredients": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "List of ingredient lines, each as a single string (e.g. '2 cups all-purpose flour'). Preserve original quantities and units."
                },
                "steps": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "Ordered list of instruction steps. Each step should be a single, clear instruction."
                },
                "servings": {
                    "type": "integer",
                    "description": "Number of servings the recipe makes. Null if not mentioned."
                },
                "time_minutes": {
                    "type": "integer",
                    "description": "Total time in minutes (prep + cook). Null if not mentioned."
                },
                "tags": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "Tags or categories for the recipe (e.g. 'dessert', 'vegetarian', 'quick')."
                },
                "confidence": {
                    "type": "number",
                    "description": "Confidence score from 0.0 to 1.0 indicating how well the text was parsed into a recipe. Use 0.9+ for clear recipes, 0.5-0.8 for partial recipes, below 0.5 for unclear text."
                }
            },
            "required": ["ingredients", "steps", "tags", "confidence"]
        }),
    }
}

/// Builds the system prompt for recipe extraction.
#[cfg(any(target_arch = "wasm32", test))]
fn system_prompt() -> String {
    "You are a recipe extraction assistant. Given raw text that may contain a recipe, \
     extract the structured recipe data using the extract_recipe tool. \
     Be thorough: identify all ingredients and steps. \
     Preserve original measurements and quantities. \
     If the text does not contain a recognizable recipe, still use the tool \
     with empty arrays and a low confidence score. \
     Do not add ingredients or steps that are not in the source text."
        .to_string()
}

/// Extracts structured recipe data from raw text using Claude's Messages API.
///
/// Calls the Anthropic API with a tool_use schema that constrains the model
/// to return a `StructuredRecipeCandidate`-shaped JSON object.
///
/// # Arguments
///
/// * `text` - The raw recipe text to extract from.
/// * `api_key` - The Anthropic API key.
/// * `logger` - The request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the API call fails or
/// the response cannot be parsed.
#[cfg(target_arch = "wasm32")]
pub async fn extract_recipe_from_text(
    text: &str,
    api_key: &str,
    logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    logger.info(
        "Starting Claude extraction",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("extraction".to_string()),
            ),
            (
                "text_length".to_string(),
                serde_json::Value::Number(serde_json::Number::from(text.len())),
            ),
        ]),
    );

    let request_body = MessagesRequest {
        model: CLAUDE_MODEL.to_string(),
        max_tokens: MAX_TOKENS,
        tools: vec![build_extraction_tool()],
        tool_choice: ToolChoice {
            choice_type: "tool".to_string(),
            name: "extract_recipe".to_string(),
        },
        messages: vec![Message {
            role: "user".to_string(),
            content: format!("Extract the recipe from the following text:\n\n{}", text),
        }],
        system: system_prompt(),
    };

    let body_json =
        serde_json::to_string(&request_body).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to serialize request: {e}"),
        })?;

    // Build the HTTP request to Anthropic's API
    let headers = worker::Headers::new();
    headers
        .set("x-api-key", api_key)
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to set api key header: {e}"),
        })?;
    headers
        .set("anthropic-version", "2023-06-01")
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to set version header: {e}"),
        })?;
    headers
        .set("content-type", "application/json")
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to set content type header: {e}"),
        })?;

    let request = worker::Request::new_with_init(
        "https://api.anthropic.com/v1/messages",
        worker::RequestInit::new()
            .with_method(worker::Method::Post)
            .with_headers(headers)
            .with_body(Some(JsValue::from_str(&body_json))),
    )
    .map_err(|e| PipelineError::ExtractionFailed {
        message: format!("failed to build request: {e}"),
    })?;

    let mut response = worker::Fetch::Request(request).send().await.map_err(|e| {
        PipelineError::ExtractionFailed {
            message: format!("API request failed: {e}"),
        }
    })?;

    let status = response.status_code();
    let response_text = response
        .text()
        .await
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to read response body: {e}"),
        })?;

    if status >= 400 {
        logger.error(
            "Claude API returned error",
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
        return Err(PipelineError::ExtractionFailed {
            message: format!("Claude API returned HTTP {status}"),
        });
    }

    // Parse the response
    let api_response: MessagesResponse =
        serde_json::from_str(&response_text).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to parse API response: {e}"),
        })?;

    // Find the tool_use content block
    let tool_input = api_response
        .content
        .into_iter()
        .find_map(|block| match block {
            ContentBlock::ToolUse { input, .. } => Some(input),
            ContentBlock::Text { .. } => None,
        })
        .ok_or_else(|| PipelineError::ExtractionFailed {
            message: "no tool_use block in response".to_string(),
        })?;

    // Parse the tool input into our extraction struct
    let extracted: ExtractedRecipe =
        serde_json::from_value(tool_input).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to parse extraction result: {e}"),
        })?;

    logger.info(
        "Claude extraction complete",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("extraction".to_string()),
            ),
            (
                "title".to_string(),
                serde_json::Value::String(extracted.title.clone().unwrap_or_default()),
            ),
            (
                "ingredients_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(extracted.ingredients.len())),
            ),
            (
                "steps_count".to_string(),
                serde_json::Value::Number(serde_json::Number::from(extracted.steps.len())),
            ),
            (
                "confidence".to_string(),
                serde_json::json!(extracted.confidence),
            ),
        ]),
    );

    Ok(StructuredRecipeCandidate {
        title: extracted.title,
        ingredient_lines: extracted.ingredients,
        steps: extracted.steps,
        servings: extracted.servings,
        time_minutes: extracted.time_minutes,
        tags: extracted.tags,
        confidence: extracted.confidence,
    })
}

/// Non-WASM stub for testing — returns a predefined extraction result.
///
/// In unit tests (running on the host platform), the Worker Fetch API
/// is not available. This stub allows pipeline tests to exercise the
/// code paths without making real API calls.
#[cfg(not(target_arch = "wasm32"))]
pub async fn extract_recipe_from_text(
    text: &str,
    _api_key: &str,
    _logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    if text.trim().is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "empty input text".to_string(),
        });
    }

    // Return a stub extraction for testing
    Ok(StructuredRecipeCandidate {
        title: Some("Test Recipe".to_string()),
        ingredient_lines: vec!["2 cups flour".to_string(), "1 cup sugar".to_string()],
        steps: vec![
            "Mix dry ingredients".to_string(),
            "Bake at 350F for 30 minutes".to_string(),
        ],
        servings: Some(4),
        time_minutes: Some(45),
        tags: vec!["baking".to_string()],
        confidence: 0.85,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_extraction_tool_has_correct_name() {
        let tool = build_extraction_tool();
        assert_eq!(tool.name, "extract_recipe");
    }

    #[test]
    fn build_extraction_tool_schema_has_required_fields() {
        let tool = build_extraction_tool();
        let required = tool.input_schema["required"]
            .as_array()
            .expect("required should be an array");
        let required_strs: Vec<&str> = required.iter().filter_map(|v| v.as_str()).collect();
        assert!(required_strs.contains(&"ingredients"));
        assert!(required_strs.contains(&"steps"));
        assert!(required_strs.contains(&"tags"));
        assert!(required_strs.contains(&"confidence"));
    }

    #[test]
    fn system_prompt_is_not_empty() {
        let prompt = system_prompt();
        assert!(!prompt.is_empty());
    }

    #[tokio::test]
    async fn extract_recipe_from_text_rejects_empty_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = extract_recipe_from_text("", "fake-key", &logger).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn extract_recipe_from_text_returns_candidate_for_valid_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = extract_recipe_from_text(
            "Simple recipe: 2 cups flour, 1 egg. Mix and bake.",
            "fake-key",
            &logger,
        )
        .await;
        assert!(result.is_ok());
        let candidate = result.expect("should succeed");
        assert!(candidate.title.is_some());
        assert!(!candidate.ingredient_lines.is_empty());
        assert!(!candidate.steps.is_empty());
    }

    #[test]
    fn messages_request_serializes_correctly() {
        let req = MessagesRequest {
            model: CLAUDE_MODEL.to_string(),
            max_tokens: MAX_TOKENS,
            tools: vec![build_extraction_tool()],
            tool_choice: ToolChoice {
                choice_type: "tool".to_string(),
                name: "extract_recipe".to_string(),
            },
            messages: vec![Message {
                role: "user".to_string(),
                content: "test".to_string(),
            }],
            system: system_prompt(),
        };

        let json = serde_json::to_value(&req).expect("should serialize");
        assert_eq!(json["model"], CLAUDE_MODEL);
        assert_eq!(json["max_tokens"], MAX_TOKENS);
        assert_eq!(json["tool_choice"]["type"], "tool");
        assert_eq!(json["tool_choice"]["name"], "extract_recipe");
    }

    #[test]
    fn extracted_recipe_deserializes_from_json() {
        let json = serde_json::json!({
            "title": "Pancakes",
            "ingredients": ["2 cups flour", "2 eggs", "1 cup milk"],
            "steps": ["Mix ingredients", "Cook on griddle"],
            "servings": 4,
            "time_minutes": 20,
            "tags": ["breakfast"],
            "confidence": 0.92
        });
        let extracted: ExtractedRecipe = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(extracted.title.as_deref(), Some("Pancakes"));
        assert_eq!(extracted.ingredients.len(), 3);
        assert_eq!(extracted.steps.len(), 2);
        assert_eq!(extracted.servings, Some(4));
        assert_eq!(extracted.time_minutes, Some(20));
        assert_eq!(extracted.confidence, 0.92);
    }

    #[test]
    fn extracted_recipe_handles_missing_optional_fields() {
        let json = serde_json::json!({
            "ingredients": ["flour"],
            "steps": ["bake"],
            "tags": [],
            "confidence": 0.5
        });
        let extracted: ExtractedRecipe = serde_json::from_value(json).expect("should deserialize");
        assert!(extracted.title.is_none());
        assert!(extracted.servings.is_none());
        assert!(extracted.time_minutes.is_none());
    }

    #[test]
    fn messages_response_deserializes_tool_use() {
        let json = serde_json::json!({
            "content": [
                {
                    "type": "tool_use",
                    "id": "toolu_123",
                    "name": "extract_recipe",
                    "input": {
                        "title": "Test",
                        "ingredients": ["flour"],
                        "steps": ["bake"],
                        "tags": [],
                        "confidence": 0.9
                    }
                }
            ],
            "stop_reason": "tool_use"
        });
        let resp: MessagesResponse = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(resp.content.len(), 1);
        match &resp.content[0] {
            ContentBlock::ToolUse { name, input } => {
                assert_eq!(name, "extract_recipe");
                assert!(input.is_object());
            }
            _ => panic!("expected ToolUse block"),
        }
    }
}
