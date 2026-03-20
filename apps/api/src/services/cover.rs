//! Cover generation service for recipes.
//!
//! Implements SPEC section 5.6 — generates a consistent visual representation
//! for every recipe. If source images are available, the best one is uploaded
//! to R2 and returned as a `SourceImage`. When no images exist, a deterministic
//! SVG placeholder is generated from the recipe title and stored in R2.
//!
//! **Design guarantee:** Cover generation always succeeds. A recipe is never
//! left without a cover image.

#[cfg(target_arch = "wasm32")]
use crate::logging::Logger;
use crate::types::ids::AssetId;
use crate::types::recipe::CoverOutput;
#[cfg(target_arch = "wasm32")]
use std::collections::HashMap;

/// Palette of warm, food-friendly colors for generated covers.
///
/// Each color is selected to look appealing as a recipe card background.
/// The title string is hashed to deterministically pick one color, so
/// the same recipe always gets the same cover color.
const COVER_COLORS: &[&str] = &[
    "#E8533F", // tomato red
    "#F2994A", // carrot orange
    "#F2C94C", // butter yellow
    "#6FCF97", // herb green
    "#56CCF2", // sky blue
    "#BB6BD9", // plum purple
    "#EB5757", // strawberry
    "#F2784B", // paprika
    "#2D9CDB", // blueberry
    "#27AE60", // basil green
];

/// Generates a cover for a recipe, either from a source image or as a
/// generated SVG placeholder.
///
/// When `image_data` is provided (from multipart upload), it is uploaded
/// to R2 and the resulting asset ID is returned as a `SourceImage`.
///
/// When no image data is available, a deterministic SVG placeholder is
/// generated from the recipe title and uploaded to R2 as a `GeneratedCover`.
///
/// # Arguments
///
/// * `bucket` - The R2 bucket for image storage.
/// * `image_data` - Optional raw image bytes from a user upload.
/// * `content_type` - The MIME type of the uploaded image (if any).
/// * `title` - The recipe title, used for the generated placeholder.
/// * `logger` - Request logger for structured logging.
///
/// # Returns
///
/// Always returns a `CoverOutput`. Never fails — falls back to an in-memory
/// placeholder asset ID if R2 is unavailable.
#[cfg(target_arch = "wasm32")]
pub async fn generate_cover(
    bucket: &worker::Bucket,
    image_data: Option<&[u8]>,
    content_type: Option<&str>,
    title: &str,
    logger: &Logger,
) -> CoverOutput {
    // If we have source image data, upload it
    if let (Some(data), Some(ct)) = (image_data, content_type) {
        match crate::services::storage::upload_image(bucket, data, ct, logger).await {
            Ok(result) => {
                logger.info(
                    "Cover uploaded from source image",
                    HashMap::from([(
                        "asset_id".to_string(),
                        serde_json::Value::String(result.asset_id.as_str().to_string()),
                    )]),
                );
                return CoverOutput::SourceImage {
                    asset_id: result.asset_id,
                };
            }
            Err(e) => {
                logger.warn(
                    "Failed to upload source image for cover, falling back to generated",
                    HashMap::from([(
                        "error".to_string(),
                        serde_json::Value::String(e.to_string()),
                    )]),
                );
                // Fall through to generated cover
            }
        }
    }

    // Generate SVG placeholder
    let svg = generate_placeholder_svg(title);

    // Try to upload the SVG to R2
    let asset_id = AssetId::new(uuid::Uuid::new_v4().to_string());
    let key = format!("images/{}.svg", asset_id.as_str());

    let mut http_metadata = worker::HttpMetadata::default();
    http_metadata.content_type = Some("image/svg+xml".to_string());

    match bucket
        .put(&key, worker::Data::Bytes(svg.into_bytes()))
        .http_metadata(http_metadata)
        .execute()
        .await
    {
        Ok(_) => {
            logger.info(
                "Generated cover placeholder uploaded to R2",
                HashMap::from([(
                    "asset_id".to_string(),
                    serde_json::Value::String(asset_id.as_str().to_string()),
                )]),
            );
            CoverOutput::GeneratedCover { asset_id }
        }
        Err(e) => {
            logger.warn(
                "Failed to upload generated cover to R2, using in-memory placeholder",
                HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            // Fallback: return a deterministic placeholder ID based on the title
            let fallback_id = format!("placeholder_{}", simple_hash(title));
            CoverOutput::GeneratedCover {
                asset_id: AssetId::new(fallback_id),
            }
        }
    }
}

/// Generates a deterministic cover without R2 access.
///
/// Returns a `GeneratedCover` with a deterministic placeholder asset ID
/// derived from the recipe title. Used when the R2 bucket is not
/// available (e.g., in tests on the host target, or when the bucket
/// binding is missing in production).
pub fn generate_cover_stub(title: &str) -> CoverOutput {
    let hash = simple_hash(title);
    let color_index = (hash as usize) % COVER_COLORS.len();
    let _ = COVER_COLORS[color_index]; // verify index is valid
    let asset_id = format!("generated_{hash}");
    CoverOutput::GeneratedCover {
        asset_id: AssetId::new(asset_id),
    }
}

/// Generates a deterministic SVG placeholder for a recipe.
///
/// The SVG shows the first letter of the recipe title (capitalized) centered
/// on a warm-colored background. The color is deterministically chosen from
/// the title string so the same recipe always gets the same cover.
///
/// # Arguments
///
/// * `title` - The recipe title to generate a cover for.
pub fn generate_placeholder_svg(title: &str) -> String {
    let hash = simple_hash(title);
    let color_index = (hash as usize) % COVER_COLORS.len();
    let bg_color = COVER_COLORS[color_index];

    // Get the first letter of the title, or '?' if empty
    let initial = title
        .chars()
        .next()
        .map(|c| c.to_uppercase().to_string())
        .unwrap_or_else(|| "?".to_string());

    // Truncate title for subtitle display (max 30 chars)
    let display_title = if title.len() > 30 {
        format!("{}...", &title[..27])
    } else {
        title.to_string()
    };

    // Escape XML special characters in the title
    let escaped_title = escape_xml(&display_title);

    format!(
        r#"<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300">
  <rect width="400" height="300" fill="{bg_color}" rx="0"/>
  <text x="200" y="130" text-anchor="middle" font-family="system-ui, -apple-system, sans-serif" font-size="96" font-weight="bold" fill="rgba(255,255,255,0.9)">{initial}</text>
  <text x="200" y="200" text-anchor="middle" font-family="system-ui, -apple-system, sans-serif" font-size="18" fill="rgba(255,255,255,0.7)">{escaped_title}</text>
</svg>"#
    )
}

/// Deterministic hash of a string to a u32.
///
/// Uses a simple DJB2-like hash. Not cryptographic, but produces
/// consistent output for the same input across runs.
pub fn simple_hash(s: &str) -> u32 {
    let mut hash: u32 = 5381;
    for byte in s.bytes() {
        hash = hash.wrapping_mul(33).wrapping_add(u32::from(byte));
    }
    hash
}

/// Returns the deterministic color for a given recipe title.
///
/// Useful for the frontend to match the generated cover color
/// when the SVG hasn't loaded yet.
pub fn color_for_title(title: &str) -> &'static str {
    let hash = simple_hash(title);
    let index = (hash as usize) % COVER_COLORS.len();
    COVER_COLORS[index]
}

