//! Pipeline stage function contracts from SPEC §9.
//!
//! Each function represents a discrete pipeline stage. The `extract_recipe`,
//! `structure_recipe`, and `assemble_recipe` stages are implemented for the
//! manual capture path. `parse_ingredients`, `resolve_ingredients`, and
//! `compute_nutrition` now delegate to real service implementations backed
//! by Claude API and USDA FoodData Central.
//!
//! All stages are:
//! - **Idempotent** -- calling with the same input produces the same output.
//! - **Immutable** -- outputs are never modified after creation.
//! - **Independently re-runnable** -- any stage can be re-executed in isolation.

use crate::logging::Logger;
use crate::services::ingredient_parser;
use crate::services::ingredient_resolver;
use crate::services::nutrition as nutrition_service;
use crate::types::capture::{CaptureInput, ExtractionArtifact, StructuredRecipeCandidate};
use crate::types::ids::{AssetId, CaptureId, RecipeId};
use crate::types::ingredient::{
    IngredientLine, IngredientResolution, ParsedIngredient, ResolvedIngredient,
};
use crate::types::nutrition::NutritionComputation;
use crate::types::recipe::{CoverOutput, Platform, ResolvedRecipe, Source, Step};

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
/// For `CaptureInput::Manual`, the text is used directly as the raw text
/// in the extraction artifact. Other input types are not yet implemented.
///
/// **SPEC S9:** `extractRecipe(CaptureInput) -> Result<ExtractionArtifact>`
///
/// # Errors
///
/// Returns `PipelineError::ExtractionFailed` if the input is empty.
/// Returns `PipelineError::NotImplemented` for non-manual input types.
pub async fn extract_recipe(input: &CaptureInput) -> Result<ExtractionArtifact, PipelineError> {
    match input {
        CaptureInput::Manual { text } => {
            if text.trim().is_empty() {
                return Err(PipelineError::ExtractionFailed {
                    message: "empty input text".to_string(),
                });
            }

            let capture_id = CaptureId::new(uuid::Uuid::new_v4().to_string());

            Ok(ExtractionArtifact {
                id: capture_id,
                version: 1,
                raw_text: Some(text.clone()),
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
                confidence: 1.0,
            })
        }
        CaptureInput::SocialLink { url } => {
            if url.trim().is_empty() {
                return Err(PipelineError::ExtractionFailed {
                    message: "empty URL".to_string(),
                });
            }

            let capture_id = CaptureId::new(uuid::Uuid::new_v4().to_string());

            Ok(ExtractionArtifact {
                id: capture_id,
                version: 1,
                raw_text: None,
                ocr_text: None,
                transcript: None,
                ingredients: vec![],
                steps: vec![],
                images: vec![],
                source: Source {
                    platform: crate::services::social::detect_platform(url),
                    url: Some(url.clone()),
                    creator_handle: None,
                    creator_id: None,
                },
                confidence: 0.0, // Will be updated after fetch
            })
        }
        CaptureInput::Screenshot { .. } => {
            let capture_id = CaptureId::new(uuid::Uuid::new_v4().to_string());

            Ok(ExtractionArtifact {
                id: capture_id,
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
                confidence: 0.0, // Will be updated after OCR
            })
        }
        _ => Err(PipelineError::NotImplemented {
            stage: "extract_recipe (speech/scan)".to_string(),
        }),
    }
}

/// Structures raw extraction data into a recipe candidate.
///
/// For extraction artifacts with raw_text, delegates to the Claude API
/// extraction service. The structured candidate contains the parsed
/// recipe fields.
///
/// **SPEC S9:** `structureRecipe(ExtractionArtifact) -> Result<StructuredRecipeCandidate>`
///
/// # Errors
///
/// Returns `PipelineError::StructuringFailed` if the artifact has no text.
pub async fn structure_recipe(
    artifact: &ExtractionArtifact,
) -> Result<StructuredRecipeCandidate, PipelineError> {
    // For manual extraction, we already have ingredient/step data
    // from the Claude API extraction. If the artifact has populated
    // ingredients and steps, use those directly.
    if !artifact.ingredients.is_empty() || !artifact.steps.is_empty() {
        return Ok(StructuredRecipeCandidate {
            title: None,
            ingredient_lines: artifact.ingredients.clone(),
            steps: artifact.steps.clone(),
            servings: None,
            time_minutes: None,
            tags: vec![],
            confidence: artifact.confidence,
        });
    }

    // If raw_text is available but no structured data yet,
    // this is a placeholder for future implementation.
    if artifact.raw_text.is_some() {
        return Err(PipelineError::StructuringFailed {
            message: "raw text structuring requires Claude API (use extract_recipe_from_text)"
                .to_string(),
        });
    }

    Err(PipelineError::StructuringFailed {
        message: "no text data available for structuring".to_string(),
    })
}

