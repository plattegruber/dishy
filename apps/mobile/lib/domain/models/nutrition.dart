/// Nutrition types from SPEC §8.3.
///
/// Nutrition data is computed from resolved ingredients and attached to
/// recipes. The system tracks both per-recipe and per-serving nutrition
/// facts, along with a status indicating the quality of the computation.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition.freezed.dart';
part 'nutrition.g.dart';

/// Core nutritional facts for a recipe or serving.
///
/// Contains the four primary macronutrient values. All values are in
/// grams except calories (kcal).
/// Maps to SPEC §8.3 `NutritionFacts`.
@freezed
class NutritionFacts with _$NutritionFacts {
  const factory NutritionFacts({
    /// Total calories in kilocalories (kcal).
    required double calories,

    /// Protein content in grams.
    required double protein,

    /// Carbohydrate content in grams.
    required double carbs,

    /// Fat content in grams.
    required double fat,
  }) = _NutritionFacts;

  factory NutritionFacts.fromJson(Map<String, dynamic> json) =>
      _$NutritionFactsFromJson(json);
}

/// The full nutrition computation result for a recipe.
///
/// Maps to SPEC §8.3 `NutritionComputation`.
@freezed
class NutritionComputation with _$NutritionComputation {
  const factory NutritionComputation({
    /// Total nutrition for the entire recipe.
    required NutritionFacts perRecipe,

    /// Nutrition per serving, if the recipe has a defined serving count.
    NutritionFacts? perServing,

    /// Status indicating the reliability of this computation.
    required NutritionStatus status,
  }) = _NutritionComputation;

  factory NutritionComputation.fromJson(Map<String, dynamic> json) =>
      _$NutritionComputationFromJson(json);
}

/// Status of a nutrition computation, indicating data quality.
///
/// Maps to SPEC §10 `NutritionState`.
enum NutritionStatus {
  /// Nutrition computation has not been attempted yet.
  pending,

  /// All ingredients matched exactly — nutrition values are precise.
  calculated,

  /// Some ingredients used fuzzy matches — nutrition values are estimated.
  estimated,

  /// Nutrition could not be computed.
  unavailable,
}
