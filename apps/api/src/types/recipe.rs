//! Recipe types from SPEC §8.3 and §8.4.
//!
//! These types represent the final output of the capture pipeline:
//! - **Source** and **Platform** — attribution to the original content.
//! - **CoverOutput** — the visual representation of the recipe.
//! - **Step** — a single recipe step.
//! - **ResolvedRecipe** — the fully assembled canonical recipe.
//! - **UserRecipeView** — user-specific overlay on a recipe.
//! - **RecipePatch** — a user edit to a recipe field.

use serde::{Deserialize, Serialize};

use super::ids::{AssetId, RecipeId, UserId};
use super::ingredient::ResolvedIngredient;
use super::nutrition::NutritionComputation;

/// The content platform where a recipe was originally found.
///
/// Used for attribution and to select the appropriate extraction strategy.
///
/// Maps to SPEC §8.3 `Platform`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Platform {
    /// Instagram (posts, reels, stories).
    Instagram,
    /// TikTok videos.
    Tiktok,
    /// YouTube videos or Shorts.
    Youtube,
    /// A standalone website or blog.
    Website,
    /// Manually entered — no external platform.
    Manual,
    /// Platform could not be determined.
    Unknown,
}

/// Attribution information for the original recipe source.
///
/// Tracks where the recipe came from and who created it, supporting
/// the security and attribution requirements from SPEC §16.
///
/// Maps to SPEC §8.3 `Source`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Source {
    /// The platform where the recipe was found.
    pub platform: Platform,
    /// The original URL, if available.
    pub url: Option<String>,
    /// The content creator's handle (e.g., "@chefname").
    pub creator_handle: Option<String>,
    /// The content creator's platform-specific ID.
    pub creator_id: Option<String>,
}

/// The visual cover image for a recipe.
///
/// The cover generation service produces one of three variants depending
/// on the source material quality and availability.
///
/// Maps to SPEC §8.3 `CoverOutput`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum CoverOutput {
    /// An image taken directly from the source content.
    SourceImage {
        /// Reference to the source image asset in R2.
        asset_id: AssetId,
    },
    /// A source image that has been enhanced (cropped, color-corrected, etc.).
    EnhancedImage {
        /// Reference to the enhanced image asset in R2.
        asset_id: AssetId,
    },
    /// A generated cover image (fallback when no good source image exists).
    GeneratedCover {
        /// Reference to the generated cover asset in R2.
        asset_id: AssetId,
    },
}

/// A single step in a recipe's instructions.
///
/// Steps are ordered and numbered. Each step contains the instruction
/// text and an optional time duration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Step {
    /// The 1-based step number.
    pub number: i32,
    /// The instruction text for this step.
    pub instruction: String,
    /// Duration in minutes for this step, if applicable.
    pub time_minutes: Option<i32>,
}

/// A fully resolved and assembled recipe.
///
/// This is the canonical recipe representation after the entire capture
/// pipeline has completed. It combines structured data from extraction,
/// resolved ingredients, computed nutrition, and cover generation.
///
/// Maps to SPEC §8.4 `ResolvedRecipe`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResolvedRecipe {
    /// Unique identifier for this recipe.
    pub id: RecipeId,
    /// The recipe title.
    pub title: String,
    /// Resolved ingredients with food database matches.
    pub ingredients: Vec<ResolvedIngredient>,
    /// Ordered recipe steps.
    pub steps: Vec<Step>,
    /// Number of servings, if known.
    pub servings: Option<i32>,
    /// Total time in minutes, if known.
    pub time_minutes: Option<i32>,
    /// Attribution to the original source.
    pub source: Source,
    /// Computed nutrition information.
    pub nutrition: NutritionComputation,
    /// Cover image for the recipe.
    pub cover: CoverOutput,
    /// Tags or categories for the recipe.
    pub tags: Vec<String>,
}

/// User-specific view of a recipe, with personal state and edits.
///
/// Each user gets their own overlay on top of the canonical recipe.
/// This includes save/favorite status, personal notes, and patches
/// (edits) the user has made.
///
/// Maps to SPEC §8.4 `UserRecipeView`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserRecipeView {
    /// The recipe this view belongs to.
    pub recipe_id: RecipeId,
    /// The user who owns this view.
    pub user_id: UserId,
    /// Whether the user has saved this recipe.
    pub saved: bool,
    /// Whether the user has favorited this recipe.
    pub favorite: bool,
    /// User's personal notes about the recipe.
    pub notes: Option<String>,
    /// User edits to the canonical recipe.
    pub patches: Vec<RecipePatch>,
}

