//! Screenshot/image OCR extraction service using Claude's vision capability.
//!
//! Accepts uploaded recipe screenshots or photos and uses Claude's vision
//! model to extract readable text from the image. The extracted text is then
//! fed into the existing recipe extraction pipeline for structuring.
//!
//! Uses the Anthropic Messages API with base64-encoded images in the
//! `image` content block type. See:
//! <https://docs.anthropic.com/en/api/messages> for the vision API format.
//!
//! This service is called during the async capture pipeline for
//! `CaptureInput::Screenshot` inputs.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;

/// The Claude model to use for vision-based extraction.
#[cfg(any(target_arch = "wasm32", test))]
const CLAUDE_MODEL: &str = "claude-sonnet-4-20250514";

/// Maximum tokens in the Claude vision response.
#[cfg(any(target_arch = "wasm32", test))]
const MAX_TOKENS: u32 = 4096;

/// Supported image media types for Claude's vision API.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ImageMediaType {
    /// JPEG image.
    Jpeg,
    /// PNG image.
    Png,
    /// GIF image.
    Gif,
    /// WebP image.
    Webp,
}

impl ImageMediaType {
    /// Returns the MIME type string for the Anthropic API.
    pub fn as_mime(&self) -> &'static str {
        match self {
            ImageMediaType::Jpeg => "image/jpeg",
            ImageMediaType::Png => "image/png",
            ImageMediaType::Gif => "image/gif",
            ImageMediaType::Webp => "image/webp",
        }
    }

    /// Detects the media type from the first few bytes of an image.
    ///
    /// Uses magic bytes to identify the format:
    /// - JPEG: starts with `FF D8 FF`
    /// - PNG: starts with `89 50 4E 47`
    /// - GIF: starts with `47 49 46`
    /// - WebP: starts with `52 49 46 46` and contains `57 45 42 50`
    ///
    /// Returns `None` if the format is not recognized.
    pub fn detect(data: &[u8]) -> Option<Self> {
        if data.len() < 4 {
            return None;
        }

        // JPEG: FF D8 FF
        if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
            return Some(ImageMediaType::Jpeg);
        }

        // PNG: 89 50 4E 47
        if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
            return Some(ImageMediaType::Png);
        }

        // GIF: 47 49 46
        if data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 {
            return Some(ImageMediaType::Gif);
        }

        // WebP: RIFF....WEBP
        if data.len() >= 12
            && data[0] == 0x52
            && data[1] == 0x49
            && data[2] == 0x46
            && data[3] == 0x46
            && data[8] == 0x57
            && data[9] == 0x45
            && data[10] == 0x42
            && data[11] == 0x50
        {
            return Some(ImageMediaType::Webp);
        }

        None
    }
}

/// Request body for the Anthropic Messages API with vision.
///
/// The messages API accepts image content blocks alongside text content
/// blocks. Each image is provided as a base64-encoded source.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct VisionMessagesRequest {
    /// The Claude model identifier.
    model: String,
    /// Maximum output tokens.
    max_tokens: u32,
    /// The conversation messages (with image content blocks).
    messages: Vec<VisionMessage>,
    /// System prompt.
    system: String,
}

/// A single message that may contain image and text content blocks.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct VisionMessage {
    /// The role (user, assistant).
    role: String,
    /// Content blocks (text and/or image).
    content: Vec<ContentBlock>,
}

/// A content block in a vision message — either text or image.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
#[serde(tag = "type")]
enum ContentBlock {
    /// A base64-encoded image.
    #[serde(rename = "image")]
    Image {
        /// The image source.
        source: ImageSource,
    },
    /// A text prompt.
    #[serde(rename = "text")]
    Text {
        /// The text content.
        text: String,
    },
}

/// Source data for an image content block.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Serialize)]
struct ImageSource {
    /// Always "base64" for inline images.
    #[serde(rename = "type")]
    source_type: String,
    /// The MIME type (e.g., "image/jpeg").
    media_type: String,
    /// The base64-encoded image data.
    data: String,
}

/// Response from the Anthropic Messages API.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
struct MessagesResponse {
    /// The content blocks in the response.
    content: Vec<ResponseContentBlock>,
}

/// A content block in the API response.
#[cfg(any(target_arch = "wasm32", test))]
#[derive(Debug, serde::Deserialize)]
#[serde(tag = "type")]
enum ResponseContentBlock {
    /// A text response block.
    #[serde(rename = "text")]
    Text {
        /// The text content.
        text: String,
    },
}

