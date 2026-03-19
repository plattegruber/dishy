/// Pipeline state machines from SPEC §10.
///
/// These enums model the lifecycle of captures and nutrition computations.
library;

/// State of a capture as it moves through the processing pipeline.
///
/// Maps to SPEC §10 `Capture Pipeline`.
enum CapturePipelineState {
  /// The capture input has been received but not yet processed.
  received,

  /// The capture is currently being processed.
  processing,

  /// Extraction is complete, raw data has been extracted.
  extracted,

  /// The extraction needs human review before proceeding.
  needsReview,

  /// The recipe has been fully resolved and assembled.
  resolved,

  /// Processing failed at some point in the pipeline.
  failed,
}

/// State of the nutrition computation for a recipe.
///
/// Maps to SPEC §10 `Nutrition`.
enum NutritionState {
  /// Nutrition computation has not been attempted.
  pending,

  /// All ingredients matched — nutrition is precise.
  calculated,

  /// Some ingredients were estimated — nutrition is approximate.
  estimated,

  /// Nutrition could not be computed.
  unavailable,
}

/// Extension methods for [CapturePipelineState] transitions.
extension CapturePipelineStateTransitions on CapturePipelineState {
  /// Whether this is a terminal state (no further transitions).
  bool get isTerminal =>
      this == CapturePipelineState.resolved ||
      this == CapturePipelineState.failed;

  /// Valid next states from the current state.
  Set<CapturePipelineState> get validTransitions {
    switch (this) {
      case CapturePipelineState.received:
        return {CapturePipelineState.processing};
      case CapturePipelineState.processing:
        return {
          CapturePipelineState.extracted,
          CapturePipelineState.failed,
        };
      case CapturePipelineState.extracted:
        return {
          CapturePipelineState.needsReview,
          CapturePipelineState.resolved,
          CapturePipelineState.failed,
        };
      case CapturePipelineState.needsReview:
        return {
          CapturePipelineState.resolved,
          CapturePipelineState.failed,
        };
      case CapturePipelineState.resolved:
      case CapturePipelineState.failed:
        return {};
    }
  }

  /// Returns true if transitioning to [target] is valid.
  bool canTransitionTo(CapturePipelineState target) =>
      validTransitions.contains(target);
}

/// Extension methods for [NutritionState] transitions.
extension NutritionStateTransitions on NutritionState {
  /// Whether this is a terminal state (no further transitions).
  bool get isTerminal => this != NutritionState.pending;

  /// Valid next states from the current state.
  Set<NutritionState> get validTransitions {
    switch (this) {
      case NutritionState.pending:
        return {
          NutritionState.calculated,
          NutritionState.estimated,
          NutritionState.unavailable,
        };
      case NutritionState.calculated:
      case NutritionState.estimated:
      case NutritionState.unavailable:
        return {};
    }
  }

  /// Returns true if transitioning to [target] is valid.
  bool canTransitionTo(NutritionState target) =>
      validTransitions.contains(target);
}
