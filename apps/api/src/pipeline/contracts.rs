//! Pipeline stage function contracts from SPEC §9.
//!
//! Each function represents a discrete pipeline stage. All implementations
//! are currently stubs that return `PipelineError::NotImplemented`. The
//! real implementations will be added in later phases.
//!
//! All stages are:
//! - **Idempotent** — calling with the same input produces the same output.
//! - **Immutable** — outputs are never modified after creation.
//! - **Independently re-runnable** — any stage can be re-executed in isolation.

use crate::types::capture::{CaptureInput, ExtractionArtifact, StructuredRecipeCandidate};
use crate::types::ids::AssetId;
use crate::types::ingredient::{IngredientLine, ResolvedIngredient};
use crate::types::nutrition::NutritionComputation;
use crate::types::recipe::{CoverOutput, ResolvedRecipe, Source, Step};

use super::errors::PipelineError;

/// Input for cover generation.
///
/// Contains the images and metadata needed to produce a cover image
/// for a recipe.
#[derive(Debug, Clone)]
pub struct CoverInput {
    /// Available images from the extraction.
    pub images: Vec<AssetId>,
    /// The recipe title (used for generated covers).
    pub title: String,
}

/// Extracts raw data from a capture input.
///
/// Takes the user's raw input (link, image, speech, text) and produces
/// an extraction artifact containing all the raw data that was found.
///
/// **SPEC §9:** `extractRecipe(CaptureInput) -> Result<ExtractionArtifact>`
///
/// # Errors
///
/// Returns `PipelineError::NotImplemented` (stub implementation).
pub async fn extract_recipe(input: &CaptureInput) -> Result<ExtractionArtifact, PipelineError> {
    let _ = input;
    Err(PipelineError::NotImplemented {
        stage: "extract_recipe".to_string(),
    })
}

/// Structures raw extraction data into a recipe candidate.
///
/// Identifies ingredients vs. steps, infers metadata (time, servings),
/// and removes noise from the raw extraction.
///
/// **SPEC §9:** `structureRecipe(ExtractionArtifact) -> Result<StructuredRecipeCandidate>`
///
/// # Errors
///
/// Returns `PipelineError::NotImplemented` (stub implementation).
pub async fn structure_recipe(
    artifact: &ExtractionArtifact,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    let _ = artifact;
    Err(PipelineError::NotImplemented {
        stage: "structure_recipe".to_string(),
    })
}

/// Parses ingredient text lines into structured ingredients.
///
/// Takes the raw ingredient lines from a structured recipe candidate
/// and parses each one into quantity, unit, name, and preparation.
///
/// **SPEC §9:** `parseIngredients(StructuredRecipeCandidate) -> [IngredientLine]`
pub async fn parse_ingredients(candidate: &StructuredRecipeCandidate) -> Vec<IngredientLine> {
    // Stub: return unparsed lines
    candidate
        .ingredient_lines
        .iter()
        .map(|text| IngredientLine {
            raw_text: text.clone(),
            parsed: None,
        })
        .collect()
}

/// Resolves parsed ingredients against a food database.
///
/// For each ingredient line, attempts to match it to a known food
/// entity in the USDA FoodData Central database (or Edamam fallback).
///
/// **SPEC §9:** `resolveIngredients([IngredientLine]) -> [ResolvedIngredient]`
pub async fn resolve_ingredients(lines: &[IngredientLine]) -> Vec<ResolvedIngredient> {
    use crate::types::ingredient::{IngredientResolution, ParsedIngredient};

    // Stub: return unmatched resolutions
    lines
        .iter()
        .map(|line| {
            let parsed = line.parsed.clone().unwrap_or(ParsedIngredient {
                quantity: None,
                unit: None,
                name: line.raw_text.clone(),
                preparation: None,
            });
            ResolvedIngredient {
                parsed,
                resolution: IngredientResolution::Unmatched {
                    text: line.raw_text.clone(),
                },
            }
        })
        .collect()
}

/// Computes nutrition facts from resolved ingredients.
///
/// Looks up nutrition data for each resolved ingredient and aggregates
/// the results into per-recipe and per-serving totals.
///
/// **SPEC §9:** `computeNutrition([ResolvedIngredient]) -> NutritionComputation`
pub async fn compute_nutrition(ingredients: &[ResolvedIngredient]) -> NutritionComputation {
    use crate::types::nutrition::{NutritionFacts, NutritionStatus};

    let _ = ingredients;
    // Stub: return unavailable nutrition
    NutritionComputation {
        per_recipe: NutritionFacts {
            calories: 0.0,
            protein: 0.0,
            carbs: 0.0,
            fat: 0.0,
        },
        per_serving: None,
        status: NutritionStatus::Unavailable,
    }
}