/// A user's edit to a specific field of a recipe.
///
/// Patches are stored as a list of (field, value) pairs so the
/// original recipe data is never modified. The UI merges patches
/// on top of the canonical recipe for display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipePatch {
    /// The field being patched (e.g., "title", "servings").
    pub field: String,
    /// The new value for the field, as a JSON value.
    pub value: serde_json::Value,
    /// ISO-8601 timestamp of when the patch was created.
    pub created_at: String,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::ids::FoodId;
    use crate::types::ingredient::{IngredientResolution, ParsedIngredient};
    use crate::types::nutrition::{NutritionFacts, NutritionStatus};

    #[test]
    fn platform_serializes_as_snake_case() {
        assert_eq!(
            serde_json::to_value(Platform::Instagram).expect("serialize"),
            "instagram"
        );
        assert_eq!(
            serde_json::to_value(Platform::Tiktok).expect("serialize"),
            "tiktok"
        );
        assert_eq!(
            serde_json::to_value(Platform::Youtube).expect("serialize"),
            "youtube"
        );
        assert_eq!(
            serde_json::to_value(Platform::Website).expect("serialize"),
            "website"
        );
        assert_eq!(
            serde_json::to_value(Platform::Manual).expect("serialize"),
            "manual"
        );
        assert_eq!(
            serde_json::to_value(Platform::Unknown).expect("serialize"),
            "unknown"
        );
    }

    #[test]
    fn platform_roundtrips_all_variants() {
        for platform in &[
            Platform::Instagram,
            Platform::Tiktok,
            Platform::Youtube,
            Platform::Website,
            Platform::Manual,
            Platform::Unknown,
        ] {
            let json = serde_json::to_string(platform).expect("should serialize");
            let deserialized: Platform = serde_json::from_str(&json).expect("should deserialize");
            assert_eq!(&deserialized, platform);
        }
    }

    #[test]
    fn source_roundtrips() {
        let source = Source {
            platform: Platform::Instagram,
            url: Some("https://instagram.com/p/abc123".to_string()),
            creator_handle: Some("@chefmike".to_string()),
            creator_id: Some("12345678".to_string()),
        };
        let json = serde_json::to_string(&source).expect("should serialize");
        let deserialized: Source = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.platform, Platform::Instagram);
        assert_eq!(
            deserialized.url.as_deref(),
            Some("https://instagram.com/p/abc123")
        );
        assert_eq!(deserialized.creator_handle.as_deref(), Some("@chefmike"));
    }

    #[test]
    fn source_with_no_optional_fields_roundtrips() {
        let source = Source {
            platform: Platform::Manual,
            url: None,
            creator_handle: None,
            creator_id: None,
        };
        let json = serde_json::to_string(&source).expect("should serialize");
        let deserialized: Source = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.platform, Platform::Manual);
        assert!(deserialized.url.is_none());
    }

    #[test]
    fn cover_output_source_image_roundtrips() {
        let cover = CoverOutput::SourceImage {
            asset_id: AssetId::new("img_001"),
        };
        let json = serde_json::to_string(&cover).expect("should serialize");
        let deserialized: CoverOutput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CoverOutput::SourceImage { asset_id } => {
                assert_eq!(asset_id.as_str(), "img_001");
            }
            _ => panic!("expected SourceImage variant"),
        }
    }

    #[test]
    fn cover_output_enhanced_image_roundtrips() {
        let cover = CoverOutput::EnhancedImage {
            asset_id: AssetId::new("img_enhanced_001"),
        };
        let json = serde_json::to_string(&cover).expect("should serialize");
        let deserialized: CoverOutput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CoverOutput::EnhancedImage { asset_id } => {
                assert_eq!(asset_id.as_str(), "img_enhanced_001");
            }
            _ => panic!("expected EnhancedImage variant"),
        }
    }

    #[test]
    fn cover_output_generated_cover_roundtrips() {
        let cover = CoverOutput::GeneratedCover {
            asset_id: AssetId::new("img_gen_001"),
        };
        let json = serde_json::to_string(&cover).expect("should serialize");
        let deserialized: CoverOutput = serde_json::from_str(&json).expect("should deserialize");
        match deserialized {
            CoverOutput::GeneratedCover { asset_id } => {
                assert_eq!(asset_id.as_str(), "img_gen_001");
            }
            _ => panic!("expected GeneratedCover variant"),
        }
    }

    #[test]
    fn cover_output_serializes_with_type_tag() {
        let cover = CoverOutput::SourceImage {
            asset_id: AssetId::new("img_001"),
        };
        let json = serde_json::to_value(&cover).expect("should serialize");
        assert_eq!(json["type"], "source_image");
    }

    #[test]
    fn step_roundtrips() {
        let step = Step {
            number: 1,
            instruction: "Preheat oven to 350F".to_string(),
            time_minutes: Some(10),
        };
        let json = serde_json::to_string(&step).expect("should serialize");
        let deserialized: Step = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.number, 1);
        assert_eq!(deserialized.instruction, "Preheat oven to 350F");
        assert_eq!(deserialized.time_minutes, Some(10));
    }

    #[test]
    fn step_without_time_roundtrips() {
        let step = Step {
            number: 2,
            instruction: "Mix dry ingredients".to_string(),
            time_minutes: None,
        };
        let json = serde_json::to_string(&step).expect("should serialize");
        let deserialized: Step = serde_json::from_str(&json).expect("should deserialize");
        assert!(deserialized.time_minutes.is_none());
    }

    #[test]
    fn resolved_recipe_roundtrips() {
        let recipe = ResolvedRecipe {
            id: RecipeId::new("recipe_001"),
            title: "Chocolate Cake".to_string(),
            ingredients: vec![ResolvedIngredient {
                parsed: ParsedIngredient {
                    quantity: Some(2.0),
                    unit: Some("cups".to_string()),
                    name: "flour".to_string(),
                    preparation: None,
                },
                resolution: IngredientResolution::Matched {
                    food_id: FoodId::new("usda_flour"),
                    confidence: 0.95,
                },
            }],
            steps: vec![Step {
                number: 1,
                instruction: "Preheat oven to 350F".to_string(),
                time_minutes: Some(10),
            }],
            servings: Some(8),
            time_minutes: Some(60),
            source: Source {
                platform: Platform::Instagram,
                url: Some("https://instagram.com/p/abc".to_string()),
                creator_handle: Some("@baker".to_string()),
                creator_id: None,
            },
            nutrition: NutritionComputation {
                per_recipe: NutritionFacts {
                    calories: 3200.0,
                    protein: 40.0,
                    carbs: 450.0,
                    fat: 140.0,
                },
                per_serving: Some(NutritionFacts {
                    calories: 400.0,
                    protein: 5.0,
                    carbs: 56.25,
                    fat: 17.5,
                }),
                status: NutritionStatus::Calculated,
            },
            cover: CoverOutput::SourceImage {
                asset_id: AssetId::new("cover_001"),
            },
            tags: vec!["dessert".to_string(), "baking".to_string()],
        };
        let json = serde_json::to_string(&recipe).expect("should serialize");
        let deserialized: ResolvedRecipe = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.id.as_str(), "recipe_001");
        assert_eq!(deserialized.title, "Chocolate Cake");
        assert_eq!(deserialized.ingredients.len(), 1);
        assert_eq!(deserialized.steps.len(), 1);
        assert_eq!(deserialized.servings, Some(8));
        assert_eq!(deserialized.tags.len(), 2);
    }

    #[test]
    fn user_recipe_view_roundtrips() {
        let view = UserRecipeView {
            recipe_id: RecipeId::new("recipe_001"),
            user_id: UserId::new("user_abc"),
            saved: true,
            favorite: false,
            notes: Some("Delicious! Try with less sugar next time.".to_string()),
            patches: vec![RecipePatch {
                field: "servings".to_string(),
                value: serde_json::json!(12),
                created_at: "2026-03-19T12:00:00Z".to_string(),
            }],
        };
        let json = serde_json::to_string(&view).expect("should serialize");
        let deserialized: UserRecipeView = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.recipe_id.as_str(), "recipe_001");
        assert_eq!(deserialized.user_id.as_str(), "user_abc");
        assert!(deserialized.saved);
        assert!(!deserialized.favorite);
        assert_eq!(deserialized.patches.len(), 1);
        assert_eq!(deserialized.patches[0].field, "servings");
    }

    #[test]
    fn user_recipe_view_empty_patches_roundtrips() {
        let view = UserRecipeView {
            recipe_id: RecipeId::new("recipe_002"),
            user_id: UserId::new("user_def"),
            saved: true,
            favorite: true,
            notes: None,
            patches: vec![],
        };
        let json = serde_json::to_string(&view).expect("should serialize");
        let deserialized: UserRecipeView = serde_json::from_str(&json).expect("should deserialize");
        assert!(deserialized.notes.is_none());
        assert!(deserialized.patches.is_empty());
    }

    #[test]
    fn recipe_patch_roundtrips() {
        let patch = RecipePatch {
            field: "title".to_string(),
            value: serde_json::json!("My Custom Title"),
            created_at: "2026-03-19T15:30:00Z".to_string(),
        };
        let json = serde_json::to_string(&patch).expect("should serialize");
        let deserialized: RecipePatch = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.field, "title");
        assert_eq!(deserialized.value, "My Custom Title");
    }
}
