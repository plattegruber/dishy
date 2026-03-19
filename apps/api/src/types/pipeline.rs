//! Pipeline state machines from SPEC §10.
//!
//! These state machines model the lifecycle of captures and nutrition
//! computations. Each state machine enforces valid transitions at the
//! type level — invalid transitions return an error rather than silently
//! succeeding.

use serde::{Deserialize, Serialize};

/// State of a capture as it moves through the processing pipeline.
///
/// Valid transitions (from SPEC §10):
/// ```text
/// Received → Processing → Extracted → NeedsReview → Resolved
///                                                 ↘ Failed
///            Processing → Failed
///            Extracted  → Failed
/// ```
///
/// Maps to SPEC §10 `Capture Pipeline`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum CapturePipelineState {
    /// The capture input has been received but not yet processed.
    Received,
    /// The capture is currently being processed (extraction in progress).
    Processing,
    /// Extraction is complete, raw data has been extracted.
    Extracted,
    /// The extraction needs human review before proceeding.
    NeedsReview,
    /// The recipe has been fully resolved and assembled.
    Resolved,
    /// Processing failed at some point in the pipeline.
    Failed,
}

/// Error returned when an invalid state transition is attempted.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvalidTransition {
    /// The current state.
    pub from: String,
    /// The attempted target state.
    pub to: String,
}

impl std::fmt::Display for InvalidTransition {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "invalid pipeline transition: {} → {}",
            self.from, self.to
        )
    }
}

impl std::error::Error for InvalidTransition {}