/// Generates a cover image for a recipe.
///
/// Selects, enhances, or generates a cover image based on the
/// available source images and recipe metadata.
///
/// **SPEC §9:** `generateCover(CoverInput) -> CoverOutput`
pub async fn generate_cover(input: &CoverInput) -> CoverOutput {
    let _ = input;
    // Stub: return a generated cover placeholder
    CoverOutput::GeneratedCover {
        asset_id: AssetId::new("placeholder_cover"),
    }
}

/// All inputs needed to assemble a final resolved recipe.
///
/// Groups the outputs of every prior pipeline stage into a single
/// struct so that `assemble_recipe` has a clean signature.
#[derive(Debug, Clone)]
pub struct AssemblyInput {
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

/// Assembles all pipeline outputs into a final resolved recipe.
///
/// Combines the structured recipe candidate, resolved ingredients,
/// nutrition computation, cover, and source into the canonical recipe.
///
/// **SPEC §9:** `assembleRecipe(...) -> ResolvedRecipe`
///
/// # Errors
///
/// Returns `PipelineError::NotImplemented` (stub implementation).
pub async fn assemble_recipe(input: &AssemblyInput) -> Result<ResolvedRecipe, PipelineError> {
    let _ = input;
    Err(PipelineError::NotImplemented {
        stage: "assemble_recipe".to_string(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::capture::CaptureInput;

    #[tokio::test]
    async fn extract_recipe_returns_not_implemented() {
        let input = CaptureInput::Manual {
            text: "test recipe".to_string(),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_err());
        match result.err() {
            Some(PipelineError::NotImplemented { stage }) => {
                assert_eq!(stage, "extract_recipe");
            }
            other => panic!("expected NotImplemented, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn structure_recipe_returns_not_implemented() {
        use crate::types::ids::CaptureId;
        use crate::types::recipe::Platform;

        let artifact = ExtractionArtifact {
            id: CaptureId::new("test"),
            version: 1,
            raw_text: None,
            ocr_text: None,
            transcript: None,
            ingredients: vec![],
            steps: vec![],
            images: vec![],
            source: Source {
                platform: Platform::Manual,
                url: None,
                creator_handle: None,
                creator_id: None,
            },
            confidence: 0.0,
        };
        let result = structure_recipe(&artifact).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn parse_ingredients_returns_unparsed_lines() {
        let candidate = StructuredRecipeCandidate {
            title: Some("Test".to_string()),
            ingredient_lines: vec!["2 cups flour".to_string(), "1 egg".to_string()],
            steps: vec![],
            servings: None,
            time_minutes: None,
            tags: vec![],
            confidence: 0.5,
        };
        let lines = parse_ingredients(&candidate).await;
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].raw_text, "2 cups flour");
        assert!(lines[0].parsed.is_none());
    }

    #[tokio::test]
    async fn resolve_ingredients_returns_unmatched() {
        let lines = vec![IngredientLine {
            raw_text: "butter".to_string(),
            parsed: None,
        }];
        let resolved = resolve_ingredients(&lines).await;
        assert_eq!(resolved.len(), 1);
        match &resolved[0].resolution {
            crate::types::ingredient::IngredientResolution::Unmatched { text } => {
                assert_eq!(text, "butter");
            }
            other => panic!("expected Unmatched, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn compute_nutrition_returns_unavailable() {
        let result = compute_nutrition(&[]).await;
        assert_eq!(
            result.status,
            crate::types::nutrition::NutritionStatus::Unavailable
        );
    }

    #[tokio::test]
    async fn generate_cover_returns_generated() {
        let input = CoverInput {
            images: vec![],
            title: "Test Recipe".to_string(),
        };
        let cover = generate_cover(&input).await;
        match cover {
            CoverOutput::GeneratedCover { asset_id } => {
                assert_eq!(asset_id.as_str(), "placeholder_cover");
            }
            other => panic!("expected GeneratedCover, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn assemble_recipe_returns_not_implemented() {
        use crate::types::nutrition::{NutritionFacts, NutritionStatus};
        use crate::types::recipe::Platform;

        let input = AssemblyInput {
            title: "Test".to_string(),
            ingredients: vec![],
            steps: vec![],
            servings: None,
            time_minutes: None,
            source: Source {
                platform: Platform::Manual,
                url: None,
                creator_handle: None,
                creator_id: None,
            },
            nutrition: NutritionComputation {
                per_recipe: NutritionFacts {
                    calories: 0.0,
                    protein: 0.0,
                    carbs: 0.0,
                    fat: 0.0,
                },
                per_serving: None,
                status: NutritionStatus::Unavailable,
            },
            cover: CoverOutput::GeneratedCover {
                asset_id: AssetId::new("cover"),
            },
            tags: vec![],
        };
        let result = assemble_recipe(&input).await;
        assert!(result.is_err());
    }
}
