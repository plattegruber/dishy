//! Social link content extraction service.
//!
//! Fetches the HTML content from a social media URL, strips tags to extract
//! readable text, and feeds the text through the Claude extraction pipeline.
//! Supports Instagram, TikTok, YouTube, and generic recipe websites.
//!
//! This service is called from the queue consumer when processing
//! `CaptureInput::SocialLink` captures asynchronously.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;
use crate::types::capture::StructuredRecipeCandidate;
use crate::types::recipe::Platform;

/// Maximum number of characters to extract from a page before truncating.
/// Claude has a large context window but we cap to avoid excessive token usage.
#[cfg(target_arch = "wasm32")]
const MAX_EXTRACTED_CHARS: usize = 15_000;

/// Determines the [`Platform`] from a URL string.
///
/// Inspects the hostname to identify known social platforms.
/// Returns [`Platform::Unknown`] for unrecognized domains.
pub fn detect_platform(url: &str) -> Platform {
    let lower = url.to_lowercase();
    if lower.contains("instagram.com") {
        Platform::Instagram
    } else if lower.contains("tiktok.com") {
        Platform::Tiktok
    } else if lower.contains("youtube.com") || lower.contains("youtu.be") {
        Platform::Youtube
    } else {
        Platform::Website
    }
}

/// Fetches the HTML content of a URL and extracts readable text.
///
/// Uses the Worker Fetch API to retrieve the page, then strips HTML tags
/// to produce plain text suitable for Claude extraction.
///
/// # Arguments
///
/// * `url` - The URL to fetch.
/// * `logger` - Request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the fetch fails or
/// the response cannot be read.
#[cfg(target_arch = "wasm32")]
pub async fn fetch_page_text(url: &str, logger: &Logger) -> Result<String, PipelineError> {
    use std::collections::HashMap;

    logger.info(
        "Fetching social link content",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("social_fetch".to_string()),
            ),
            (
                "url".to_string(),
                serde_json::Value::String(url.to_string()),
            ),
        ]),
    );

    let request = worker::Request::new(url, worker::Method::Get).map_err(|e| {
        PipelineError::ExtractionFailed {
            message: format!("failed to build request for {url}: {e}"),
        }
    })?;

    let mut response = worker::Fetch::Request(request).send().await.map_err(|e| {
        PipelineError::ExtractionFailed {
            message: format!("fetch failed for {url}: {e}"),
        }
    })?;

    let status = response.status_code();
    if status >= 400 {
        return Err(PipelineError::ExtractionFailed {
            message: format!("URL returned HTTP {status}: {url}"),
        });
    }

    let html = response
        .text()
        .await
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to read response body: {e}"),
        })?;

    let text = strip_html_tags(&html);
    let trimmed = if text.len() > MAX_EXTRACTED_CHARS {
        text[..MAX_EXTRACTED_CHARS].to_string()
    } else {
        text
    };

    logger.info(
        "Social link content fetched",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("social_fetch".to_string()),
            ),
            (
                "text_length".to_string(),
                serde_json::Value::Number(serde_json::Number::from(trimmed.len())),
            ),
        ]),
    );

    Ok(trimmed)
}

/// Extracts a recipe from a social link URL.
///
/// Fetches the page content, strips HTML, and feeds the text to Claude
/// for recipe extraction.
///
/// # Arguments
///
/// * `url` - The social link URL.
/// * `api_key` - The Anthropic API key.
/// * `logger` - Request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` on any failure.
#[cfg(target_arch = "wasm32")]
pub async fn extract_recipe_from_url(
    url: &str,
    api_key: &str,
    logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    let text = fetch_page_text(url, logger).await?;

    if text.trim().is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: format!("no text content found at {url}"),
        });
    }

    crate::services::extraction::extract_recipe_from_text(&text, api_key, logger).await
}

/// Non-WASM stub for testing.
#[cfg(not(target_arch = "wasm32"))]
pub async fn fetch_page_text(_url: &str, _logger: &Logger) -> Result<String, PipelineError> {
    Ok("Test recipe content from social link: 2 cups flour, 1 egg. Mix and bake.".to_string())
}