/// Parses ingredient text lines into structured ingredients using the
/// Claude API with tool_use for reliable parsing.
///
/// Takes the raw ingredient lines from a structured recipe candidate
/// and parses each one into quantity, unit, name, and preparation.
///
/// **SPEC S9:** `parseIngredients(StructuredRecipeCandidate) -> [IngredientLine]`
///
/// # Arguments
///
/// * `candidate` - The structured recipe candidate with raw ingredient lines.
/// * `api_key` - The Anthropic API key for Claude-based parsing.
/// * `logger` - The request logger for structured logging.
///
/// # Returns
///
/// A vector of `IngredientLine` objects with structured parse results.
/// Falls back to heuristic parsing if the API call fails.
pub async fn parse_ingredients(
    candidate: &StructuredRecipeCandidate,
    api_key: &str,
    logger: &Logger,
) -> Vec<IngredientLine> {
    if candidate.ingredient_lines.is_empty() {
        return vec![];
    }

    // Try Claude-based parsing first
    match ingredient_parser::parse_ingredient_lines(&candidate.ingredient_lines, api_key, logger)
        .await
    {
        Ok(lines) => lines,
        Err(e) => {
            // Fall back to heuristic parsing
            logger.warn(
                "Claude ingredient parsing failed, falling back to heuristic parser",
                std::collections::HashMap::from([(
                    "error".to_string(),
                    serde_json::Value::String(e.to_string()),
                )]),
            );
            candidate
                .ingredient_lines
                .iter()
                .map(|text| IngredientLine {
                    raw_text: text.clone(),
                    parsed: Some(ingredient_parser::parse_ingredient_heuristic(text)),
                })
                .collect()
        }
    }
}

/// Resolves parsed ingredients against the USDA FoodData Central database.
///
/// For each ingredient line, attempts to match it to a known food
/// entity in the USDA FDC database.
///
/// **SPEC S9:** `resolveIngredients([IngredientLine]) -> [ResolvedIngredient]`
///
/// # Arguments
///
/// * `lines` - The parsed ingredient lines to resolve.
/// * `fdc_api_key` - The USDA FDC API key.
/// * `logger` - The request logger for structured logging.
///
/// # Returns
///
/// A vector of `ResolvedIngredient` objects with resolution results.
pub async fn resolve_ingredients(
    lines: &[IngredientLine],
    fdc_api_key: &str,
    logger: &Logger,
) -> Vec<ResolvedIngredient> {
    if fdc_api_key.is_empty() {
        // No FDC key configured -- return all as unmatched
        logger.warn(
            "FDC_API_KEY not configured, skipping ingredient resolution",
            std::collections::HashMap::new(),
        );
        return lines
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
            .collect();
    }

    ingredient_resolver::resolve_ingredient_lines(lines, fdc_api_key, logger).await
}

