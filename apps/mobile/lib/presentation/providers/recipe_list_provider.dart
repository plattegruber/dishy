/// Riverpod provider for the recipe list state.
///
/// Manages fetching and refreshing the list of recipes for the
/// authenticated user. Uses [AsyncNotifier] to handle loading,
/// error, and data states.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recipe_repository.dart';
import '../../domain/models/recipe.dart';

/// Notifier that manages the recipe list state.
///
/// Automatically fetches recipes on first access. Provides a
/// [refresh] method for pull-to-refresh.
class RecipeListNotifier extends AsyncNotifier<List<ResolvedRecipe>> {
  @override
  Future<List<ResolvedRecipe>> build() async {
    return _fetchRecipes();
  }

  /// Fetches recipes from the repository.
  Future<List<ResolvedRecipe>> _fetchRecipes() async {
    final RecipeRepository repository = ref.read(recipeRepositoryProvider);
    return repository.getRecipes();
  }

  /// Refreshes the recipe list by re-fetching from the API.
  ///
  /// Sets the state to loading, then fetches the latest recipes.
  Future<void> refresh() async {
    state = const AsyncLoading<List<ResolvedRecipe>>();
    state = await AsyncValue.guard(_fetchRecipes);
  }

  /// Adds a recipe to the local list without re-fetching.
  ///
  /// Called after a successful capture to immediately show the new
  /// recipe in the list.
  void addRecipe(ResolvedRecipe recipe) {
    state.whenData((List<ResolvedRecipe> recipes) {
      state = AsyncData<List<ResolvedRecipe>>(<ResolvedRecipe>[recipe, ...recipes]);
    });
  }
}

/// Provides the recipe list state.
///
/// Usage:
/// ```dart
/// final asyncRecipes = ref.watch(recipeListProvider);
/// ```
final AsyncNotifierProvider<RecipeListNotifier, List<ResolvedRecipe>>
    recipeListProvider =
    AsyncNotifierProvider<RecipeListNotifier, List<ResolvedRecipe>>(
  RecipeListNotifier.new,
);
