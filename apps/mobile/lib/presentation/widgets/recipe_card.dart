/// Recipe card widget for the recipe grid.
///
/// Shows the recipe cover image (or a styled placeholder), title overlay,
/// and metadata (time, servings). Designed for use in a 2-column grid
/// per SPEC section 15: "Home: Grid layout".
///
/// The card loads cover images from the API when available and falls
/// back to a colored placeholder with the recipe title when no image
/// is stored.
library;

import 'package:flutter/material.dart';

import '../../domain/models/recipe.dart';
import '../providers/image_provider.dart';

/// A card widget displaying a recipe in the home grid.
///
/// Shows:
/// - Cover image from the API, or a styled color placeholder
/// - Recipe title overlaid on the cover
/// - Time and servings metadata at the bottom
///
/// The [onTap] callback is invoked when the user taps the card.
class RecipeCard extends StatelessWidget {
  /// Creates a recipe card for the given [recipe].
  const RecipeCard({
    required this.recipe,
    required this.onTap,
    super.key,
  });

  /// The recipe to display.
  final ResolvedRecipe recipe;

  /// Called when the user taps this card.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Cover image area
            Expanded(
              flex: 3,
              child: _CoverImage(recipe: recipe),
            ),
            // Title and metadata
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    _MetadataRow(recipe: recipe),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the cover image or a styled placeholder.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkImage = coverHasNetworkImage(recipe.cover);

    if (hasNetworkImage) {
      final String url = imageUrlForAsset(assetIdFromCover(recipe.cover));
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return _Placeholder(title: recipe.title);
        },
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }
          return _Placeholder(title: recipe.title, showLoading: true);
        },
      );
    }

    return _Placeholder(title: recipe.title);
  }
}

/// A styled placeholder when no cover image is available.
///
/// Shows a solid color background (deterministic per recipe title)
/// with a restaurant icon and truncated title text.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.title,
    this.showLoading = false,
  });

  final String title;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final Color color = placeholderColorForTitle(title);

    return Container(
      color: color,
      child: Center(
        child: showLoading
            ? const CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2,
              )
            : const Icon(
                Icons.restaurant,
                size: 36,
                color: Colors.white70,
              ),
      ),
    );
  }
}

/// Displays recipe metadata (time, servings) in a compact row.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.recipe});

  final ResolvedRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (recipe.timeMinutes != null) ...<Widget>[
          const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 3),
          Text(
            '${recipe.timeMinutes} min',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(width: 8),
        ],
        if (recipe.servings != null) ...<Widget>[
          const Icon(Icons.people_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 3),
          Text(
            '${recipe.servings}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