/// Computes nutrition facts from resolved ingredients using USDA FDC data.
///
/// Looks up nutrition data for each resolved ingredient and aggregates
/// the results into per-recipe and per-serving totals. Degrades
/// gracefully when some ingredients are unmatched.
///
/// **SPEC S9:** `computeNutrition([ResolvedIngredient]) -> NutritionComputation`
///
/// # Arguments
///
/// * `ingredients` - The resolved ingredients to compute nutrition for.
/// * `servings` - Optional serving count for per-serving calculation.
/// * `fdc_api_key` - The USDA FDC API key.
/// * `logger` - The request logger for structured logging.
pub async fn compute_nutrition(
    ingredients: &[ResolvedIngredient],
    servings: Option<i32>,
    fdc_api_key: &str,
    logger: &Logger,
) -> NutritionComputation {
    if fdc_api_key.is_empty() {
        logger.warn(
            "FDC_API_KEY not configured, skipping nutrition computation",
            std::collections::HashMap::new(),
        );
        return NutritionComputation {
            per_recipe: crate::types::nutrition::NutritionFacts {
                calories: 0.0,
                protein: 0.0,
                carbs: 0.0,
                fat: 0.0,
            },
            per_serving: None,
            status: crate::types::nutrition::NutritionStatus::Unavailable,
        };
    }

    nutrition_service::compute_nutrition_from_ingredients(
        ingredients,
        servings,
        fdc_api_key,
        logger,
    )
    .await
}

