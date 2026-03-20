/// Riverpod provider for user recipe view state (favorites, saves, notes).
///
/// Manages the user-specific overlay on recipes. Stores state locally
/// and syncs with the backend PATCH endpoint when available.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/recipe.dart';

/// State containing all user recipe views indexed by recipe ID.
///
/// This allows the UI to quickly check if a recipe is favorited or
/// saved without re-fetching from the API.
class UserRecipeViewState {
  /// Creates the state from a map of recipe ID to user view.
  const UserRecipeViewState({
    this.views = const <String, UserRecipeView>{},
  });

  /// User views indexed by recipe ID.
  final Map<String, UserRecipeView> views;

  /// Returns the user view for a recipe, or null if not set.
  UserRecipeView? viewFor(String recipeId) => views[recipeId];

  /// Whether the recipe is favorited.
  bool isFavorite(String recipeId) =>
      views[recipeId]?.favorite ?? false;

  /// Whether the recipe is saved.
  bool isSaved(String recipeId) => views[recipeId]?.saved ?? false;

  /// Returns a copy with the given view updated.
  UserRecipeViewState withView(UserRecipeView view) {
    return UserRecipeViewState(
      views: <String, UserRecipeView>{
        ...views,
        view.recipeId: view,
      },
    );
  }
}

/// Notifier managing user recipe view state.
///
/// Provides methods to toggle favorites, saves, and update notes.
/// State is kept in memory; a future version will sync to the backend.
class UserRecipeViewNotifier extends StateNotifier<UserRecipeViewState> {
  /// Creates the notifier with an empty state.
  UserRecipeViewNotifier() : super(const UserRecipeViewState());

  /// Toggles the favorite status for a recipe.
  void toggleFavorite(String recipeId, {String userId = ''}) {
    final UserRecipeView existing = state.viewFor(recipeId) ??
        UserRecipeView(
          recipeId: recipeId,
          userId: userId,
          saved: true,
          favorite: false,
          patches: const <RecipePatch>[],
        );

    state = state.withView(
      existing.copyWith(favorite: !existing.favorite),
    );
  }

  /// Toggles the saved status for a recipe.
  void toggleSaved(String recipeId, {String userId = ''}) {
    final UserRecipeView existing = state.viewFor(recipeId) ??
        UserRecipeView(
          recipeId: recipeId,
          userId: userId,
          saved: false,
          favorite: false,
          patches: const <RecipePatch>[],
        );

    state = state.withView(
      existing.copyWith(saved: !existing.saved),
    );
  }

  /// Updates the user's notes for a recipe.
  void updateNotes(String recipeId, String notes, {String userId = ''}) {
    final UserRecipeView existing = state.viewFor(recipeId) ??
        UserRecipeView(
          recipeId: recipeId,
          userId: userId,
          saved: true,
          favorite: false,
          patches: const <RecipePatch>[],
        );

    state = state.withView(
      existing.copyWith(notes: notes.isEmpty ? null : notes),
    );
  }
}

/// Provides user recipe view state for the entire app.
final StateNotifierProvider<UserRecipeViewNotifier, UserRecipeViewState>
    userRecipeViewProvider =
    StateNotifierProvider<UserRecipeViewNotifier, UserRecipeViewState>(
  (Ref ref) => UserRecipeViewNotifier(),
);
