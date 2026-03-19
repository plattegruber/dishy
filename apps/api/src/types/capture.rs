//! Capture input types and extraction artifacts from SPEC §8.1.
//!
//! These types represent the first two stages of the recipe capture pipeline:
//! 1. **CaptureInput** — the raw input from the user (link, image, speech, text).
//! 2. **ExtractionArtifact** — the raw extraction output from processing the input.
//! 3. **StructuredRecipeCandidate** — a structured recipe parsed from the artifact.

use serde::{Deserialize, Serialize};

use super::ids::{AssetId, CaptureId};
use super::recipe::Source;

/// The raw input provided by the user to capture a recipe.
///
/// Each variant represents a different capture modality. The system accepts
/// any of these and routes them through the appropriate extraction pipeline.
///
/// Maps to SPEC §8.1 `CaptureInput`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum CaptureInput {
    /// A URL to a social media post or website containing a recipe.
    SocialLink {
        /// The URL of the social media post or recipe page.
        url: String,
    },
    /// A screenshot of a recipe (e.g., from a social media app).
    Screenshot {
        /// Reference to the uploaded screenshot image asset.
        image: AssetId,
    },
    /// A scanned physical recipe (e.g., from a cookbook or handwritten note).
    Scan {
        /// Reference to the uploaded scan image asset.
        image: AssetId,
    },
    /// A spoken recipe captured via speech-to-text.
    Speech {
        /// The transcribed text from the speech input.
        transcript: String,
    },
    /// A manually entered recipe in free-form text.
    Manual {
        /// The raw text entered by the user.
        text: String,
    },
}

/// The result of running extraction on a `CaptureInput`.
///
/// Contains all raw data extracted from the input before structuring.
/// Extraction artifacts are versioned to support reprocessing — each time
/// extraction is re-run, a new version is created without overwriting the
/// previous one.
///
/// Maps to SPEC §8.1 `ExtractionArtifact`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractionArtifact {
    /// The capture input that produced this artifact.
    pub id: CaptureId,
    /// Version number for reprocessing support (starts at 1).
    pub version: i32,
    /// Raw text extracted directly from the input, if available.
    pub raw_text: Option<String>,
    /// Text extracted via OCR from images, if applicable.
    pub ocr_text: Option<String>,
    /// Text from speech transcription, if applicable.
    pub transcript: Option<String>,
    /// Individual ingredient text lines found in the source.
    pub ingredients: Vec<String>,
    /// Individual step text lines found in the source.
    pub steps: Vec<String>,
    /// References to images found in or associated with the source.
    pub images: Vec<AssetId>,
    /// Attribution and platform information about the source.
    pub source: Source,
    /// Confidence score for the extraction quality (0.0 to 1.0).
    pub confidence: f64,
}

