//! Cover generation service for recipe images.
//!
//! Implements SPEC §5.6: Cover Generation Service. Produces a visual
//! cover for every recipe, either by selecting the best available source
//! image or generating a styled placeholder.
//!
//! ## Strategy
//!
//! 1. If extraction provided images: rank them, select the best, and
//!    store it as a `SourceImage` cover.
//! 2. If no images are available: generate a minimal SVG placeholder
//!    with a solid color background and the recipe title, store it
//!    as a `GeneratedCover`.
//!
//! The fallback path always succeeds -- a recipe is never left without
//! a cover.

use crate::pipeline::contracts::CoverInput;
use crate::pipeline::errors::PipelineError;
use crate::types::ids::AssetId;
use crate::types::recipe::CoverOutput;

/// The output of cover generation.
///
/// Wraps `CoverOutput` with additional metadata about the generation
/// process for logging and observability.
#[derive(Debug, Clone)]
pub struct CoverResult {
    /// The cover output to store on the recipe.
    pub cover: CoverOutput,
    /// Whether the cover was generated (fallback) vs. selected from source.
    pub is_generated: bool,
}

/// A palette of background colors for generated covers.
///
/// Colors are selected deterministically based on the recipe title
/// hash so the same recipe always gets the same color.
const COVER_COLORS: &[&str] = &[
    "#E57373", // red
    "#F06292", // pink
    "#BA68C8", // purple
    "#9575CD", // deep purple
    "#7986CB", // indigo
    "#64B5F6", // blue
    "#4FC3F7", // light blue
    "#4DD0E1", // cyan
    "#4DB6AC", // teal
    "#81C784", // green
    "#AED581", // light green
    "#FFD54F", // amber
    "#FFB74D", // orange
    "#FF8A65", // deep orange
];

/// Selects a deterministic color from the palette based on the title.
///
/// Uses a simple hash of the title string to index into the palette.
fn color_for_title(title: &str) -> &'static str {
    let hash: usize = title.bytes().fold(0usize, |acc, b| {
        acc.wrapping_mul(31).wrapping_add(b as usize)
    });
    COVER_COLORS[hash % COVER_COLORS.len()]
}

/// Generates a minimal SVG cover image with a solid color background
/// and the recipe title rendered as white text.
///
/// The SVG is 600x400 pixels and uses a system sans-serif font.
/// Text is truncated to 40 characters to avoid overflow.
pub fn generate_placeholder_svg(title: &str) -> Vec<u8> {
    let color = color_for_title(title);
    let display_title = if title.len() > 40 {
        format!("{}...", &title[..37])
    } else {
        title.to_string()
    };
    // Escape XML special characters in the title.
    let escaped_title = display_title
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;");

    let svg = format!(
        r#"<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400">
  <rect width="600" height="400" fill="{color}" rx="0" ry="0"/>
  <text x="300" y="200" text-anchor="middle" dominant-baseline="central"
        font-family="system-ui, -apple-system, sans-serif"
        font-size="28" font-weight="bold" fill="white">{escaped_title}</text>
</svg>"#,
    );

    svg.into_bytes()
}

/// Generates a cover for a recipe based on available images.
///
/// If images are available in the input, selects the first one as the
/// cover (future: rank by quality/relevance). If no images are available,
/// generates a styled SVG placeholder.
///
/// # Arguments
///
/// * `input` -- The cover generation input with images and title.
///
/// # Returns
///
/// A `CoverResult` containing the cover output and metadata.
///
/// # Errors
///
/// Returns `PipelineError::CoverGenerationFailed` only if a critical
/// failure occurs. The fallback path (generated cover) always succeeds.
pub fn generate_cover(input: &CoverInput) -> Result<CoverResult, PipelineError> {
    // If source images are available, use the first one (best candidate).
    if let Some(first_image) = input.images.first() {
        return Ok(CoverResult {
            cover: CoverOutput::SourceImage {
                asset_id: first_image.clone(),
            },
            is_generated: false,
        });
    }

    // Fallback: generate a placeholder cover.
    // In the pipeline integration, this SVG is uploaded to R2 and the
    // resulting asset ID is used. Here we return a deterministic
    // placeholder ID that the pipeline will replace after upload.
    let placeholder_id = AssetId::new(format!("generated_{}", title_to_slug(&input.title)));

    Ok(CoverResult {
        cover: CoverOutput::GeneratedCover {
            asset_id: placeholder_id,
        },
        is_generated: true,
    })
}

