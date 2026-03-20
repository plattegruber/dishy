/// Riverpod provider for a single recipe's detail state.
///
/// Uses a family provider parameterized by recipe ID so each recipe
/// detail screen has its own independent state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../domain/models/recipe.dart';

/// Provides the detail state for a single recipe by ID.
///
/// Usage:
/// ```dart
/// final asyncRecipe = ref.watch(recipeDetailProvider(recipeId));
/// ```
final FutureProviderFamily<ResolvedRecipe, String> recipeDetailProvider =
    FutureProvider.family<ResolvedRecipe, String>(
  (Ref ref, String recipeId) async {
    final RecipeRepository repository = ref.read(recipeRepositoryProvider);
    return repository.getRecipe(recipeId);
  },
);
