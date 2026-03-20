/// Grocery list screen -- consolidated shopping list from selected recipes.
///
/// Allows selecting multiple recipes, merges duplicate ingredients,
/// groups by category (produce, dairy, pantry, etc.), and supports
/// checking off items as they are purchased.
///
/// Implements SPEC section 15: "Grocery: Single consolidated list".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/grocery.dart';
import '../../domain/models/recipe.dart';
import '../../domain/services/grocery_service.dart';
import '../providers/grocery_provider.dart';
import '../providers/recipe_list_provider.dart';

/// Screen displaying the grocery list built from selected recipes.
///
/// Features:
/// - Recipe selector to choose which recipes to shop for
/// - Auto-merged duplicate ingredients
/// - Items grouped by category (produce, dairy, meat, pantry, etc.)
/// - Tap to check off purchased items
/// - Clear completed items
class GroceryListScreen extends ConsumerWidget {
  /// Creates the grocery list screen.
  const GroceryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GroceryState groceryState = ref.watch(groceryProvider);
    final AsyncValue<List<ResolvedRecipe>> asyncRecipes =
        ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        centerTitle: true,
        actions: <Widget>[
          if (groceryState.groceryList != null)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Clear completed',
              onPressed: () =>
                  ref.read(groceryProvider.notifier).clearCompleted(),
            ),
        ],
      ),
      body: asyncRecipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace st) => Center(
          child: Text('Failed to load recipes: $error'),
        ),
        data: (List<ResolvedRecipe> recipes) {
          if (recipes.isEmpty) {
            return const _EmptyState();
          }

          return Column(
            children: <Widget>[
              // Recipe selector
              _RecipeSelector(
                recipes: recipes,
                selectedIds: groceryState.selectedRecipeIds,
                onToggle: (String id) =>
                    ref.read(groceryProvider.notifier).toggleRecipe(id),
                onSelectAll: () =>
                    ref.read(groceryProvider.notifier).selectAll(recipes),
                onDeselectAll: () =>
                    ref.read(groceryProvider.notifier).deselectAll(),
              ),
              const Divider(height: 1),
              // Grocery list
              Expanded(
                child: groceryState.groceryList == null
                    ? const _NoRecipesSelected()
                    : _GroceryListBody(
                        groceryList: groceryState.groceryList!,
                        onToggleItem: (int index) =>
                            ref.read(groceryProvider.notifier).toggleItem(index),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Recipe selector shown at the top of the grocery list.
class _RecipeSelector extends StatelessWidget {
  const _RecipeSelector({
    required this.recipes,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final List<ResolvedRecipe> recipes;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final bool allSelected = selectedIds.length == recipes.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Select Recipes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: allSelected ? onDeselectAll : onSelectAll,
                child: Text(allSelected ? 'Deselect All' : 'Select All'),
              ),
            ],
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final ResolvedRecipe recipe = recipes[index];
                final bool isSelected = selectedIds.contains(recipe.id);

                return FilterChip(
                  label: Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  onSelected: (_) => onToggle(recipe.id),
                  selectedColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Body of the grocery list with items grouped by category.
class _GroceryListBody extends StatelessWidget {
  const _GroceryListBody({
    required this.groceryList,
    required this.onToggleItem,
  });

  final GroceryList groceryList;
  final ValueChanged<int> onToggleItem;

  @override
  Widget build(BuildContext context) {
    if (groceryList.items.isEmpty) {
      return const Center(
        child: Text(
          'No ingredients found in selected recipes.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group items by category for display
    final Map<GroceryCategory, List<_IndexedItem>> grouped =
        <GroceryCategory, List<_IndexedItem>>{};

    for (int i = 0; i < groceryList.items.length; i++) {
      final GroceryItem item = groceryList.items[i];
      grouped.putIfAbsent(item.category, () => <_IndexedItem>[]);
      grouped[item.category]!.add(_IndexedItem(index: i, item: item));
    }

    // Build section list
    final List<GroceryCategory> categories = grouped.keys.toList()
      ..sort(
        (GroceryCategory a, GroceryCategory b) =>
            a.index.compareTo(b.index),
      );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int sectionIndex) {
        final GroceryCategory category = categories[sectionIndex];
        final List<_IndexedItem> items = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                groceryCategoryLabel(category),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...items.map(
              (_IndexedItem indexed) => _GroceryItemTile(
                item: indexed.item,
                onToggle: () => onToggleItem(indexed.index),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single grocery item tile with checkbox.
class _GroceryItemTile extends StatelessWidget {
  const _GroceryItemTile({
    required this.item,
    required this.onToggle,
  });

  final GroceryItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.checked,
        onChanged: (_) => onToggle(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        formatGroceryQuantity(item),
        style: TextStyle(
          fontSize: 16,
          decoration: item.checked ? TextDecoration.lineThrough : null,
          color: item.checked ? Colors.grey : null,
        ),
      ),
      subtitle: item.recipeIds.length > 1
          ? Text(
              '${item.recipeIds.length} recipes',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: onToggle,
      dense: true,
    );
  }
}

/// Helper class to track the original index of items in grouped lists.
class _IndexedItem {
  const _IndexedItem({required this.index, required this.item});

  final int index;
  final GroceryItem item;
}

/// Empty state when no recipes exist at all.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No recipes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Capture some recipes first, then\nbuild your grocery list here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// State shown when recipes exist but none are selected.
class _NoRecipesSelected extends StatelessWidget {
  const _NoRecipesSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.touch_app,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Select recipes above',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap recipe chips to build\nyour grocery list.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
