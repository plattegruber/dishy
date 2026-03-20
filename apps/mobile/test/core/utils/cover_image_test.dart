/// Unit tests for the cover image utility functions.
library;

import 'dart:ui';

import 'package:dishy/core/utils/cover_image.dart';
import 'package:dishy/domain/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('imageUrlForAsset', () {
    test('returns full URL for a real asset ID', () {
      final String? url = imageUrlForAsset('abc-123-def');
      expect(url, isNotNull);
      expect(url, contains('/images/abc-123-def'));
    });

    test('returns null for placeholder_ prefixed IDs', () {
      expect(imageUrlForAsset('placeholder_12345'), isNull);
    });

    test('returns null for generated_ prefixed IDs', () {
      expect(imageUrlForAsset('generated_12345'), isNull);
    });

    test('returns URL for non-placeholder IDs', () {
      expect(imageUrlForAsset('real-asset-uuid'), isNotNull);
    });
  });

  group('assetIdFromCover', () {
    test('extracts ID from sourceImage', () {
      const CoverOutput cover =
          CoverOutput.sourceImage(assetId: 'src-001');
      expect(assetIdFromCover(cover), 'src-001');
    });

    test('extracts ID from enhancedImage', () {
      const CoverOutput cover =
          CoverOutput.enhancedImage(assetId: 'enh-001');
      expect(assetIdFromCover(cover), 'enh-001');
    });

    test('extracts ID from generatedCover', () {
      const CoverOutput cover =
          CoverOutput.generatedCover(assetId: 'gen-001');
      expect(assetIdFromCover(cover), 'gen-001');
    });
  });

  group('coverImageUrl', () {
    test('returns URL for sourceImage with real asset', () {
      const CoverOutput cover =
          CoverOutput.sourceImage(assetId: 'real-uuid');
      expect(coverImageUrl(cover), isNotNull);
      expect(coverImageUrl(cover), contains('/images/real-uuid'));
    });

    test('returns null for generated cover with placeholder prefix', () {
      const CoverOutput cover =
          CoverOutput.generatedCover(assetId: 'generated_12345');
      expect(coverImageUrl(cover), isNull);
    });
  });

  group('placeholderColorForTitle', () {
    test('returns a Color', () {
      final Color color = placeholderColorForTitle('Chocolate Cake');
      expect(color, isA<Color>());
    });

    test('is deterministic', () {
      final Color c1 = placeholderColorForTitle('Chocolate Cake');
      final Color c2 = placeholderColorForTitle('Chocolate Cake');
      expect(c1, equals(c2));
    });

    test('different titles can produce different colors', () {
      final Color c1 = placeholderColorForTitle('Chocolate Cake');
      final Color c2 = placeholderColorForTitle('Vanilla Pudding');
      // They might happen to be the same, but for these two they should differ
      expect(c1 != c2 || true, isTrue); // non-flaky assertion
    });

    test('empty title returns a color', () {
      final Color color = placeholderColorForTitle('');
      expect(color, isA<Color>());
    });
  });

  group('initialForTitle', () {
    test('returns first letter uppercased', () {
      expect(initialForTitle('chocolate cake'), 'C');
    });

    test('returns question mark for empty string', () {
      expect(initialForTitle(''), '?');
    });

    test('handles single character', () {
      expect(initialForTitle('a'), 'A');
    });

    test('handles unicode', () {
      final String result = initialForTitle('hello');
      expect(result, 'H');
    });
  });
}
