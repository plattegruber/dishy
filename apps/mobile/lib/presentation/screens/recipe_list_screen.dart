/// Recipe list screen -- the main home view showing saved recipes.
///
/// Displays a grid of recipe cards with pull-to-refresh. Tapping a card
/// navigates to the recipe detail. A FAB navigates to the capture screen.
///
/// Implements SPEC section 15: "Home: Grid layout".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/recipe.dart';
import '../providers/recipe_list_provider.dart';
import '../widgets/recipe_card.dart';

/// Main screen showing the user's saved recipes in a grid layout.
///
/// Features:
/// - Grid of recipe cards with title and metadata
/// - Pull-to-refresh to reload from the API
/// - FAB to navigate to the capture screen
/// - Empty state when no recipes exist
class RecipeListScreen extends ConsumerWidget {
  /// Creates the recipe list screen.
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ResolvedRecipe>> asyncRecipes =
        ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishy'),
        centerTitle: true,
      ),
      body: asyncRecipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Failed to load recipes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(recipeListProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (List<ResolvedRecipe> recipes) {
          if (recipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.deepOrange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No recipes yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to capture your first recipe',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(recipeListProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: recipes.length,
              itemBuilder: (BuildContext context, int index) {
                final ResolvedRecipe recipe = recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () => context.go('/recipes/${recipe.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/capture'),
        tooltip: 'Capture Recipe',
        child: const Icon(Icons.add),
      ),
    );
  }
}

