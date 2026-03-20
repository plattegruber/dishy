/// Riverpod providers for recipe cover image loading and caching.
///
/// Provides image URLs for recipe covers and generates placeholder
/// widgets when no cover image is available from the API.
///
/// Implements the image loading requirements from Phase 7:
/// - Cached image loading from API
/// - Placeholder generation for recipes without covers
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/ids.dart';
import '../../domain/models/recipe.dart';

/// Constructs the full URL for an image asset served by the API.
///
/// The API serves images at `GET /images/:asset_id` with proper
/// Content-Type and cache headers.
String imageUrlForAsset(AssetId assetId) {
  return '${AppConstants.apiBaseUrl}/images/$assetId';
}

/// Extracts the asset ID from a [CoverOutput], regardless of variant.
AssetId assetIdFromCover(CoverOutput cover) {
  return switch (cover) {
    CoverOutputSourceImage(:final assetId) => assetId,
    CoverOutputEnhancedImage(:final assetId) => assetId,
    CoverOutputGeneratedCover(:final assetId) => assetId,
  };
}

/// Returns `true` if the cover has a real (non-placeholder) image
/// that should be loaded from the network.
///
/// Placeholder covers have asset IDs starting with "placeholder_"
/// or "generated_" and should use the local placeholder widget instead.
bool coverHasNetworkImage(CoverOutput cover) {
  final AssetId id = assetIdFromCover(cover);
  return !id.startsWith('placeholder_') && !id.startsWith('generated_');
}

/// Provides the image URL for a recipe's cover, if it has a network image.
///
/// Returns `null` if the cover is a local placeholder.
///
/// Usage:
/// ```dart
/// final url = ref.watch(coverImageUrlProvider(recipe.cover));
/// ```
final Provider<String? Function(CoverOutput)> coverImageUrlProvider =
    Provider<String? Function(CoverOutput)>(
  (Ref ref) {
    return (CoverOutput cover) {
      if (coverHasNetworkImage(cover)) {
        return imageUrlForAsset(assetIdFromCover(cover));
      }
      return null;
    };
  },
);

/// A palette of background colors for placeholder covers.
///
/// Colors are selected deterministically based on the recipe title
/// so the same recipe always gets the same placeholder color.
const List<Color> _placeholderColors = <Color>[
  Color(0xFFE57373), // red
  Color(0xFFF06292), // pink
  Color(0xFFBA68C8), // purple
  Color(0xFF9575CD), // deep purple
  Color(0xFF7986CB), // indigo
  Color(0xFF64B5F6), // blue
  Color(0xFF4FC3F7), // light blue
  Color(0xFF4DD0E1), // cyan
  Color(0xFF4DB6AC), // teal
  Color(0xFF81C784), // green
  Color(0xFFAED581), // light green
  Color(0xFFFFD54F), // amber
  Color(0xFFFFB74D), // orange
  Color(0xFFFF8A65), // deep orange
];

/// Returns a deterministic placeholder color based on the recipe title.
///
/// Uses the same hashing algorithm as the backend cover service so
/// placeholder colors are visually consistent.
Color placeholderColorForTitle(String title) {
  int hash = 0;
  for (int i = 0; i < title.length; i++) {
    hash = (hash * 31 + title.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return _placeholderColors[hash % _placeholderColors.length];
}
