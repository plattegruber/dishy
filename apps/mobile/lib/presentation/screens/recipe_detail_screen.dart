/// Recipe detail screen -- displays a single recipe's full information.
///
/// Shows the recipe title, parsed ingredients with resolution status,
/// step-by-step instructions, source attribution, and nutrition facts card.
/// Clean, readable layout per SPEC section 15: "Recipe View".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/recipe.dart' as recipe_model;
import '../../domain/models/recipe.dart' hide Step;
import '../providers/recipe_detail_provider.dart';
import '../widgets/ingredient_list.dart';
import '../widgets/nutrition_card.dart';

/// Screen displaying the full details of a single recipe.
///
/// Takes a [recipeId] parameter and fetches the recipe from the API.
/// Displays title, ingredients, steps, source, and nutrition info.
class RecipeDetailScreen extends ConsumerWidget {
  /// Creates the recipe detail screen for the given [recipeId].
  const RecipeDetailScreen({
    required this.recipeId,
    super.key,
  });

  /// The ID of the recipe to display.
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ResolvedRecipe> asyncRecipe =
        ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: asyncRecipe.when(
          loading: () => const Text('Loading...'),
          error: (Object error, StackTrace st) => const Text('Error'),
          data: (ResolvedRecipe recipe) => Text(recipe.title),
        ),
      ),
      body: asyncRecipe.when(
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
                  'Failed to load recipe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (ResolvedRecipe recipe) => _RecipeDetailBody(recipe: recipe),
      ),
    );
  }
}

/// The scrollable body content for the recipe detail view.
class _RecipeDetailBody extends StatelessWidget {
  const _RecipeDetailBody({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Metadata row
          _MetadataRow(recipe: recipe),
          const SizedBox(height: 24),

          // Tags
          if (recipe.tags.isNotEmpty) ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: recipe.tags
                  .map(
                    (String tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Ingredients section
          Text(
            'Ingredients',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          IngredientList(ingredients: recipe.ingredients),
          const SizedBox(height: 24),

          // Steps section
          Text(
            'Instructions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...recipe.steps.map(
            (recipe_model.Step step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${step.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          step.instruction,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (step.timeMinutes != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${step.timeMinutes} min',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Source attribution
          if (recipe.source.url != null ||
              recipe.source.creatorHandle != null) ...<Widget>[
            Text(
              'Source',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (recipe.source.creatorHandle != null)
              Text(
                recipe.source.creatorHandle!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            if (recipe.source.url != null)
              Text(
                recipe.source.url!,
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            const SizedBox(height: 24),
          ],

          // Nutrition card
          Text(
            'Nutrition',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          NutritionCard(
            nutrition: recipe.nutrition,
            servings: recipe.servings,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Displays recipe metadata (servings, time) in a horizontal row.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (recipe.servings != null) ...<Widget>[
          const Icon(Icons.people_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${recipe.servings} servings',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 16),
        ],
        if (recipe.timeMinutes != null) ...<Widget>[
          const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${recipe.timeMinutes} min',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