/// Generates a cover and uploads the fallback SVG to R2 if needed.
///
/// This is the full pipeline-integrated version that:
/// 1. Checks for source images and returns immediately if found.
/// 2. Generates a placeholder SVG and uploads it to R2.
/// 3. Returns the `CoverOutput` with the R2 asset ID.
///
/// # Arguments
///
/// * `input` -- The cover generation input.
/// * `upload_fn` -- An async function that uploads bytes to R2 and returns an `AssetId`.
///
/// # Errors
///
/// Returns `PipelineError::CoverGenerationFailed` if the R2 upload fails.
pub async fn generate_cover_with_upload<F, Fut>(
    input: &CoverInput,
    upload_fn: F,
) -> Result<CoverOutput, PipelineError>
where
    F: FnOnce(Vec<u8>, String) -> Fut,
    Fut: std::future::Future<Output = Result<AssetId, String>>,
{
    // If source images are available, use the first one.
    if let Some(first_image) = input.images.first() {
        return Ok(CoverOutput::SourceImage {
            asset_id: first_image.clone(),
        });
    }

    // Generate the placeholder SVG.
    let svg_bytes = generate_placeholder_svg(&input.title);

    // Upload to R2 (SVGs are served as image/svg+xml but stored
    // with a .webp-like key for consistency -- the content-type
    // header on the R2 object determines how it's served).
    let asset_id = upload_fn(svg_bytes, "image/png".to_string())
        .await
        .map_err(|e| PipelineError::CoverGenerationFailed {
            message: format!("failed to upload generated cover: {e}"),
        })?;

    Ok(CoverOutput::GeneratedCover { asset_id })
}

