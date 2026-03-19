//! Pipeline error types.
//!
//! All pipeline stage functions return `Result<T, PipelineError>` for
//! consistent error handling across the capture → assembly pipeline.

use serde::{Deserialize, Serialize};

/// Errors that can occur during pipeline processing.
///
/// Each variant represents a failure at a specific pipeline stage.
/// The `stage` method returns the stage name for logging and observability.
#[derive(Debug, Clone, Serialize, Deserialize, thiserror::Error)]
pub enum PipelineError {
    /// Extraction failed (OCR, ASR, or LLM extraction error).
    #[error("extraction failed: {message}")]
    ExtractionFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// Structuring failed (could not parse extraction into a recipe candidate).
    #[error("structuring failed: {message}")]
    StructuringFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// Ingredient parsing or resolution failed.
    #[error("ingredient resolution failed: {message}")]
    IngredientResolutionFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// Nutrition computation failed.
    #[error("nutrition computation failed: {message}")]
    NutritionFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// Cover generation failed.
    #[error("cover generation failed: {message}")]
    CoverGenerationFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// Final assembly failed (missing required data).
    #[error("assembly failed: {message}")]
    AssemblyFailed {
        /// Human-readable description of what went wrong.
        message: String,
    },

    /// The pipeline stage is not yet implemented.
    #[error("not implemented: {stage}")]
    NotImplemented {
        /// The name of the unimplemented stage.
        stage: String,
    },
}

impl PipelineError {
    /// Returns the pipeline stage name for this error.
    pub fn stage(&self) -> &'static str {
        match self {
            PipelineError::ExtractionFailed { .. } => "extraction",
            PipelineError::StructuringFailed { .. } => "structuring",
            PipelineError::IngredientResolutionFailed { .. } => "ingredient_resolution",
            PipelineError::NutritionFailed { .. } => "nutrition",
            PipelineError::CoverGenerationFailed { .. } => "cover_generation",
            PipelineError::AssemblyFailed { .. } => "assembly",
            PipelineError::NotImplemented { .. } => "not_implemented",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn pipeline_error_extraction_displays_correctly() {
        let err = PipelineError::ExtractionFailed {
            message: "OCR timed out".to_string(),
        };
        assert_eq!(err.to_string(), "extraction failed: OCR timed out");
        assert_eq!(err.stage(), "extraction");
    }

    #[test]
    fn pipeline_error_not_implemented_displays_correctly() {
        let err = PipelineError::NotImplemented {
            stage: "cover_generation".to_string(),
        };
        assert_eq!(err.to_string(), "not implemented: cover_generation");
        assert_eq!(err.stage(), "not_implemented");
    }

    #[test]
    fn pipeline_error_roundtrips() {
        let err = PipelineError::StructuringFailed {
            message: "no recipe found".to_string(),
        };
        let json = serde_json::to_string(&err).expect("should serialize");
        let deserialized: PipelineError = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(
            deserialized.to_string(),
            "structuring failed: no recipe found"
        );
    }

    #[test]
    fn pipeline_error_stage_returns_correct_values() {
        assert_eq!(
            PipelineError::ExtractionFailed {
                message: String::new()
            }
            .stage(),
            "extraction"
        );
        assert_eq!(
            PipelineError::StructuringFailed {
                message: String::new()
            }
            .stage(),
            "structuring"
        );
        assert_eq!(
            PipelineError::IngredientResolutionFailed {
                message: String::new()
            }
            .stage(),
            "ingredient_resolution"
        );
        assert_eq!(
            PipelineError::NutritionFailed {
                message: String::new()
            }
            .stage(),
            "nutrition"
        );
        assert_eq!(
            PipelineError::CoverGenerationFailed {
                message: String::new()
            }
            .stage(),
            "cover_generation"
        );
        assert_eq!(
            PipelineError::AssemblyFailed {
                message: String::new()
            }
            .stage(),
            "assembly"
        );
    }
}
