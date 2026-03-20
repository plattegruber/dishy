/// Recipe detail screen -- displays a single recipe's full information.
///
/// Shows a hero cover image, recipe title, parsed ingredients with
/// checkboxes, step-by-step instructions, source attribution with links,
/// nutrition facts, and action buttons for cooking mode, sharing, and
/// favoriting. Clean, readable layout per SPEC section 15: "Recipe View".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/cover_image.dart';
import '../../domain/models/ingredient.dart';
import '../../domain/models/recipe.dart' as recipe_model;
import '../../domain/models/recipe.dart' hide Step;
import '../providers/recipe_detail_provider.dart';
import '../providers/user_recipe_view_provider.dart';
import '../widgets/nutrition_card.dart';
import 'cooking_mode_screen.dart';

/// Screen displaying the full details of a single recipe.
///
/// Takes a [recipeId] parameter and fetches the recipe from the API.
/// Displays title, ingredients with checkboxes, steps, source, nutrition,
/// and action buttons for cooking mode and sharing.
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
        actions: <Widget>[
          asyncRecipe.whenOrNull(
                data: (ResolvedRecipe recipe) {
                  final UserRecipeViewState userViews =
                      ref.watch(userRecipeViewProvider);
                  final bool isFav = userViews.isFavorite(recipe.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : null,
                    ),
                    tooltip: isFav ? 'Unfavorite' : 'Favorite',
                    onPressed: () => ref
                        .read(userRecipeViewProvider.notifier)
                        .toggleFavorite(recipe.id),
                  );
                },
              ) ??
              const SizedBox.shrink(),
          asyncRecipe.whenOrNull(
                data: (ResolvedRecipe recipe) {
                  return IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () => _shareRecipe(recipe),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
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

  void _shareRecipe(ResolvedRecipe recipe) {
    final StringBuffer text = StringBuffer();
    text.writeln(recipe.title);
    if (recipe.source.url != null) {
      text.writeln(recipe.source.url);
    }
    text.writeln('\nShared from Dishy');
    Share.share(text.toString());
  }
}

/// The scrollable body content for the recipe detail view.
class _RecipeDetailBody extends StatelessWidget {
  const _RecipeDetailBody({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Hero cover image
                _HeroCover(recipe: recipe),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Metadata row
                      _MetadataRow(recipe: recipe),
                      const SizedBox(height: 16),

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

                      // Ingredients section with checkboxes
                      Text(
                        'Ingredients',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _IngredientChecklist(ingredients: recipe.ingredients),
                      const SizedBox(height: 24),

                      // Steps section
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...recipe.steps.map(
                        (recipe_model.Step step) => _StepRow(step: step),
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
                        _SourceAttribution(source: recipe.source),
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
                ),
              ],
            ),
          ),
        ),
        // Start Cooking button
        _StartCookingBar(recipe: recipe),
      ],
    );
  }
}

/// "Start Cooking" button at the bottom of the recipe detail.
class _StartCookingBar extends StatelessWidget {
  const _StartCookingBar({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    CookingModeScreen(recipe: recipe),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Cooking'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero cover image at the top of the recipe detail.
class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = coverImageUrl(recipe.cover);
    final Color color = placeholderColorForTitle(recipe.title);
    final String initial = initialForTitle(recipe.title);

    if (imageUrl != null) {
      return SizedBox(
        height: 240,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
            return _HeroPlaceholder(color: color, initial: initial);
          },
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) return child;
            return _HeroPlaceholder(color: color, initial: initial);
          },
        ),
      );
    }

    return _HeroPlaceholder(color: color, initial: initial);
  }
}

/// Colored placeholder for the hero cover area.
class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({
    required this.color,
    required this.initial,
  });

  final Color color;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      color: color,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
        ),
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

/// Ingredient checklist with tap-to-check functionality.
class _IngredientChecklist extends StatefulWidget {
  const _IngredientChecklist({required this.ingredients});

  final List<ResolvedIngredient> ingredients;

  @override
  State<_IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<_IngredientChecklist> {
  final Set<int> _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.ingredients.isEmpty) {
      return const Text(
        'No ingredients listed.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    return Column(
      children: List<Widget>.generate(
        widget.ingredients.length,
        (int index) {
          final ResolvedIngredient ingredient = widget.ingredients[index];
          final bool isChecked = _checked.contains(index);

          return InkWell(
            onTap: () {
              setState(() {
                if (isChecked) {
                  _checked.remove(index);
                } else {
                  _checked.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (_) {
                        setState(() {
                          if (isChecked) {
                            _checked.remove(index);
                          } else {
                            _checked.add(index);
                          }
                        });
                      },
                      activeColor: Colors.deepOrange,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _IngredientText(
                      parsed: ingredient.parsed,
                      isChecked: isChecked,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Displays the formatted ingredient text.
class _IngredientText extends StatelessWidget {
  const _IngredientText({required this.parsed, required this.isChecked});

  final ParsedIngredient parsed;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = TextStyle(
      fontSize: 16,
      decoration: isChecked ? TextDecoration.lineThrough : null,
      color: isChecked ? Colors.grey : null,
    );

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(baseStyle),
        children: <InlineSpan>[
          if (parsed.quantity != null)
            TextSpan(
              text: '${_formatQuantity(parsed.quantity!)} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (parsed.unit != null)
            TextSpan(
              text: '${parsed.unit} ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          TextSpan(text: parsed.name),
          if (parsed.preparation != null)
            TextSpan(
              text: ', ${parsed.preparation}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  String _formatQuantity(double qty) {
    if (qty == qty.toInt().toDouble()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }
}

/// A single recipe step row with number badge.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final recipe_model.Step step;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

/// Source attribution with tappable link.
class _SourceAttribution extends StatelessWidget {
  const _SourceAttribution({required this.source});

  final Source source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (source.creatorHandle != null)
          Text(
            source.creatorHandle!,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        if (source.url != null)
          InkWell(
            onTap: () => _launchUrl(source.url!),
            child: Text(
              source.url!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.tryParse(urlString) ?? Uri();
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