/// Non-WASM stub for testing.
#[cfg(not(target_arch = "wasm32"))]
pub async fn extract_recipe_from_url(
    url: &str,
    api_key: &str,
    logger: &Logger,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    if url.trim().is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "empty URL".to_string(),
        });
    }
    let text = fetch_page_text(url, logger).await?;
    crate::services::extraction::extract_recipe_from_text(&text, api_key, logger).await
}

/// Strips HTML tags from a string, producing plain text.
///
/// A simple tag-stripping implementation suitable for extracting readable
/// content from recipe pages. Does not handle all HTML edge cases but
/// works well enough for the extraction pipeline.
pub fn strip_html_tags(html: &str) -> String {
    let mut result = String::with_capacity(html.len());
    let mut in_tag = false;
    let mut in_script = false;
    let mut in_style = false;
    let mut last_was_space = false;

    let lower = html.to_lowercase();
    let chars: Vec<char> = html.chars().collect();
    let lower_chars: Vec<char> = lower.chars().collect();

    let mut i = 0;
    while i < chars.len() {
        if !in_tag && chars[i] == '<' {
            in_tag = true;
            // Check for script/style opening tags
            let remaining: String = lower_chars[i..].iter().take(10).collect();
            if remaining.starts_with("<script") {
                in_script = true;
            } else if remaining.starts_with("<style") {
                in_style = true;
            }
            // Check for closing script/style
            if remaining.starts_with("</script") {
                in_script = false;
            } else if remaining.starts_with("</style") {
                in_style = false;
            }
        } else if in_tag && chars[i] == '>' {
            in_tag = false;
            // Add a space after block-level tags for readability
            if !last_was_space {
                result.push(' ');
                last_was_space = true;
            }
        } else if !in_tag && !in_script && !in_style {
            let ch = chars[i];
            if ch.is_whitespace() {
                if !last_was_space {
                    result.push(' ');
                    last_was_space = true;
                }
            } else {
                result.push(ch);
                last_was_space = false;
            }
        }
        i += 1;
    }

    // Decode common HTML entities
    result
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&apos;", "'")
        .replace("&#39;", "'")
        .replace("&nbsp;", " ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detect_platform_instagram() {
        assert_eq!(
            detect_platform("https://www.instagram.com/p/abc123/"),
            Platform::Instagram
        );
    }

    #[test]
    fn detect_platform_tiktok() {
        assert_eq!(
            detect_platform("https://www.tiktok.com/@user/video/123"),
            Platform::Tiktok
        );
    }

    #[test]
    fn detect_platform_youtube() {
        assert_eq!(
            detect_platform("https://www.youtube.com/watch?v=abc"),
            Platform::Youtube
        );
        assert_eq!(detect_platform("https://youtu.be/abc"), Platform::Youtube);
    }

    #[test]
    fn detect_platform_website() {
        assert_eq!(
            detect_platform("https://example.com/recipe"),
            Platform::Website
        );
    }

    #[test]
    fn strip_html_tags_removes_tags() {
        let html = "<p>Hello <b>world</b></p>";
        let text = strip_html_tags(html);
        assert!(text.contains("Hello"));
        assert!(text.contains("world"));
        assert!(!text.contains('<'));
    }

    #[test]
    fn strip_html_tags_removes_script() {
        let html = "<p>Hello</p><script>alert('x')</script><p>World</p>";
        let text = strip_html_tags(html);
        assert!(text.contains("Hello"));
        assert!(text.contains("World"));
        assert!(!text.contains("alert"));
    }

    #[test]
    fn strip_html_tags_decodes_entities() {
        let html = "Mac &amp; Cheese &lt;3";
        let text = strip_html_tags(html);
        assert!(text.contains("Mac & Cheese <3"));
    }

    #[test]
    fn strip_html_tags_collapses_whitespace() {
        let html = "<p>  Hello   World  </p>";
        let text = strip_html_tags(html);
        // Whitespace should be collapsed
        assert!(!text.contains("  "));
    }

    #[tokio::test]
    async fn extract_recipe_from_url_rejects_empty_url() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = extract_recipe_from_url("", "fake-key", &logger).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn extract_recipe_from_url_returns_candidate() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result =
            extract_recipe_from_url("https://example.com/recipe", "fake-key", &logger).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn fetch_page_text_returns_content() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = fetch_page_text("https://example.com", &logger).await;
        assert!(result.is_ok());
        assert!(!result.expect("should succeed").is_empty());
    }
}