/// Escapes XML special characters in a string.
fn escape_xml(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn simple_hash_is_deterministic() {
        let h1 = simple_hash("Chocolate Cake");
        let h2 = simple_hash("Chocolate Cake");
        assert_eq!(h1, h2);
    }

    #[test]
    fn simple_hash_differs_for_different_inputs() {
        let h1 = simple_hash("Chocolate Cake");
        let h2 = simple_hash("Vanilla Pudding");
        assert_ne!(h1, h2);
    }

    #[test]
    fn color_for_title_is_deterministic() {
        let c1 = color_for_title("Chocolate Cake");
        let c2 = color_for_title("Chocolate Cake");
        assert_eq!(c1, c2);
    }

    #[test]
    fn color_for_title_returns_valid_hex() {
        let color = color_for_title("Test Recipe");
        assert!(color.starts_with('#'));
        assert_eq!(color.len(), 7);
    }

    #[test]
    fn generate_placeholder_svg_contains_initial() {
        let svg = generate_placeholder_svg("Chocolate Cake");
        assert!(svg.contains(">C<"));
    }

    #[test]
    fn generate_placeholder_svg_contains_title() {
        let svg = generate_placeholder_svg("Chocolate Cake");
        assert!(svg.contains("Chocolate Cake"));
    }

    #[test]
    fn generate_placeholder_svg_truncates_long_title() {
        let long_title = "This is a very long recipe title that should be truncated";
        let svg = generate_placeholder_svg(long_title);
        assert!(svg.contains("..."));
        assert!(!svg.contains(long_title));
    }

    #[test]
    fn generate_placeholder_svg_handles_empty_title() {
        let svg = generate_placeholder_svg("");
        assert!(svg.contains(">?<"));
    }

    #[test]
    fn generate_placeholder_svg_escapes_xml_characters() {
        let svg = generate_placeholder_svg("Mac & Cheese <Special>");
        assert!(svg.contains("&amp;"));
        assert!(svg.contains("&lt;"));
        assert!(svg.contains("&gt;"));
        assert!(!svg.contains("& "));
    }

    #[test]
    fn generate_placeholder_svg_is_valid_xml_structure() {
        let svg = generate_placeholder_svg("Test");
        assert!(svg.starts_with("<svg"));
        assert!(svg.ends_with("</svg>"));
        assert!(svg.contains("xmlns="));
    }

    #[test]
    fn cover_colors_are_valid_hex() {
        for color in COVER_COLORS {
            assert!(color.starts_with('#'), "color should start with #: {color}");
            assert_eq!(color.len(), 7, "color should be 7 chars: {color}");
        }
    }

    #[test]
    fn generate_cover_stub_returns_generated_cover() {
        let cover = generate_cover_stub("Test Recipe");
        match cover {
            CoverOutput::GeneratedCover { asset_id } => {
                assert!(asset_id.as_str().starts_with("generated_"));
            }
            other => panic!("expected GeneratedCover, got {other:?}"),
        }
    }

    #[test]
    fn generate_cover_stub_is_deterministic() {
        let cover1 = generate_cover_stub("Test Recipe");
        let cover2 = generate_cover_stub("Test Recipe");
        match (cover1, cover2) {
            (
                CoverOutput::GeneratedCover { asset_id: id1 },
                CoverOutput::GeneratedCover { asset_id: id2 },
            ) => {
                assert_eq!(id1.as_str(), id2.as_str());
            }
            _ => panic!("expected both to be GeneratedCover"),
        }
    }

    #[test]
    fn escape_xml_handles_all_special_chars() {
        let result = escape_xml("A & B < C > D \" E ' F");
        assert_eq!(result, "A &amp; B &lt; C &gt; D &quot; E &apos; F");
    }

    #[test]
    fn escape_xml_returns_plain_string_unchanged() {
        let result = escape_xml("Hello World");
        assert_eq!(result, "Hello World");
    }
}