/// Builds the system prompt for vision-based recipe text extraction.
#[cfg(any(target_arch = "wasm32", test))]
fn vision_system_prompt() -> String {
    "You are a recipe OCR assistant. Given a screenshot or photo of a recipe, \
     extract ALL visible text from the image. Include the recipe title, \
     ingredients list, instructions/steps, and any other relevant information \
     like serving size, prep time, cook time, and notes. \
     Preserve the original measurements and quantities exactly as shown. \
     Format the output as clean text with clear sections for ingredients \
     and instructions. If the image is not a recipe, describe what you see \
     and note that no recipe was found."
        .to_string()
}

/// Extracts text from a recipe screenshot using Claude's vision capability.
///
/// Sends the image as a base64-encoded content block to the Anthropic
/// Messages API and returns the extracted text. The text is suitable for
/// feeding into the recipe extraction pipeline.
///
/// # Arguments
///
/// * `image_data` - The raw image bytes (JPEG, PNG, GIF, or WebP).
/// * `api_key` - The Anthropic API key.
/// * `logger` - The request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the image format is
/// unsupported, the API call fails, or no text could be extracted.
#[cfg(target_arch = "wasm32")]
pub async fn extract_text_from_image(
    image_data: &[u8],
    api_key: &str,
    logger: &Logger,
) -> Result<String, PipelineError> {
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    let media_type =
        ImageMediaType::detect(image_data).ok_or_else(|| PipelineError::ExtractionFailed {
            message: "unsupported image format (expected JPEG, PNG, GIF, or WebP)".to_string(),
        })?;

    let image_size_kb = image_data.len() / 1024;

    logger.info(
        "Starting Claude vision extraction",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ocr".to_string()),
            ),
            (
                "media_type".to_string(),
                serde_json::Value::String(media_type.as_mime().to_string()),
            ),
            (
                "image_size_kb".to_string(),
                serde_json::Value::Number(serde_json::Number::from(image_size_kb)),
            ),
        ]),
    );

    // Enforce a 20MB limit (Anthropic's limit)
    if image_data.len() > 20 * 1024 * 1024 {
        return Err(PipelineError::ExtractionFailed {
            message: "image exceeds 20MB size limit".to_string(),
        });
    }

    let base64_data =
        base64::Engine::encode(&base64::engine::general_purpose::STANDARD, image_data);

    let request_body = VisionMessagesRequest {
        model: CLAUDE_MODEL.to_string(),
        max_tokens: MAX_TOKENS,
        messages: vec![VisionMessage {
            role: "user".to_string(),
            content: vec![
                ContentBlock::Image {
                    source: ImageSource {
                        source_type: "base64".to_string(),
                        media_type: media_type.as_mime().to_string(),
                        data: base64_data,
                    },
                },
                ContentBlock::Text {
                    text: "Extract all recipe text from this image. Include the title, \
                           ingredients, instructions, and any other relevant details."
                        .to_string(),
                },
            ],
        }],
        system: vision_system_prompt(),
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

    if status == 429 {
        logger.warn(
            "Claude API rate limited during vision extraction",
            HashMap::from([(
                "status".to_string(),
                serde_json::Value::Number(serde_json::Number::from(status)),
            )]),
        );
        return Err(PipelineError::ExtractionFailed {
            message: "Claude API rate limited — please retry later".to_string(),
        });
    }

    if status >= 400 {
        logger.error(
            "Claude vision API returned error",
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
            message: format!("Claude vision API returned HTTP {status}"),
        });
    }

    let api_response: MessagesResponse =
        serde_json::from_str(&response_text).map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to parse vision API response: {e}"),
        })?;

    // Collect all text blocks from the response
    let extracted_text: String = api_response
        .content
        .into_iter()
        .filter_map(|block| match block {
            ResponseContentBlock::Text { text } => Some(text),
        })
        .collect::<Vec<String>>()
        .join("\n");

    if extracted_text.trim().is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "no text extracted from image".to_string(),
        });
    }

    logger.info(
        "Claude vision extraction complete",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("ocr".to_string()),
            ),
            (
                "text_length".to_string(),
                serde_json::Value::Number(serde_json::Number::from(extracted_text.len())),
            ),
        ]),
    );

    Ok(extracted_text)
}