/// A recipe candidate parsed and structured from an extraction artifact.
///
/// This is the output of the structuring service — it takes the raw
/// extraction data and organizes it into recognizable recipe fields.
/// Fields are optional because the structuring service may not be able
/// to determine all of them.
///
/// Maps to SPEC §8.1 `StructuredRecipeCandidate`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StructuredRecipeCandidate {
    /// The recipe title, if it could be identified.
    pub title: Option<String>,
    /// Raw ingredient lines as extracted (not yet parsed).
    pub ingredient_lines: Vec<String>,
    /// Step-by-step instructions.
    pub steps: Vec<String>,
    /// Number of servings, if identified.
    pub servings: Option<i32>,
    /// Total time in minutes, if identified.
    pub time_minutes: Option<i32>,
    /// Tags or categories associated with the recipe.
    pub tags: Vec<String>,
    /// Confidence score for the structuring quality (0.0 to 1.0).
    pub confidence: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn capture_input_social_link_roundtrips() {
        let input = CaptureInput::SocialLink {
            url: "https://instagram.com/p/abc123".to_string(),
        };
        let json = serde_json::to_string(&input).expect("should serialize");
        let deserialized: CaptureInput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CaptureInput::SocialLink { url } => {
                assert_eq!(url, "https://instagram.com/p/abc123");
            }
            _ => panic!("expected SocialLink variant"),
        }
    }

    #[test]
    fn capture_input_screenshot_roundtrips() {
        let input = CaptureInput::Screenshot {
            image: AssetId::new("asset_img_001"),
        };
        let json = serde_json::to_string(&input).expect("should serialize");
        let deserialized: CaptureInput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CaptureInput::Screenshot { image } => {
                assert_eq!(image.as_str(), "asset_img_001");
            }
            _ => panic!("expected Screenshot variant"),
        }
    }

    #[test]
    fn capture_input_scan_roundtrips() {
        let input = CaptureInput::Scan {
            image: AssetId::new("asset_scan_001"),
        };
        let json = serde_json::to_string(&input).expect("should serialize");
        let deserialized: CaptureInput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CaptureInput::Scan { image } => {
                assert_eq!(image.as_str(), "asset_scan_001");
            }
            _ => panic!("expected Scan variant"),
        }
    }

    #[test]
    fn capture_input_speech_roundtrips() {
        let input = CaptureInput::Speech {
            transcript: "Add two cups of flour".to_string(),
        };
        let json = serde_json::to_string(&input).expect("should serialize");
        let deserialized: CaptureInput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CaptureInput::Speech { transcript } => {
                assert_eq!(transcript, "Add two cups of flour");
            }
            _ => panic!("expected Speech variant"),
        }
    }

    #[test]
    fn capture_input_manual_roundtrips() {
        let input = CaptureInput::Manual {
            text: "1 cup sugar, 2 eggs".to_string(),
        };
        let json = serde_json::to_string(&input).expect("should serialize");
        let deserialized: CaptureInput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CaptureInput::Manual { text } => {
                assert_eq!(text, "1 cup sugar, 2 eggs");
            }
            _ => panic!("expected Manual variant"),
        }
    }

    #[test]
    fn capture_input_serializes_with_type_tag() {
        let input = CaptureInput::SocialLink {
            url: "https://example.com".to_string(),
        };
        let json = serde_json::to_value(&input).expect("should serialize");
        assert_eq!(json["type"], "social_link");
        assert_eq!(json["url"], "https://example.com");
    }

    #[test]
    fn extraction_artifact_roundtrips() {
        let artifact = ExtractionArtifact {
            id: CaptureId::new("capture_001"),
            version: 1,
            raw_text: Some("raw text here".to_string()),
            ocr_text: None,
            transcript: None,
            ingredients: vec!["1 cup flour".to_string(), "2 eggs".to_string()],
            steps: vec!["Mix ingredients".to_string()],
            images: vec![AssetId::new("img_001")],
            source: Source {
                platform: super::super::recipe::Platform::Instagram,
                url: Some("https://instagram.com/p/abc".to_string()),
                creator_handle: Some("@chef".to_string()),
                creator_id: None,
            },
            confidence: 0.85,
        };
        let json = serde_json::to_string(&artifact).expect("should serialize");
        let deserialized: ExtractionArtifact =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.id.as_str(), "capture_001");
        assert_eq!(deserialized.version, 1);
        assert_eq!(deserialized.ingredients.len(), 2);
        assert_eq!(deserialized.confidence, 0.85);
    }

    #[test]
    fn structured_recipe_candidate_roundtrips() {
        let candidate = StructuredRecipeCandidate {
            title: Some("Chocolate Cake".to_string()),
            ingredient_lines: vec!["2 cups flour".to_string(), "1 cup sugar".to_string()],
            steps: vec![
                "Preheat oven".to_string(),
                "Mix dry ingredients".to_string(),
            ],
            servings: Some(8),
            time_minutes: Some(45),
            tags: vec!["dessert".to_string(), "baking".to_string()],
            confidence: 0.92,
        };
        let json = serde_json::to_string(&candidate).expect("should serialize");
        let deserialized: StructuredRecipeCandidate =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.title.as_deref(), Some("Chocolate Cake"));
        assert_eq!(deserialized.ingredient_lines.len(), 2);
        assert_eq!(deserialized.servings, Some(8));
        assert_eq!(deserialized.time_minutes, Some(45));
    }

    #[test]
    fn structured_recipe_candidate_handles_optional_fields() {
        let candidate = StructuredRecipeCandidate {
            title: None,
            ingredient_lines: vec![],
            steps: vec![],
            servings: None,
            time_minutes: None,
            tags: vec![],
            confidence: 0.5,
        };
        let json = serde_json::to_string(&candidate).expect("should serialize");
        let deserialized: StructuredRecipeCandidate =
            serde_json::from_str(&json).expect("should deserialize");
        assert!(deserialized.title.is_none());
        assert!(deserialized.servings.is_none());
        assert!(deserialized.time_minutes.is_none());
    }
}
