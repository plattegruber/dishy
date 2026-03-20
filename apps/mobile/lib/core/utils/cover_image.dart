/// Utilities for constructing cover image URLs and generating
/// placeholder colors from recipe data.
///
/// The cover image system has three tiers:
/// 1. **R2 image** -- served from `/images/:asset_id` when available.
/// 2. **SVG placeholder** -- served from R2 for generated covers.
/// 3. **Local color placeholder** -- deterministic color from the title
///    when the network image hasn't loaded yet.
library;

import 'dart:ui';

import '../../domain/models/recipe.dart';
import '../constants/app_constants.dart';

/// Warm, food-friendly palette for generated cover placeholders.
///
/// Must stay in sync with the API's `COVER_COLORS` in
/// `apps/api/src/services/cover.rs`.
const List<Color> _coverColors = <Color>[
  Color(0xFFE8533F), // tomato red
  Color(0xFFF2994A), // carrot orange
  Color(0xFFF2C94C), // butter yellow
  Color(0xFF6FCF97), // herb green
  Color(0xFF56CCF2), // sky blue
  Color(0xFFBB6BD9), // plum purple
  Color(0xFFEB5757), // strawberry
  Color(0xFFF2784B), // paprika
  Color(0xFF2D9CDB), // blueberry
  Color(0xFF27AE60), // basil green
];

/// Constructs the full URL for an image asset served from the API.
///
/// Returns `null` if the [assetId] looks like a placeholder
/// (starts with "placeholder_" or "generated_") that was never
/// actually uploaded to R2.
String? imageUrlForAsset(String assetId) {
  if (assetId.startsWith('placeholder_') || assetId.startsWith('generated_')) {
    return null;
  }
  return '${AppConstants.apiBaseUrl}/images/$assetId';
}

/// Extracts the asset ID from a [CoverOutput] regardless of variant.
String assetIdFromCover(CoverOutput cover) {
  return switch (cover) {
    CoverOutputSourceImage(:final String assetId) => assetId,
    CoverOutputEnhancedImage(:final String assetId) => assetId,
    CoverOutputGeneratedCover(:final String assetId) => assetId,
  };
}

/// Returns the full image URL for a recipe's cover, or `null` if only
/// a local placeholder should be shown.
String? coverImageUrl(CoverOutput cover) {
  return imageUrlForAsset(assetIdFromCover(cover));
}

/// Deterministic hash matching the API's `simple_hash` (DJB2).
///
/// Produces the same output as the Rust implementation so the
/// client picks the same color the API used for the SVG cover.
int _simpleHash(String s) {
  int hash = 5381;
  for (int i = 0; i < s.length; i++) {
    // Wrap at 32 bits to match Rust u32 wrapping arithmetic
    hash = ((hash * 33) + s.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return hash;
}

/// Returns a deterministic placeholder color for a recipe title.
///
/// Uses the same DJB2 hash as the API so the local placeholder
/// matches the SVG background generated server-side.
Color placeholderColorForTitle(String title) {
  final int hash = _simpleHash(title);
  final int index = hash % _coverColors.length;
  return _coverColors[index];
}

/// Returns the first character of [title] uppercased, or "?" if empty.
///
/// Used as the initial displayed on placeholder covers.
String initialForTitle(String title) {
  if (title.isEmpty) return '?';
  return title[0].toUpperCase();
}
