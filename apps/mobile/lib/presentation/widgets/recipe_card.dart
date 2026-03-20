/// Recipe card widget for the grid layout.
///
/// Displays a recipe with its cover image (or a colored placeholder),
/// title, metadata (time, servings), and an optional favorite button.
/// Designed for responsive grid layouts.
///
/// Implements SPEC section 15: "Home: Grid layout, auto-grouped sections."
library;

import 'package:flutter/material.dart';

import '../../core/utils/cover_image.dart';
import '../../domain/models/recipe.dart';

/// A card displaying a recipe's cover image, title, and metadata.
///
/// When a real cover image URL is available it is loaded from the API.
/// Otherwise, a deterministic color placeholder with the recipe's
/// initial is shown. The placeholder color matches the server-side
/// SVG cover background.
///
/// Optionally shows a favorite heart icon overlay.
class RecipeCard extends StatelessWidget {
  /// Creates a recipe card for the given [recipe].
  const RecipeCard({
    required this.recipe,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    super.key,
  });

  /// The recipe to display.
  final ResolvedRecipe recipe;

  /// Whether this recipe is favorited by the user.
  final bool isFavorite;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the favorite button is tapped.
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = coverImageUrl(recipe.cover);
    final Color placeholderColor = placeholderColorForTitle(recipe.title);
    final String initial = initialForTitle(recipe.title);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Cover image area with favorite overlay
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _CoverImage(
                    imageUrl: imageUrl,
                    placeholderColor: placeholderColor,
                    initial: initial,
                  ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteButton(
                        isFavorite: isFavorite,
                        onToggle: onFavoriteToggle!,
                      ),
                    ),
                ],
              ),
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
                    _MetadataChips(recipe: recipe),
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

/// Favorite heart button overlay on recipe cards.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onToggle,
  });

  final bool isFavorite;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Displays the cover image or a colored placeholder.
class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.imageUrl,
    required this.placeholderColor,
    required this.initial,
  });

  final String? imageUrl;
  final Color placeholderColor;
  final String initial;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return _Placeholder(color: placeholderColor, initial: initial);
        },
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? loadingProgress,
        ) {
          if (loadingProgress == null) return child;
          return _Placeholder(color: placeholderColor, initial: initial);
        },
      );
    }
    return _Placeholder(color: placeholderColor, initial: initial);
  }
}

/// A colored placeholder with the recipe's initial letter.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.color,
    required this.initial,
  });

  final Color color;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Displays time and servings as compact chips.
class _MetadataChips extends StatelessWidget {
  const _MetadataChips({required this.recipe});

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