impl CapturePipelineState {
    /// Attempts to transition to the `Processing` state.
    ///
    /// Only valid from `Received`.
    pub fn start_processing(&self) -> Result<Self, InvalidTransition> {
        match self {
            CapturePipelineState::Received => Ok(CapturePipelineState::Processing),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Processing".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `Extracted` state.
    ///
    /// Only valid from `Processing`.
    pub fn mark_extracted(&self) -> Result<Self, InvalidTransition> {
        match self {
            CapturePipelineState::Processing => Ok(CapturePipelineState::Extracted),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Extracted".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `NeedsReview` state.
    ///
    /// Only valid from `Extracted`.
    pub fn request_review(&self) -> Result<Self, InvalidTransition> {
        match self {
            CapturePipelineState::Extracted => Ok(CapturePipelineState::NeedsReview),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "NeedsReview".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `Resolved` state.
    ///
    /// Valid from `Extracted` (auto-resolved) or `NeedsReview` (after review).
    pub fn resolve(&self) -> Result<Self, InvalidTransition> {
        match self {
            CapturePipelineState::Extracted | CapturePipelineState::NeedsReview => {
                Ok(CapturePipelineState::Resolved)
            }
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Resolved".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `Failed` state.
    ///
    /// Valid from `Processing`, `Extracted`, or `NeedsReview`.
    pub fn fail(&self) -> Result<Self, InvalidTransition> {
        match self {
            CapturePipelineState::Processing
            | CapturePipelineState::Extracted
            | CapturePipelineState::NeedsReview => Ok(CapturePipelineState::Failed),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Failed".to_string(),
            }),
        }
    }

    /// Returns true if this is a terminal state (no further transitions).
    pub fn is_terminal(&self) -> bool {
        matches!(
            self,
            CapturePipelineState::Resolved | CapturePipelineState::Failed
        )
    }
}

/// State of the nutrition computation for a recipe.
///
/// Valid transitions (from SPEC §10):
/// ```text
/// Pending → Calculated
/// Pending → Estimated
/// Pending → Unavailable
/// ```
///
/// Maps to SPEC §10 `Nutrition`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NutritionState {
    /// Nutrition computation has not been attempted.
    Pending,
    /// All ingredients matched — nutrition is precise.
    Calculated,
    /// Some ingredients were estimated — nutrition is approximate.
    Estimated,
    /// Nutrition could not be computed.
    Unavailable,
}

impl NutritionState {
    /// Attempts to transition to the `Calculated` state.
    ///
    /// Only valid from `Pending`.
    pub fn mark_calculated(&self) -> Result<Self, InvalidTransition> {
        match self {
            NutritionState::Pending => Ok(NutritionState::Calculated),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Calculated".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `Estimated` state.
    ///
    /// Only valid from `Pending`.
    pub fn mark_estimated(&self) -> Result<Self, InvalidTransition> {
        match self {
            NutritionState::Pending => Ok(NutritionState::Estimated),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Estimated".to_string(),
            }),
        }
    }

    /// Attempts to transition to the `Unavailable` state.
    ///
    /// Only valid from `Pending`.
    pub fn mark_unavailable(&self) -> Result<Self, InvalidTransition> {
        match self {
            NutritionState::Pending => Ok(NutritionState::Unavailable),
            other => Err(InvalidTransition {
                from: format!("{other:?}"),
                to: "Unavailable".to_string(),
            }),
        }
    }

    /// Returns true if this is a terminal state (no further transitions).
    pub fn is_terminal(&self) -> bool {
        matches!(
            self,
            NutritionState::Calculated | NutritionState::Estimated | NutritionState::Unavailable
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── CapturePipelineState tests ──

    #[test]
    fn capture_happy_path_received_to_resolved() {
        let state = CapturePipelineState::Received;
        let state = state.start_processing().expect("Received → Processing");
        let state = state.mark_extracted().expect("Processing → Extracted");
        let state = state.resolve().expect("Extracted → Resolved");
        assert_eq!(state, CapturePipelineState::Resolved);
    }

    #[test]
    fn capture_happy_path_with_review() {
        let state = CapturePipelineState::Received;
        let state = state.start_processing().expect("Received → Processing");
        let state = state.mark_extracted().expect("Processing → Extracted");
        let state = state.request_review().expect("Extracted → NeedsReview");
        let state = state.resolve().expect("NeedsReview → Resolved");
        assert_eq!(state, CapturePipelineState::Resolved);
    }

    #[test]
    fn capture_processing_can_fail() {
        let state = CapturePipelineState::Processing;
        let state = state.fail().expect("Processing → Failed");
        assert_eq!(state, CapturePipelineState::Failed);
    }

    #[test]
    fn capture_extracted_can_fail() {
        let state = CapturePipelineState::Extracted;
        let state = state.fail().expect("Extracted → Failed");
        assert_eq!(state, CapturePipelineState::Failed);
    }

    #[test]
    fn capture_needs_review_can_fail() {
        let state = CapturePipelineState::NeedsReview;
        let state = state.fail().expect("NeedsReview → Failed");
        assert_eq!(state, CapturePipelineState::Failed);
    }

    #[test]
    fn capture_received_cannot_extract() {
        let state = CapturePipelineState::Received;
        assert!(state.mark_extracted().is_err());
    }

    #[test]
    fn capture_received_cannot_resolve() {
        let state = CapturePipelineState::Received;
        assert!(state.resolve().is_err());
    }

    #[test]
    fn capture_received_cannot_fail() {
        let state = CapturePipelineState::Received;
        assert!(state.fail().is_err());
    }

    #[test]
    fn capture_resolved_is_terminal() {
        let state = CapturePipelineState::Resolved;
        assert!(state.is_terminal());
        assert!(state.start_processing().is_err());
        assert!(state.mark_extracted().is_err());
        assert!(state.request_review().is_err());
        assert!(state.resolve().is_err());
        assert!(state.fail().is_err());
    }

    #[test]
    fn capture_failed_is_terminal() {
        let state = CapturePipelineState::Failed;
        assert!(state.is_terminal());
        assert!(state.start_processing().is_err());
        assert!(state.mark_extracted().is_err());
        assert!(state.resolve().is_err());
    }

    #[test]
    fn capture_processing_cannot_resolve() {
        let state = CapturePipelineState::Processing;
        assert!(state.resolve().is_err());
    }

    #[test]
    fn capture_pipeline_state_roundtrips_all_variants() {
        for state in &[
            CapturePipelineState::Received,
            CapturePipelineState::Processing,
            CapturePipelineState::Extracted,
            CapturePipelineState::NeedsReview,
            CapturePipelineState::Resolved,
            CapturePipelineState::Failed,
        ] {
            let json = serde_json::to_string(state).expect("should serialize");
            let deserialized: CapturePipelineState =
                serde_json::from_str(&json).expect("should deserialize");
            assert_eq!(&deserialized, state);
        }
    }

    #[test]
    fn capture_pipeline_state_serializes_as_snake_case() {
        assert_eq!(
            serde_json::to_value(CapturePipelineState::NeedsReview).expect("serialize"),
            "needs_review"
        );
    }

    // ── NutritionState tests ──

    #[test]
    fn nutrition_pending_to_calculated() {
        let state = NutritionState::Pending;
        let state = state.mark_calculated().expect("Pending → Calculated");
        assert_eq!(state, NutritionState::Calculated);
    }

    #[test]
    fn nutrition_pending_to_estimated() {
        let state = NutritionState::Pending;
        let state = state.mark_estimated().expect("Pending → Estimated");
        assert_eq!(state, NutritionState::Estimated);
    }

    #[test]
    fn nutrition_pending_to_unavailable() {
        let state = NutritionState::Pending;
        let state = state.mark_unavailable().expect("Pending → Unavailable");
        assert_eq!(state, NutritionState::Unavailable);
    }

    #[test]
    fn nutrition_calculated_is_terminal() {
        let state = NutritionState::Calculated;
        assert!(state.is_terminal());
        assert!(state.mark_calculated().is_err());
        assert!(state.mark_estimated().is_err());
        assert!(state.mark_unavailable().is_err());
    }

    #[test]
    fn nutrition_estimated_is_terminal() {
        let state = NutritionState::Estimated;
        assert!(state.is_terminal());
        assert!(state.mark_calculated().is_err());
    }

    #[test]
    fn nutrition_unavailable_is_terminal() {
        let state = NutritionState::Unavailable;
        assert!(state.is_terminal());
        assert!(state.mark_calculated().is_err());
    }

    #[test]
    fn nutrition_pending_is_not_terminal() {
        assert!(!NutritionState::Pending.is_terminal());
    }

    #[test]
    fn nutrition_state_roundtrips_all_variants() {
        for state in &[
            NutritionState::Pending,
            NutritionState::Calculated,
            NutritionState::Estimated,
            NutritionState::Unavailable,
        ] {
            let json = serde_json::to_string(state).expect("should serialize");
            let deserialized: NutritionState =
                serde_json::from_str(&json).expect("should deserialize");
            assert_eq!(&deserialized, state);
        }
    }

    #[test]
    fn invalid_transition_displays_correctly() {
        let err = InvalidTransition {
            from: "Resolved".to_string(),
            to: "Processing".to_string(),
        };
        assert_eq!(
            err.to_string(),
            "invalid pipeline transition: Resolved → Processing"
        );
    }
}
