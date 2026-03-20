/// Riverpod provider for the grocery list state.
///
/// Manages building and updating the grocery list from selected recipes.
/// Supports checking off items and clearing completed items.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/grocery.dart';
import '../../domain/models/recipe.dart';
import '../../domain/services/grocery_service.dart';
import 'recipe_list_provider.dart';

/// State for the grocery list screen.
class GroceryState {
  /// Creates the grocery state.
  const GroceryState({
    this.selectedRecipeIds = const <String>{},
    this.groceryList,
  });

  /// IDs of recipes selected for the grocery list.
  final Set<String> selectedRecipeIds;

  /// The computed grocery list, or null if no recipes are selected.
  final GroceryList? groceryList;

  /// Creates a copy with updated fields.
  GroceryState copyWith({
    Set<String>? selectedRecipeIds,
    GroceryList? groceryList,
  }) {
    return GroceryState(
      selectedRecipeIds: selectedRecipeIds ?? this.selectedRecipeIds,
      groceryList: groceryList ?? this.groceryList,
    );
  }
}

/// Notifier managing grocery list state.
///
/// Allows selecting recipes, building the merged list, toggling
/// items, and clearing completed items.
class GroceryNotifier extends StateNotifier<GroceryState> {
  /// Creates the notifier with access to recipe data.
  GroceryNotifier({required this.ref}) : super(const GroceryState());

  /// Reference for reading other providers.
  final Ref ref;

  final GroceryService _service = const GroceryService();

  /// Toggles selection of a recipe for the grocery list.
  void toggleRecipe(String recipeId) {
    final Set<String> updated = Set<String>.from(state.selectedRecipeIds);
    if (updated.contains(recipeId)) {
      updated.remove(recipeId);
    } else {
      updated.add(recipeId);
    }

    state = state.copyWith(selectedRecipeIds: updated);
    _rebuildList();
  }

  /// Selects all available recipes.
  void selectAll(List<ResolvedRecipe> recipes) {
    state = state.copyWith(
      selectedRecipeIds:
          recipes.map((ResolvedRecipe r) => r.id).toSet(),
    );
    _rebuildList();
  }

  /// Deselects all recipes.
  void deselectAll() {
    state = const GroceryState();
  }

  /// Toggles the checked state of a grocery item at [index].
  void toggleItem(int index) {
    final GroceryList? list = state.groceryList;
    if (list == null || index < 0 || index >= list.items.length) return;

    final List<GroceryItem> updatedItems = List<GroceryItem>.from(list.items);
    updatedItems[index] = updatedItems[index].copyWith(
      checked: !updatedItems[index].checked,
    );

    state = state.copyWith(
      groceryList: list.copyWith(items: updatedItems),
    );
  }

  /// Removes all checked items from the list.
  void clearCompleted() {
    final GroceryList? list = state.groceryList;
    if (list == null) return;

    final List<GroceryItem> remaining = list.items
        .where((GroceryItem item) => !item.checked)
        .toList();

    state = state.copyWith(
      groceryList: list.copyWith(items: remaining),
    );
  }

  /// Rebuilds the grocery list from the selected recipes.
  void _rebuildList() {
    if (state.selectedRecipeIds.isEmpty) {
      state = const GroceryState();
      return;
    }

    final AsyncValue<List<ResolvedRecipe>> asyncRecipes =
        ref.read(recipeListProvider);

    asyncRecipes.whenData((List<ResolvedRecipe> allRecipes) {
      final List<ResolvedRecipe> selected = allRecipes
          .where(
            (ResolvedRecipe r) => state.selectedRecipeIds.contains(r.id),
          )
          .toList();

      if (selected.isEmpty) {
        state = state.copyWith(groceryList: null);
        return;
      }

      final GroceryList list = _service.buildGroceryList(selected);
      state = state.copyWith(groceryList: list);
    });
  }
}

/// Provides grocery list state.
final StateNotifierProvider<GroceryNotifier, GroceryState>
    groceryProvider =
    StateNotifierProvider<GroceryNotifier, GroceryState>(
  (Ref ref) => GroceryNotifier(ref: ref),
);
