//! Social link extraction service.
//!
//! Fetches web page content from social media URLs (Instagram, TikTok, YouTube,
//! blogs) and extracts recipe-relevant text. The extracted text is then fed into
//! the existing Claude extraction pipeline for structuring.
//!
//! This service is called during the async capture pipeline for
//! `CaptureInput::SocialLink` inputs.

use crate::logging::Logger;
use crate::pipeline::errors::PipelineError;
use crate::types::recipe::Platform;

/// Detects the platform from a URL.
///
/// Examines the hostname of the URL to determine which social platform
/// it belongs to. Returns `Platform::Unknown` if the URL cannot be
/// parsed or the hostname is not recognized.
///
/// # Examples
///
/// ```ignore
/// let platform = detect_platform("https://www.instagram.com/p/abc123");
/// assert_eq!(platform, Platform::Instagram);
/// ```
pub fn detect_platform(url: &str) -> Platform {
    let lower = url.to_lowercase();

    if lower.contains("instagram.com") || lower.contains("instagr.am") {
        Platform::Instagram
    } else if lower.contains("tiktok.com") || lower.contains("vm.tiktok.com") {
        Platform::Tiktok
    } else if lower.contains("youtube.com")
        || lower.contains("youtu.be")
        || lower.contains("youtube.com/shorts")
    {
        Platform::Youtube
    } else if lower.starts_with("http://") || lower.starts_with("https://") {
        Platform::Website
    } else {
        Platform::Unknown
    }
}

/// Validates that a URL looks reasonable for social link capture.
///
/// Checks that the URL starts with `http://` or `https://` and has
/// a minimum length. Does NOT fetch the URL.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the URL is invalid.
pub fn validate_url(url: &str) -> Result<(), PipelineError> {
    let trimmed = url.trim();
    if trimmed.is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "URL cannot be empty".to_string(),
        });
    }

    if !trimmed.starts_with("http://") && !trimmed.starts_with("https://") {
        return Err(PipelineError::ExtractionFailed {
            message: format!("URL must start with http:// or https://: {trimmed}"),
        });
    }

    // Minimum viable URL: "http://x.co" = 11 chars
    if trimmed.len() < 11 {
        return Err(PipelineError::ExtractionFailed {
            message: format!("URL is too short: {trimmed}"),
        });
    }

    Ok(())
}

/// Fetches the web page at the given URL and extracts text content.
///
/// Uses the Worker Fetch API to retrieve the page HTML, then strips
/// HTML tags to extract readable text. The resulting text is suitable
/// for feeding into the Claude extraction pipeline.
///
/// # Arguments
///
/// * `url` - The URL to fetch.
/// * `logger` - The request logger for structured logging.
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the fetch fails or
/// the page cannot be read.
#[cfg(target_arch = "wasm32")]
pub async fn fetch_page_text(url: &str, logger: &Logger) -> Result<String, PipelineError> {
    use std::collections::HashMap;
    use worker::wasm_bindgen::JsValue;

    logger.info(
        "Fetching social link page content",
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

    let headers = worker::Headers::new();
    headers
        .set(
            "User-Agent",
            "Mozilla/5.0 (compatible; DishyBot/1.0; +https://dishy.app)",
        )
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to set User-Agent header: {e}"),
        })?;
    headers
        .set(
            "Accept",
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        )
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to set Accept header: {e}"),
        })?;

    let request = worker::Request::new_with_init(
        url,
        worker::RequestInit::new()
            .with_method(worker::Method::Get)
            .with_headers(headers)
            .with_redirect(worker::RequestRedirect::Follow),
    )
    .map_err(|e| PipelineError::ExtractionFailed {
        message: format!("failed to build request for {url}: {e}"),
    })?;

    let mut response = worker::Fetch::Request(request).send().await.map_err(|e| {
        PipelineError::ExtractionFailed {
            message: format!("fetch failed for {url}: {e}"),
        }
    })?;

    let status = response.status_code();
    if status >= 400 {
        let body_preview = response
            .text()
            .await
            .unwrap_or_default()
            .chars()
            .take(200)
            .collect::<String>();

        logger.warn(
            "Social link fetch returned error status",
            HashMap::from([
                (
                    "status".to_string(),
                    serde_json::Value::Number(serde_json::Number::from(status)),
                ),
                (
                    "url".to_string(),
                    serde_json::Value::String(url.to_string()),
                ),
            ]),
        );

        return Err(PipelineError::ExtractionFailed {
            message: format!("page returned HTTP {status}: {body_preview}"),
        });
    }

    let html = response
        .text()
        .await
        .map_err(|e| PipelineError::ExtractionFailed {
            message: format!("failed to read page body: {e}"),
        })?;

    let text = strip_html_tags(&html);

    logger.info(
        "Social link page text extracted",
        HashMap::from([
            (
                "stage".to_string(),
                serde_json::Value::String("social_fetch".to_string()),
            ),
            (
                "text_length".to_string(),
                serde_json::Value::Number(serde_json::Number::from(text.len())),
            ),
        ]),
    );

    if text.trim().is_empty() {
        return Err(PipelineError::ExtractionFailed {
            message: "page contained no extractable text".to_string(),
        });
    }

    // Truncate to a reasonable size to avoid sending too much to Claude
    let truncated = if text.len() > 50_000 {
        text[..50_000].to_string()
    } else {
        text
    };

    Ok(truncated)
}

