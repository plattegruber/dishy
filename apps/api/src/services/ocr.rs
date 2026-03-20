//! Screenshot OCR service using Claude Vision API.
//!
//! Accepts image bytes (from R2 or direct upload), sends them to the
//! Claude Messages API with vision capabilities, and extracts readable
//! text from the image. The extracted text is then fed through the
//! standard recipe extraction pipeline.
//!
//! This service is called from the queue consumer when processing
//! `CaptureInput::Screenshot` captures asynchronously.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;
use crate::types::capture::StructuredRecipeCandidate;

/// The Claude model to use for vision-based extraction.
#[cfg(any(target_arch = "wasm32", test))]
const CLAUDE_VISION_MODEL: &str = "claude-sonnet-4-20250514";

/// Maximum tokens in the Claude vision response.
#[cfg(any(target_arch = "wasm32", test))]
const MAX_TOKENS: u32 = 4096;

/// Request body for the Anthropic Messages API (vision).
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct VisionRequest {
    /// The Claude model identifier.
    model: String,
    /// Maximum output tokens.
    max_tokens: u32,
    /// Tools available to the model.
    tools: Vec<serde_json::Value>,
    /// Instruction to force tool use.
    tool_choice: serde_json::Value,
    /// The conversation messages (with image content).
    messages: Vec<serde_json::Value>,
    /// System prompt.
    system: String,
}

/// Builds the system prompt for OCR-based recipe extraction.
#[cfg(any(target_arch = "wasm32", test))]
fn ocr_system_prompt() -> String {
    "You are a recipe extraction assistant. You are given a screenshot or photo \
     that may contain a recipe. Extract the structured recipe data using the \
     extract_recipe tool. Read all visible text in the image carefully. \
     Be thorough: identify all ingredients and steps visible in the image. \
     Preserve original measurements and quantities exactly as shown. \
     If the image does not contain a recognizable recipe, still use the tool \
     with empty arrays and a low confidence score. \
     Do not add ingredients or steps that are not visible in the image."
        .to_string()
}

/// Builds the extraction tool schema (same as text extraction).
#[cfg(any(target_arch = "wasm32", test))]
fn build_extraction_tool() -> serde_json::Value {
    serde_json::json!({
        "name": "extract_recipe",
        "description": "Extract structured recipe data from the image. Parse visible text to identify the recipe title, ingredients, steps, servings, time, and tags.",
        "input_schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "The recipe title."
                },
                "ingredients": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "List of ingredient lines."
                },
                "steps": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "Ordered list of instruction steps."
                },
                "servings": {
                    "type": "integer",
                    "description": "Number of servings. Null if not visible."
                },
                "time_minutes": {
                    "type": "integer",
                    "description": "Total time in minutes. Null if not visible."
                },
                "tags": {
                    "type": "array",
                    "items": { "type": "string" },
                    "description": "Tags or categories."
                },
                "confidence": {
                    "type": "number",
                    "description": "Confidence score from 0.0 to 1.0."
                }
            },
            "required": ["ingredients", "steps", "tags", "confidence"]
        }
    })
}

/// The extracted recipe data from Claude's tool_use response.
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

/// Response from the Anthropic Messages API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
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
        text: String,
    },
    /// A tool use block containing the structured extraction.
    #[serde(rename = "tool_use")]
    ToolUse {
        /// The tool name.
        name: String,
        /// The tool's structured input.
        input: serde_json::Value,
    },
}

