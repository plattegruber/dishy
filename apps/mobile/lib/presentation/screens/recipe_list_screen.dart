/// Recipe list screen -- the main home view showing saved recipes.
///
/// Displays a grid of recipe cards with search/filter, auto-grouped
/// sections (recent, favorites, tags), and a prominent FAB for capture.
///
/// Implements SPEC section 15: "Home: Grid layout, auto-grouped sections,
/// primary capture entry point."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/recipe.dart';
import '../providers/recipe_list_provider.dart';
import '../providers/user_recipe_view_provider.dart';
import '../widgets/recipe_card.dart';

/// Main screen showing the user's saved recipes in a searchable grid.
///
/// Features:
/// - Search bar for filtering by title
/// - Auto-grouped sections (favorites first, then by tag)
/// - Responsive grid (2 columns on phone, 3+ on tablet)
/// - Pull-to-refresh
/// - Beautiful empty state
/// - FAB to navigate to the capture screen
class RecipeListScreen extends ConsumerStatefulWidget {
  /// Creates the recipe list screen.
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResolvedRecipe> _filterRecipes(List<ResolvedRecipe> recipes) {
    if (_searchQuery.isEmpty) return recipes;
    final String query = _searchQuery.toLowerCase();
    return recipes.where((ResolvedRecipe recipe) {
      return recipe.title.toLowerCase().contains(query) ||
          recipe.tags.any(
            (String tag) => tag.toLowerCase().contains(query),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ResolvedRecipe>> asyncRecipes =
        ref.watch(recipeListProvider);
    final UserRecipeViewState userViews = ref.watch(userRecipeViewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dishy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: asyncRecipes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => _ErrorView(
          error: error,
          onRetry: () => ref.read(recipeListProvider.notifier).refresh(),
        ),
        data: (List<ResolvedRecipe> recipes) {
          if (recipes.isEmpty) {
            return const _EmptyState();
          }

          final List<ResolvedRecipe> filtered = _filterRecipes(recipes);

          return RefreshIndicator(
            onRefresh: () => ref.read(recipeListProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: <Widget>[
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search recipes...',
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.search, size: 20),
                      ),
                      trailing: _searchQuery.isNotEmpty
                          ? <Widget>[
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ]
                          : null,
                      onChanged: (String value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      elevation: const WidgetStatePropertyAll<double>(0),
                      padding: const WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                // Recipe grid
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No matching recipes',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ..._buildRecipeSections(
                    context,
                    filtered,
                    userViews,
                  ),
                // Bottom spacing
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/capture'),
        tooltip: 'Capture Recipe',
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Capture'),
      ),
    );
  }

  /// Builds auto-grouped recipe sections.
  ///
  /// Groups in order: Favorites, then remaining recipes grouped by
  /// first tag, then untagged recipes.
  List<Widget> _buildRecipeSections(
    BuildContext context,
    List<ResolvedRecipe> recipes,
    UserRecipeViewState userViews,
  ) {
    final List<Widget> sections = <Widget>[];

    // Favorites section
    final List<ResolvedRecipe> favorites = recipes
        .where(
          (ResolvedRecipe r) => userViews.isFavorite(r.id),
        )
        .toList();

    if (favorites.isNotEmpty) {
      sections.addAll(
        _buildSection(context, 'Favorites', favorites, userViews),
      );
    }

    // Remaining recipes (not in favorites)
    final Set<String> favoriteIds =
        favorites.map((ResolvedRecipe r) => r.id).toSet();
    final List<ResolvedRecipe> remaining = recipes
        .where((ResolvedRecipe r) => !favoriteIds.contains(r.id))
        .toList();

    // Group by first tag
    final Map<String, List<ResolvedRecipe>> byTag =
        <String, List<ResolvedRecipe>>{};
    final List<ResolvedRecipe> untagged = <ResolvedRecipe>[];

    for (final ResolvedRecipe recipe in remaining) {
      if (recipe.tags.isNotEmpty) {
        final String tag = recipe.tags.first;
        byTag.putIfAbsent(tag, () => <ResolvedRecipe>[]);
        byTag[tag]!.add(recipe);
      } else {
        untagged.add(recipe);
      }
    }

    // If no favorites and no tags, show all in "All Recipes"
    if (favorites.isEmpty && byTag.isEmpty) {
      sections.addAll(
        _buildSection(context, 'All Recipes', recipes, userViews),
      );
      return sections;
    }

    // Tag sections
    final List<String> sortedTags = byTag.keys.toList()..sort();
    for (final String tag in sortedTags) {
      sections.addAll(
        _buildSection(
          context,
          tag[0].toUpperCase() + tag.substring(1),
          byTag[tag]!,
          userViews,
        ),
      );
    }

    // Untagged recipes
    if (untagged.isNotEmpty) {
      sections.addAll(
        _buildSection(context, 'Other', untagged, userViews),
      );
    }

    return sections;
  }

  /// Builds a single section with a header and recipe grid.
  List<Widget> _buildSection(
    BuildContext context,
    String title,
    List<ResolvedRecipe> recipes,
    UserRecipeViewState userViews,
  ) {
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: MediaQuery.of(context).size.width > 600
                ? 220
                : MediaQuery.of(context).size.width / 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final ResolvedRecipe recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                isFavorite: userViews.isFavorite(recipe.id),
                onTap: () => context.go('/recipes/${recipe.id}'),
                onFavoriteToggle: () =>
                    ref.read(userRecipeViewProvider.notifier)
                        .toggleFavorite(recipe.id),
              );
            },
            childCount: recipes.length,
          ),
        ),
      ),
    ];
  }
}

/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beautiful empty state when no recipes exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No recipes yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Capture a recipe from a photo, link,\nor just type it in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => GoRouter.of(context).go('/capture'),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Capture Your First Recipe'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