/// Non-WASM stub for testing -- returns sample page text.
#[cfg(not(target_arch = "wasm32"))]
pub async fn fetch_page_text(url: &str, _logger: &Logger) -> Result<String, PipelineError> {
    if url.contains("fail") {
        return Err(PipelineError::ExtractionFailed {
            message: "simulated fetch failure".to_string(),
        });
    }

    Ok(format!(
        "Recipe from {url}\n\n\
         Chocolate Chip Cookies\n\n\
         Ingredients:\n\
         2 cups flour\n\
         1 cup sugar\n\
         1 cup butter\n\
         2 eggs\n\
         1 tsp vanilla\n\n\
         Instructions:\n\
         1. Preheat oven to 375F\n\
         2. Mix dry ingredients\n\
         3. Cream butter and sugar\n\
         4. Add eggs and vanilla\n\
         5. Combine wet and dry\n\
         6. Drop onto baking sheet\n\
         7. Bake 9-11 minutes"
    ))
}

/// Strips HTML tags from a string, returning only visible text content.
///
/// This is a simple tag-stripping implementation that handles common
/// HTML patterns. It removes `<script>`, `<style>`, and `<noscript>`
/// blocks entirely, collapses whitespace, and preserves text content.
pub fn strip_html_tags(html: &str) -> String {
    let mut result = String::with_capacity(html.len() / 3);
    let mut inside_tag = false;
    let mut inside_script = false;
    let mut inside_style = false;
    let chars: Vec<char> = html.chars().collect();
    let len = chars.len();
    let mut i = 0;

    while i < len {
        if inside_script || inside_style {
            // Look for the closing tag
            let closing = if inside_script { "</script" } else { "</style" };
            if i + closing.len() < len {
                let window: String = chars[i..i + closing.len()].iter().collect();
                if window.to_lowercase() == closing {
                    inside_script = false;
                    inside_style = false;
                    // Skip past the closing tag
                    while i < len && chars[i] != '>' {
                        i += 1;
                    }
                    i += 1; // skip '>'
                    continue;
                }
            }
            i += 1;
            continue;
        }

        if chars[i] == '<' {
            // Check for script/style opening
            let remaining: String = chars[i..].iter().take(10).collect();
            let lower = remaining.to_lowercase();
            if lower.starts_with("<script") {
                inside_script = true;
                inside_tag = true;
            } else if lower.starts_with("<style") {
                inside_style = true;
                inside_tag = true;
            } else {
                inside_tag = true;
            }
            i += 1;
            continue;
        }

        if chars[i] == '>' {
            inside_tag = false;
            result.push(' ');
            i += 1;
            continue;
        }

        if !inside_tag {
            result.push(chars[i]);
        }
        i += 1;
    }

    // Collapse multiple whitespace into single spaces and trim
    let collapsed: String = result.split_whitespace().collect::<Vec<&str>>().join(" ");

    collapsed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detect_platform_instagram() {
        assert_eq!(
            detect_platform("https://www.instagram.com/p/abc123"),
            Platform::Instagram
        );
        assert_eq!(
            detect_platform("https://instagr.am/abc"),
            Platform::Instagram
        );
    }

    #[test]
    fn detect_platform_tiktok() {
        assert_eq!(
            detect_platform("https://www.tiktok.com/@user/video/123"),
            Platform::Tiktok
        );
        assert_eq!(
            detect_platform("https://vm.tiktok.com/abc"),
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
        assert_eq!(
            detect_platform("https://youtube.com/shorts/abc"),
            Platform::Youtube
        );
    }

    #[test]
    fn detect_platform_website() {
        assert_eq!(
            detect_platform("https://www.allrecipes.com/recipe/123"),
            Platform::Website
        );
    }

    #[test]
    fn detect_platform_unknown() {
        assert_eq!(detect_platform("not-a-url"), Platform::Unknown);
    }

    #[test]
    fn validate_url_accepts_valid_urls() {
        assert!(validate_url("https://example.com").is_ok());
        assert!(validate_url("http://example.com/path").is_ok());
    }

    #[test]
    fn validate_url_rejects_empty() {
        assert!(validate_url("").is_err());
        assert!(validate_url("   ").is_err());
    }

    #[test]
    fn validate_url_rejects_non_http() {
        assert!(validate_url("ftp://example.com").is_err());
        assert!(validate_url("not-a-url").is_err());
    }

    #[test]
    fn validate_url_rejects_too_short() {
        assert!(validate_url("http://x").is_err());
    }

    #[test]
    fn strip_html_tags_basic() {
        assert_eq!(strip_html_tags("<p>Hello</p>"), "Hello");
    }

    #[test]
    fn strip_html_tags_removes_scripts() {
        let html = "<p>Before</p><script>var x = 1;</script><p>After</p>";
        let text = strip_html_tags(html);
        assert!(text.contains("Before"));
        assert!(text.contains("After"));
        assert!(!text.contains("var x"));
    }

    #[test]
    fn strip_html_tags_removes_styles() {
        let html = "<p>Text</p><style>.x { color: red; }</style><p>More</p>";
        let text = strip_html_tags(html);
        assert!(text.contains("Text"));
        assert!(text.contains("More"));
        assert!(!text.contains("color"));
    }

    #[test]
    fn strip_html_tags_collapses_whitespace() {
        let html = "<p>  Hello  </p>  <p>  World  </p>";
        let text = strip_html_tags(html);
        assert_eq!(text, "Hello World");
    }

    #[test]
    fn strip_html_tags_handles_empty_input() {
        assert_eq!(strip_html_tags(""), "");
    }

    #[test]
    fn strip_html_tags_handles_plain_text() {
        assert_eq!(strip_html_tags("plain text"), "plain text");
    }

    #[tokio::test]
    async fn fetch_page_text_returns_text_for_valid_url() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = fetch_page_text("https://example.com", &logger).await;
        assert!(result.is_ok());
        let text = result.expect("should succeed");
        assert!(!text.is_empty());
    }

    #[tokio::test]
    async fn fetch_page_text_fails_for_fail_url() {
        let logger = crate::logging::Logger::new("test".to_string(), "test".to_string());
        let result = fetch_page_text("https://fail.example.com", &logger).await;
        assert!(result.is_err());
    }
}