/// Extracts a recipe from image bytes using Claude Vision API.
///
/// Sends the image to Claude as a base64-encoded content block,
/// combined with the extraction tool schema. Returns a structured
/// recipe candidate.
///
/// # Arguments
///
/// * `image_data` - The raw image bytes.
/// * `content_type` - The MIME type of the image (e.g., "image/jpeg").
/// * `api_key` - The Anthropic API key.
/// * `logger` - Request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` on any failure.
#[cfg(target_arch = "wasm32")]
pub async fn extract_recipe_from_image(
    image_data: &[u8],
    content_type: &str,
    api_key: &str,
    logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    use base64::{engine::general_purpose::STANDARD, Engine as _};
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    logger.info(
        "Starting Claude Vision OCR extraction",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ocr_extraction".to_string()),
            ),
            (
                "image_size".to_string(),
                serde_json::Value::Number(serde_json::Number::from(image_data.len())),
            ),
            (
                "content_type".to_string(),
                serde_json::Value::String(content_type.to_string()),
            ),
        ]),
    );

    let image_b64 = STANDARD.encode(image_data);

    // Determine media type for Claude (must be image/jpeg, image/png, image/gif, or image/webp)
    let media_type = match content_type {
        "image/jpeg" | "image/png" | "image/gif" | "image/webp" => content_type,
        _ => "image/jpeg", // default fallback
    };

    let request_body = VisionRequest {
        model: CLAUDE_VISION_MODEL.to_string(),
        max_tokens: MAX_TOKENS,
        tools: vec![build_extraction_tool()],
        tool_choice: serde_json::json!({
            "type": "tool",
            "name": "extract_recipe"
        }),
        messages: vec![serde_json::json!({
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": media_type,
                        "data": image_b64
                    }
                },
                {
                    "type": "text",
                    "text": "Extract the recipe from this image. Read all visible text carefully."
                }
            ]
        })],
        system: ocr_system_prompt(),
    };

    let body_json =
        serde_json::to_string(&request_body).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to serialize vision request: {e}"),
        })?;

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
        message: format!("failed to build vision request: {e}"),
    })?;

    let mut response = worker::Fetch::Request(request).send().await.map_err(|e| {
        PipelineError::ExtractionFailed {
            message: format!("vision API request failed: {e}"),
        }
    })?;

    let status = response.status_code();
    let response_text = response
        .text()
        .await
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to read vision response body: {e}"),
        })?;

    if status >= 400 {
        logger.error(
            "Claude Vision API returned error",
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
            message: format!("Claude Vision API returned HTTP {status}"),
        });
    }

    let api_response: MessagesResponse =
        serde_json::from_str(&response_text).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to parse vision API response: {e}"),
        })?;

    let tool_input = api_response
        .content
        .into_iter()
        .find_map(|block| match block {
            ContentBlock::ToolUse { input, .. } => Some(input),
            ContentBlock::Text { .. } => None,
        })
        .ok_or_else(|| PipelineError::ExtractionFailed {
            message: "no tool_use block in vision response".to_string(),
        })?;

    let extracted: ExtractedRecipe =
        serde_json::from_value(tool_input).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to parse vision extraction result: {e}"),
        })?;

    logger.info(
        "Claude Vision OCR extraction complete",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ocr_extraction".to_string()),
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

/// Non-WASM stub for testing -- returns a predefined result.
#[cfg(not(target_arch = "wasm32"))]
pub async fn extract_recipe_from_image(
    image_data: &[u8],
    _content_type: &str,
    _api_key: &str,
    _logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    if image_data.is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "empty image data".to_string(),
        });
    }

    Ok(StructuredRecipeCandidate {
        title: Some("Screenshot Recipe".to_string()),
        ingredient_lines: vec!["2 cups flour".to_string(), "1 cup sugar".to_string()],
        steps: vec!["Mix ingredients".to_string(), "Bake at 350F".to_string()],
        servings: Some(4),
        time_minutes: Some(30),
        tags: vec!["baking".to_string()],
        confidence: 0.80,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ocr_system_prompt_is_not_empty() {
        let prompt = ocr_system_prompt();
        assert!(!prompt.is_empty());
        assert!(prompt.contains("recipe"));
    }

    #[test]
    fn build_extraction_tool_has_correct_structure() {
        let tool = build_extraction_tool();
        assert_eq!(tool["name"], "extract_recipe");
        let required = tool["input_schema"]["required"]
            .as_array()
            .expect("required should be an array");
        let required_strs: Vec<&str> = required.iter().filter_map(|v| v.as_str()).collect();
        assert!(required_strs.contains(&"ingredients"));
        assert!(required_strs.contains(&"steps"));
        assert!(required_strs.contains(&"confidence"));
    }

    #[test]
    fn extracted_recipe_deserializes_from_json() {
        let json = serde_json::json!({
            "title": "OCR Pancakes",
            "ingredients": ["2 cups flour", "2 eggs"],
            "steps": ["Mix", "Cook"],
            "servings": 4,
            "time_minutes": 20,
            "tags": ["breakfast"],
            "confidence": 0.85
        });
        let extracted: ExtractedRecipe = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(extracted.title.as_deref(), Some("OCR Pancakes"));
        assert_eq!(extracted.ingredients.len(), 2);
    }

    #[tokio::test]
    async fn extract_recipe_from_image_rejects_empty_data() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = extract_recipe_from_image(&[], "image/jpeg", "fake-key", &logger).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn extract_recipe_from_image_returns_candidate() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let fake_image = vec![0u8; 100]; // fake image bytes
        let result =
            extract_recipe_from_image(&fake_image, "image/jpeg", "fake-key", &logger).await;
        assert!(result.is_ok());
        let candidate = result.expect("should succeed");
        assert!(candidate.title.is_some());
        assert!(!candidate.ingredient_lines.is_empty());
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
            ]
        });
        let resp: MessagesResponse = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(resp.content.len(), 1);
    }
}