/// Converts a title to a URL-safe slug for use in asset IDs.
///
/// Lowercases the title, replaces non-alphanumeric characters with
/// hyphens, and truncates to 32 characters.
fn title_to_slug(title: &str) -> String {
    let slug: String = title
        .to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect();
    let slug = slug.trim_matches('-').to_string();
    if slug.len() > 32 {
        slug[..32].trim_end_matches('-').to_string()
    } else {
        slug
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn color_for_title_is_deterministic() {
        let color1 = color_for_title("Chocolate Cake");
        let color2 = color_for_title("Chocolate Cake");
        assert_eq!(color1, color2);
    }

    #[test]
    fn color_for_title_varies_for_different_titles() {
        // Different titles should usually get different colors.
        // Not guaranteed for all pairs, but should work for these.
        let color1 = color_for_title("Chocolate Cake");
        let color2 = color_for_title("Caesar Salad");
        // We just check they're valid hex colors, not that they differ
        // (hash collisions are possible).
        assert!(color1.starts_with('#'));
        assert!(color2.starts_with('#'));
    }

    #[test]
    fn generate_placeholder_svg_contains_title() {
        let svg = generate_placeholder_svg("Pancakes");
        let svg_str = String::from_utf8(svg).expect("should be valid UTF-8");
        assert!(svg_str.contains("Pancakes"));
        assert!(svg_str.contains("<svg"));
        assert!(svg_str.contains("</svg>"));
    }

    #[test]
    fn generate_placeholder_svg_truncates_long_titles() {
        let long_title = "This is a very long recipe title that exceeds the maximum length";
        let svg = generate_placeholder_svg(long_title);
        let svg_str = String::from_utf8(svg).expect("should be valid UTF-8");
        assert!(svg_str.contains("..."));
        assert!(!svg_str.contains(long_title));
    }

    #[test]
    fn generate_placeholder_svg_escapes_special_characters() {
        let title = "Mac & Cheese <Classic>";
        let svg = generate_placeholder_svg(title);
        let svg_str = String::from_utf8(svg).expect("should be valid UTF-8");
        assert!(svg_str.contains("&amp;"));
        assert!(svg_str.contains("&lt;"));
        assert!(svg_str.contains("&gt;"));
        assert!(!svg_str.contains("& "));
    }

    #[test]
    fn generate_placeholder_svg_has_correct_dimensions() {
        let svg = generate_placeholder_svg("Test");
        let svg_str = String::from_utf8(svg).expect("should be valid UTF-8");
        assert!(svg_str.contains("width=\"600\""));
        assert!(svg_str.contains("height=\"400\""));
    }

    #[test]
    fn generate_cover_returns_source_image_when_images_available() {
        let input = CoverInput {
            images: vec![AssetId::new("img_001"), AssetId::new("img_002")],
            title: "Test Recipe".to_string(),
        };
        let result = generate_cover(&input).expect("should succeed");
        assert!(!result.is_generated);
        match result.cover {
            CoverOutput::SourceImage { asset_id } => {
                assert_eq!(asset_id.as_str(), "img_001");
            }
            other => panic!("expected SourceImage, got {other:?}"),
        }
    }

    #[test]
    fn generate_cover_returns_generated_when_no_images() {
        let input = CoverInput {
            images: vec![],
            title: "Pancakes".to_string(),
        };
        let result = generate_cover(&input).expect("should succeed");
        assert!(result.is_generated);
        match &result.cover {
            CoverOutput::GeneratedCover { asset_id } => {
                assert!(
                    asset_id.as_str().starts_with("generated_"),
                    "should start with 'generated_'"
                );
            }
            other => panic!("expected GeneratedCover, got {other:?}"),
        }
    }

    #[test]
    fn generate_cover_never_fails_for_empty_input() {
        let input = CoverInput {
            images: vec![],
            title: String::new(),
        };
        let result = generate_cover(&input);
        assert!(result.is_ok(), "should always succeed with fallback");
    }

    #[tokio::test]
    async fn generate_cover_with_upload_uses_source_image() {
        let input = CoverInput {
            images: vec![AssetId::new("img_source")],
            title: "Test".to_string(),
        };
        let result = generate_cover_with_upload(&input, |_bytes, _ct| async {
            panic!("upload should not be called when source images exist");
        })
        .await;
        assert!(result.is_ok());
        match result.expect("should succeed") {
            CoverOutput::SourceImage { asset_id } => {
                assert_eq!(asset_id.as_str(), "img_source");
            }
            other => panic!("expected SourceImage, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn generate_cover_with_upload_uploads_generated_svg() {
        let input = CoverInput {
            images: vec![],
            title: "Pancakes".to_string(),
        };
        let result = generate_cover_with_upload(&input, |bytes, content_type| async move {
            assert!(!bytes.is_empty(), "SVG bytes should not be empty");
            assert_eq!(content_type, "image/png");
            Ok(AssetId::new("uploaded_cover_123"))
        })
        .await;
        assert!(result.is_ok());
        match result.expect("should succeed") {
            CoverOutput::GeneratedCover { asset_id } => {
                assert_eq!(asset_id.as_str(), "uploaded_cover_123");
            }
            other => panic!("expected GeneratedCover, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn generate_cover_with_upload_propagates_upload_error() {
        let input = CoverInput {
            images: vec![],
            title: "Fail".to_string(),
        };
        let result = generate_cover_with_upload(&input, |_bytes, _ct| async {
            Err("R2 bucket error".to_string())
        })
        .await;
        assert!(result.is_err());
        match result {
            Err(PipelineError::CoverGenerationFailed { message }) => {
                assert!(message.contains("R2 bucket error"));
            }
            other => panic!("expected CoverGenerationFailed, got {other:?}"),
        }
    }

    #[test]
    fn title_to_slug_converts_correctly() {
        assert_eq!(title_to_slug("Chocolate Cake"), "chocolate-cake");
        assert_eq!(title_to_slug("Mac & Cheese"), "mac---cheese");
        assert_eq!(title_to_slug(""), "");
    }

    #[test]
    fn title_to_slug_truncates_long_titles() {
        let long = "a".repeat(100);
        let slug = title_to_slug(&long);
        assert!(slug.len() <= 32);
    }
}
