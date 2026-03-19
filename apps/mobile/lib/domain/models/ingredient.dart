/// Ingredient types from SPEC §8.2.
///
/// The ingredient pipeline takes raw text lines from a recipe and transforms
/// them through three stages:
/// 1. [IngredientLine] — raw text with an optional parse result.
/// 2. [ParsedIngredient] — structured fields (quantity, unit, name, preparation).
/// 3. [ResolvedIngredient] — a parsed ingredient matched against a food database.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ids.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

/// A single ingredient line from a recipe, with its parse result.
///
/// Maps to SPEC §8.2 `IngredientLine`.
@freezed
class IngredientLine with _$IngredientLine {
  const factory IngredientLine({
    /// The original ingredient text as it appeared in the recipe.
    required String rawText,

    /// The structured parse result, if parsing succeeded.
    ParsedIngredient? parsed,
  }) = _IngredientLine;

  factory IngredientLine.fromJson(Map<String, dynamic> json) =>
      _$IngredientLineFromJson(json);
}

/// A structured ingredient parsed from free-form text.
///
/// Maps to SPEC §8.2 `ParsedIngredient`.
@freezed
class ParsedIngredient with _$ParsedIngredient {
  const factory ParsedIngredient({
    /// Numeric quantity (e.g., 2.0, 0.5).
    double? quantity,

    /// Unit of measurement (e.g., "cup", "tbsp", "g").
    String? unit,

    /// The ingredient name (e.g., "all-purpose flour", "salt").
    required String name,

    /// Preparation instructions (e.g., "diced", "sifted").
    String? preparation,
  }) = _ParsedIngredient;

  factory ParsedIngredient.fromJson(Map<String, dynamic> json) =>
      _$ParsedIngredientFromJson(json);
}

/// An ingredient that has been parsed and resolved against a food database.
///
/// Maps to SPEC §8.2 `ResolvedIngredient`.
@freezed
class ResolvedIngredient with _$ResolvedIngredient {
  const factory ResolvedIngredient({
    /// The parsed ingredient data.
    required ParsedIngredient parsed,

    /// The resolution result from the food database lookup.
    required IngredientResolution resolution,
  }) = _ResolvedIngredient;

  factory ResolvedIngredient.fromJson(Map<String, dynamic> json) =>
      _$ResolvedIngredientFromJson(json);
}

/// The result of trying to match a parsed ingredient to a known food entity.
///
/// Maps to SPEC §8.2 `IngredientResolution`.
@freezed
sealed class IngredientResolution with _$IngredientResolution {
  /// Exact match found in the food database.
  const factory IngredientResolution.matched({
    /// The ID of the matched food entity.
    required FoodId foodId,

    /// Confidence score for the match (0.0 to 1.0).
    required double confidence,
  }) = IngredientResolutionMatched;

  /// Approximate match found — multiple candidates.
  const factory IngredientResolution.fuzzyMatched({
    /// Candidate food entity IDs with their confidence scores.
    required List<FuzzyCandidate> candidates,

    /// Overall confidence in the best match (0.0 to 1.0).
    required double confidence,
  }) = IngredientResolutionFuzzyMatched;

  /// No match found in the food database.
  const factory IngredientResolution.unmatched({
    /// The original text that could not be matched.
    required String text,
  }) = IngredientResolutionUnmatched;

  factory IngredientResolution.fromJson(Map<String, dynamic> json) =>
      _$IngredientResolutionFromJson(json);
}

/// A single candidate from a fuzzy ingredient match.
@freezed
class FuzzyCandidate with _$FuzzyCandidate {
  const factory FuzzyCandidate({
    /// The ID of the candidate food entity.
    required FoodId foodId,

    /// Confidence score for this candidate (0.0 to 1.0).
    required double confidence,
  }) = _FuzzyCandidate;

  factory FuzzyCandidate.fromJson(Map<String, dynamic> json) =>
      _$FuzzyCandidateFromJson(json);
}