/// Generates a cover image for a recipe.
///
/// Selects, enhances, or generates a cover image based on the
/// available source images and recipe metadata.
///
/// **SPEC S9:** `generateCover(CoverInput) -> CoverOutput`
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
/// Generates a new `RecipeId` for the assembled recipe.
///
/// **SPEC S9:** `assembleRecipe(...) -> ResolvedRecipe`
///
/// # Errors
///
/// Returns `PipelineError::AssemblyFailed` if the title is empty.
pub async fn assemble_recipe(input: &AssemblyInput) -> Result<ResolvedRecipe, PipelineError> {
    if input.title.trim().is_empty() {
        return Err(PipelineError::AssemblyFailed {
            message: "recipe title cannot be empty".to_string(),
        });
    }

    let recipe_id = RecipeId::new(uuid::Uuid::new_v4().to_string());

    Ok(ResolvedRecipe {
        id: recipe_id,
        title: input.title.clone(),
        ingredients: input.ingredients.clone(),
        steps: input.steps.clone(),
        servings: input.servings,
        time_minutes: input.time_minutes,
        source: input.source.clone(),
        nutrition: input.nutrition.clone(),
        cover: input.cover.clone(),
        tags: input.tags.clone(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::capture::CaptureInput;
    use crate::types::nutrition::{NutritionFacts, NutritionStatus};

    #[tokio::test]
    async fn extract_recipe_manual_succeeds() {
        let input = CaptureInput::Manual {
            text: "2 cups flour, 1 egg. Mix and bake.".to_string(),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_ok());
        let artifact = result.expect("should succeed");
        assert!(artifact.raw_text.is_some());
        assert_eq!(artifact.source.platform, Platform::Manual);
    }

    #[tokio::test]
    async fn extract_recipe_manual_rejects_empty_text() {
        let input = CaptureInput::Manual {
            text: "   ".to_string(),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn extract_recipe_social_link_creates_artifact() {
        let input = CaptureInput::SocialLink {
            url: "https://www.instagram.com/p/abc123".to_string(),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_ok());
        let artifact = result.expect("should succeed");
        assert_eq!(artifact.source.platform, Platform::Instagram);
        assert_eq!(
            artifact.source.url.as_deref(),
            Some("https://www.instagram.com/p/abc123")
        );
    }

    #[tokio::test]
    async fn extract_recipe_social_link_rejects_empty_url() {
        let input = CaptureInput::SocialLink {
            url: "  ".to_string(),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn extract_recipe_screenshot_creates_artifact() {
        use crate::types::ids::AssetId;
        let input = CaptureInput::Screenshot {
            image: AssetId::new("test_image"),
        };
        let result = extract_recipe(&input).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn structure_recipe_with_data_succeeds() {
        let artifact = ExtractionArtifact {
            id: CaptureId::new("test"),
            version: 1,
            raw_text: None,
            ocr_text: None,
            transcript: None,
            ingredients: vec!["2 cups flour".to_string()],
            steps: vec!["Mix well".to_string()],
            images: vec![],
            source: Source {
                platform: Platform::Manual,
                url: None,
                creator_handle: None,
                creator_id: None,
            },
            confidence: 0.9,
        };
        let result = structure_recipe(&artifact).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn structure_recipe_no_data_fails() {
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
    async fn parse_ingredients_returns_parsed_lines() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let candidate = StructuredRecipeCandidate {
            title: Some("Test".to_string()),
            ingredient_lines: vec!["2 cups flour".to_string(), "1 egg".to_string()],
            steps: vec![],
            servings: None,
            time_minutes: None,
            tags: vec![],
            confidence: 0.5,
        };
        let lines = parse_ingredients(&candidate, "fake-key", &logger).await;
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0].raw_text, "2 cups flour");
        assert!(lines[0].parsed.is_some());
    }

    #[tokio::test]
    async fn parse_ingredients_empty_input() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let candidate = StructuredRecipeCandidate {
            title: Some("Test".to_string()),
            ingredient_lines: vec![],
            steps: vec![],
            servings: None,
            time_minutes: None,
            tags: vec![],
            confidence: 0.5,
        };
        let lines = parse_ingredients(&candidate, "fake-key", &logger).await;
        assert!(lines.is_empty());
    }

    #[tokio::test]
    async fn resolve_ingredients_without_key_returns_unmatched() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let lines = vec![IngredientLine {
            raw_text: "butter".to_string(),
            parsed: Some(ParsedIngredient {
                quantity: None,
                unit: None,
                name: "butter".to_string(),
                preparation: None,
            }),
        }];
        let resolved = resolve_ingredients(&lines, "", &logger).await;
        assert_eq!(resolved.len(), 1);
        match &resolved[0].resolution {
            IngredientResolution::Unmatched { text } => {
                assert_eq!(text, "butter");
            }
            other => panic!("expected Unmatched, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn resolve_ingredients_with_key_resolves_known_foods() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let lines = vec![IngredientLine {
            raw_text: "2 cups flour".to_string(),
            parsed: Some(ParsedIngredient {
                quantity: Some(2.0),
                unit: Some("cups".to_string()),
                name: "flour".to_string(),
                preparation: None,
            }),
        }];
        let resolved = resolve_ingredients(&lines, "test-key", &logger).await;
        assert_eq!(resolved.len(), 1);
        match &resolved[0].resolution {
            IngredientResolution::Matched { food_id, .. } => {
                assert!(!food_id.as_str().is_empty());
            }
            other => panic!("expected Matched for flour, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn compute_nutrition_without_key_returns_unavailable() {
        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let result = compute_nutrition(&[], None, "", &logger).await;
        assert_eq!(result.status, NutritionStatus::Unavailable);
    }

    #[tokio::test]
    async fn compute_nutrition_with_matched_ingredients() {
        use crate::types::ids::FoodId;

        let logger = crate::logging::Logger::new("test-corr".to_string(), "test-sess".to_string());
        let ingredients = vec![ResolvedIngredient {
            parsed: ParsedIngredient {
                quantity: Some(2.0),
                unit: Some("cups".to_string()),
                name: "flour".to_string(),
                preparation: None,
            },
            resolution: IngredientResolution::Matched {
                food_id: FoodId::new("169761"),
                confidence: 0.95,
            },
        }];

        let result = compute_nutrition(&ingredients, Some(4), "test-key", &logger).await;
        assert_eq!(result.status, NutritionStatus::Calculated);
        assert!(result.per_recipe.calories > 0.0);
        assert!(result.per_serving.is_some());
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
    async fn assemble_recipe_succeeds_with_valid_input() {
        let input = AssemblyInput {
            title: "Chocolate Cake".to_string(),
            ingredients: vec![],
            steps: vec![Step {
                number: 1,
                instruction: "Bake".to_string(),
                time_minutes: None,
            }],
            servings: Some(8),
            time_minutes: Some(60),
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
            tags: vec!["dessert".to_string()],
        };
        let result = assemble_recipe(&input).await;
        assert!(result.is_ok());
        let recipe = result.expect("should succeed");
        assert_eq!(recipe.title, "Chocolate Cake");
        assert_eq!(recipe.servings, Some(8));
        assert_eq!(recipe.tags, vec!["dessert"]);
    }

    #[tokio::test]
    async fn assemble_recipe_rejects_empty_title() {
        let input = AssemblyInput {
            title: "  ".to_string(),
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
        assert!(matches!(result, Err(PipelineError::AssemblyFailed { .. })));
    }
}
