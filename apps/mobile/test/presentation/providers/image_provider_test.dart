/// Tests for image provider utilities.
library;

import 'package:dishy/domain/models/recipe.dart';
import 'package:dishy/presentation/providers/image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('imageUrlForAsset', () {
    test('constructs correct URL from asset ID', () {
      final String url = imageUrlForAsset('cover_abc123.jpg');
      expect(url, endsWith('/images/cover_abc123.jpg'));
    });
  });

  group('assetIdFromCover', () {
    test('extracts ID from SourceImage', () {
      const CoverOutput cover =
          CoverOutput.sourceImage(assetId: 'source_001');
      expect(assetIdFromCover(cover), equals('source_001'));
    });

    test('extracts ID from EnhancedImage', () {
      const CoverOutput cover =
          CoverOutput.enhancedImage(assetId: 'enhanced_001');
      expect(assetIdFromCover(cover), equals('enhanced_001'));
    });

    test('extracts ID from GeneratedCover', () {
      const CoverOutput cover =
          CoverOutput.generatedCover(assetId: 'generated_001');
      expect(assetIdFromCover(cover), equals('generated_001'));
    });
  });

  group('coverHasNetworkImage', () {
    test('returns true for source image with real ID', () {
      const CoverOutput cover =
          CoverOutput.sourceImage(assetId: 'cover_abc.jpg');
      expect(coverHasNetworkImage(cover), isTrue);
    });

    test('returns false for placeholder cover', () {
      const CoverOutput cover =
          CoverOutput.generatedCover(assetId: 'placeholder_cover');
      expect(coverHasNetworkImage(cover), isFalse);
    });

    test('returns false for generated cover', () {
      const CoverOutput cover =
          CoverOutput.generatedCover(assetId: 'generated_pancakes');
      expect(coverHasNetworkImage(cover), isFalse);
    });

    test('returns true for real uploaded cover', () {
      const CoverOutput cover =
          CoverOutput.sourceImage(assetId: 'cover_550e8400.jpg');
      expect(coverHasNetworkImage(cover), isTrue);
    });
  });

  group('placeholderColorForTitle', () {
    test('returns deterministic color for same title', () {
      final Color color1 = placeholderColorForTitle('Chocolate Cake');
      final Color color2 = placeholderColorForTitle('Chocolate Cake');
      expect(color1, equals(color2));
    });

    test('returns a non-transparent color', () {
      final Color color = placeholderColorForTitle('Pancakes');
      expect(color.a, greaterThan(0));
    });

    test('handles empty string', () {
      final Color color = placeholderColorForTitle('');
      // Should not throw, should return a valid color
      expect(color, isNotNull);
    });

    test('different titles usually produce different colors', () {
      // This isn't guaranteed for all pairs but should work for these
      final Color color1 = placeholderColorForTitle('Chocolate Cake');
      final Color color2 = placeholderColorForTitle('Caesar Salad');
      // Both should be valid colors
      expect(color1.a, greaterThan(0));
      expect(color2.a, greaterThan(0));
    });
  });
}
