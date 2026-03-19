/// Recipe types from SPEC §8.3 and §8.4.
///
/// These types represent the final output of the capture pipeline:
/// - [Source] and [Platform] — attribution to the original content.
/// - [CoverOutput] — the visual representation of the recipe.
/// - [Step] — a single recipe step.
/// - [ResolvedRecipe] — the fully assembled canonical recipe.
/// - [UserRecipeView] — user-specific overlay on a recipe.
/// - [RecipePatch] — a user edit to a recipe field.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'ids.dart';
import 'ingredient.dart';
import 'nutrition.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// The content platform where a recipe was originally found.
///
/// Maps to SPEC §8.3 `Platform`.
enum Platform {
  /// Instagram (posts, reels, stories).
  instagram,

  /// TikTok videos.
  tiktok,

  /// YouTube videos or Shorts.
  youtube,

  /// A standalone website or blog.
  website,

  /// Manually entered — no external platform.
  manual,

  /// Platform could not be determined.
  unknown,
}

/// Attribution information for the original recipe source.
///
/// Maps to SPEC §8.3 `Source`.
@freezed
class Source with _$Source {
  const factory Source({
    /// The platform where the recipe was found.
    required Platform platform,

    /// The original URL, if available.
    String? url,

    /// The content creator's handle (e.g., "@chefname").
    String? creatorHandle,

    /// The content creator's platform-specific ID.
    String? creatorId,
  }) = _Source;

  factory Source.fromJson(Map<String, dynamic> json) => _$SourceFromJson(json);
}

/// The visual cover image for a recipe.
///
/// Maps to SPEC §8.3 `CoverOutput`.
@freezed
sealed class CoverOutput with _$CoverOutput {
  /// An image taken directly from the source content.
  const factory CoverOutput.sourceImage({
    /// Reference to the source image asset in R2.
    required AssetId assetId,
  }) = CoverOutputSourceImage;

  /// A source image that has been enhanced.
  const factory CoverOutput.enhancedImage({
    /// Reference to the enhanced image asset in R2.
    required AssetId assetId,
  }) = CoverOutputEnhancedImage;

  /// A generated cover image (fallback).
  const factory CoverOutput.generatedCover({
    /// Reference to the generated cover asset in R2.
    required AssetId assetId,
  }) = CoverOutputGeneratedCover;

  factory CoverOutput.fromJson(Map<String, dynamic> json) =>
      _$CoverOutputFromJson(json);
}

/// A single step in a recipe's instructions.
@freezed
class Step with _$Step {
  const factory Step({
    /// The 1-based step number.
    required int number,

    /// The instruction text for this step.
    required String instruction,

    /// Duration in minutes for this step, if applicable.
    int? timeMinutes,
  }) = _Step;

  factory Step.fromJson(Map<String, dynamic> json) => _$StepFromJson(json);
}

/// A fully resolved and assembled recipe.
///
/// Maps to SPEC §8.4 `ResolvedRecipe`.
@freezed
class ResolvedRecipe with _$ResolvedRecipe {
  const factory ResolvedRecipe({
    /// Unique identifier for this recipe.
    required RecipeId id,

    /// The recipe title.
    required String title,

    /// Resolved ingredients with food database matches.
    required List<ResolvedIngredient> ingredients,

    /// Ordered recipe steps.
    required List<Step> steps,

    /// Number of servings, if known.
    int? servings,

    /// Total time in minutes, if known.
    int? timeMinutes,

    /// Attribution to the original source.
    required Source source,

    /// Computed nutrition information.
    required NutritionComputation nutrition,

    /// Cover image for the recipe.
    required CoverOutput cover,

    /// Tags or categories for the recipe.
    required List<String> tags,
  }) = _ResolvedRecipe;

  factory ResolvedRecipe.fromJson(Map<String, dynamic> json) =>
      _$ResolvedRecipeFromJson(json);
}

/// User-specific view of a recipe, with personal state and edits.
///
/// Maps to SPEC §8.4 `UserRecipeView`.
@freezed
class UserRecipeView with _$UserRecipeView {
  const factory UserRecipeView({
    /// The recipe this view belongs to.
    required RecipeId recipeId,

    /// The user who owns this view.
    required UserId userId,

    /// Whether the user has saved this recipe.
    required bool saved,

    /// Whether the user has favorited this recipe.
    required bool favorite,

    /// User's personal notes about the recipe.
    String? notes,

    /// User edits to the canonical recipe.
    required List<RecipePatch> patches,
  }) = _UserRecipeView;

  factory UserRecipeView.fromJson(Map<String, dynamic> json) =>
      _$UserRecipeViewFromJson(json);
}

/// A user's edit to a specific field of a recipe.
@freezed
class RecipePatch with _$RecipePatch {
  const factory RecipePatch({
    /// The field being patched (e.g., "title", "servings").
    required String field,

    /// The new value for the field, as a JSON value.
    required Object value,

    /// ISO-8601 timestamp of when the patch was created.
    required String createdAt,
  }) = _RecipePatch;

  factory RecipePatch.fromJson(Map<String, dynamic> json) =>
      _$RecipePatchFromJson(json);
}