/// Non-WASM stub for testing — returns sample extracted text.
#[cfg(not(target_arch = "wasm32"))]
pub async fn extract_text_from_image(
    image_data: &[u8],
    _api_key: &str,
    _logger: &Logger,
) -> Result<String, PipelineError> {
    if image_data.is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "empty image data".to_string(),
        });
    }

    Ok("Pasta Carbonara\n\n\
        Ingredients:\n\
        200g spaghetti\n\
        100g pancetta\n\
        2 eggs\n\
        50g pecorino cheese\n\
        Black pepper\n\n\
        Instructions:\n\
        1. Cook spaghetti in salted boiling water\n\
        2. Fry pancetta until crispy\n\
        3. Beat eggs with grated cheese and pepper\n\
        4. Drain pasta, reserve some water\n\
        5. Toss pasta with pancetta off heat\n\
        6. Add egg mixture, toss quickly\n\
        7. Add pasta water if needed for creaminess"
        .to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn image_media_type_detect_jpeg() {
        let jpeg_header = [0xFF, 0xD8, 0xFF, 0xE0];
        assert_eq!(
            ImageMediaType::detect(&jpeg_header),
            Some(ImageMediaType::Jpeg)
        );
    }

    #[test]
    fn image_media_type_detect_png() {
        let png_header = [0x89, 0x50, 0x4E, 0x47];
        assert_eq!(
            ImageMediaType::detect(&png_header),
            Some(ImageMediaType::Png)
        );
    }

    #[test]
    fn image_media_type_detect_gif() {
        let gif_header = [0x47, 0x49, 0x46, 0x38];
        assert_eq!(
            ImageMediaType::detect(&gif_header),
            Some(ImageMediaType::Gif)
        );
    }

    #[test]
    fn image_media_type_detect_webp() {
        let webp_header = [
            0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
        ];
        assert_eq!(
            ImageMediaType::detect(&webp_header),
            Some(ImageMediaType::Webp)
        );
    }

    #[test]
    fn image_media_type_detect_unknown() {
        let unknown = [0x00, 0x01, 0x02, 0x03];
        assert_eq!(ImageMediaType::detect(&unknown), None);
    }

    #[test]
    fn image_media_type_detect_too_short() {
        let short = [0xFF, 0xD8];
        assert_eq!(ImageMediaType::detect(&short), None);
    }

    #[test]
    fn image_media_type_as_mime() {
        assert_eq!(ImageMediaType::Jpeg.as_mime(), "image/jpeg");
        assert_eq!(ImageMediaType::Png.as_mime(), "image/png");
        assert_eq!(ImageMediaType::Gif.as_mime(), "image/gif");
        assert_eq!(ImageMediaType::Webp.as_mime(), "image/webp");
    }

    #[test]
    fn vision_system_prompt_is_not_empty() {
        let prompt = vision_system_prompt();
        assert!(!prompt.is_empty());
        assert!(prompt.contains("recipe"));
    }

    #[test]
    fn vision_request_serializes_correctly() {
        let req = VisionMessagesRequest {
            model: CLAUDE_MODEL.to_string(),
            max_tokens: MAX_TOKENS,
            messages: vec![VisionMessage {
                role: "user".to_string(),
                content: vec![
                    ContentBlock::Image {
                        source: ImageSource {
                            source_type: "base64".to_string(),
                            media_type: "image/jpeg".to_string(),
                            data: "dGVzdA==".to_string(),
                        },
                    },
                    ContentBlock::Text {
                        text: "Extract recipe text".to_string(),
                    },
                ],
            }],
            system: "test".to_string(),
        };

        let json = serde_json::to_value(&req).expect("should serialize");
        assert_eq!(json["model"], CLAUDE_MODEL);
        assert_eq!(json["max_tokens"], MAX_TOKENS);
        assert_eq!(json["messages"][0]["content"][0]["type"], "image");
        assert_eq!(
            json["messages"][0]["content"][0]["source"]["type"],
            "base64"
        );
        assert_eq!(
            json["messages"][0]["content"][0]["source"]["media_type"],
            "image/jpeg"
        );
        assert_eq!(json["messages"][0]["content"][1]["type"], "text");
    }

    #[test]
    fn vision_response_deserializes() {
        let json = serde_json::json!({
            "content": [
                {
                    "type": "text",
                    "text": "Recipe: Pasta\n\nIngredients:\n200g pasta"
                }
            ],
            "stop_reason": "end_turn"
        });
        let resp: MessagesResponse = serde_json::from_value(json).expect("should deserialize");
        assert_eq!(resp.content.len(), 1);
        match &resp.content[0] {
            ResponseContentBlock::Text { text } => {
                assert!(text.contains("Pasta"));
            }
        }
    }

    #[tokio::test]
    async fn extract_text_from_image_returns_text_for_valid_image() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        // Pass some non-empty bytes (doesn't need to be a real image in stub)
        let result = extract_text_from_image(&[1, 2, 3, 4], "fake-key", &logger).await;
        assert!(result.is_ok());
        let text = result.expect("should succeed");
        assert!(!text.is_empty());
        assert!(text.contains("Carbonara") || text.contains("spaghetti"));
    }

    #[tokio::test]
    async fn extract_text_from_image_fails_for_empty_data() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = extract_text_from_image(&[], "fake-key", &logger).await;
        assert!(result.is_err());
    }
}
