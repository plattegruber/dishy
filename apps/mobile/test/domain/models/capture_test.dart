import 'dart:convert';

import 'package:dishy/domain/models/capture.dart';
import 'package:dishy/domain/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptureInput', () {
    test('socialLink serialization roundtrips', () {
      const input = CaptureInput.socialLink(url: 'https://instagram.com/p/abc');
      final json = jsonDecode(jsonEncode(input.toJson()));
      final deserialized =
          CaptureInput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CaptureInputSocialLink>());
      expect(
        (deserialized as CaptureInputSocialLink).url,
        equals('https://instagram.com/p/abc'),
      );
    });

    test('screenshot serialization roundtrips', () {
      const input = CaptureInput.screenshot(image: 'asset_img_001');
      final json = jsonDecode(jsonEncode(input.toJson()));
      final deserialized =
          CaptureInput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CaptureInputScreenshot>());
      expect(
        (deserialized as CaptureInputScreenshot).image,
        equals('asset_img_001'),
      );
    });

    test('scan serialization roundtrips', () {
      const input = CaptureInput.scan(image: 'asset_scan_001');
      final json = jsonDecode(jsonEncode(input.toJson()));
      final deserialized =
          CaptureInput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CaptureInputScan>());
    });

    test('speech serialization roundtrips', () {
      const input = CaptureInput.speech(transcript: 'Two cups of flour');
      final json = jsonDecode(jsonEncode(input.toJson()));
      final deserialized =
          CaptureInput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CaptureInputSpeech>());
      expect(
        (deserialized as CaptureInputSpeech).transcript,
        equals('Two cups of flour'),
      );
    });

    test('manual serialization roundtrips', () {
      const input = CaptureInput.manual(text: '1 cup sugar, 2 eggs');
      final json = jsonDecode(jsonEncode(input.toJson()));
      final deserialized =
          CaptureInput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CaptureInputManual>());
      expect(
        (deserialized as CaptureInputManual).text,
        equals('1 cup sugar, 2 eggs'),
      );
    });
  });

  group('ExtractionArtifact', () {
    test('roundtrips with all fields', () {
      const artifact = ExtractionArtifact(
        id: 'capture_001',
        version: 1,
        rawText: 'raw text here',
        ocrText: null,
        transcript: null,
        ingredients: ['1 cup flour', '2 eggs'],
        steps: ['Mix ingredients'],
        images: ['img_001'],
        source: Source(
          platform: Platform.instagram,
          url: 'https://instagram.com/p/abc',
          creatorHandle: '@chef',
        ),
        confidence: 0.85,
      );
      final json = jsonDecode(jsonEncode(artifact.toJson()));
      final deserialized =
          ExtractionArtifact.fromJson(json as Map<String, dynamic>);
      expect(deserialized.id, equals('capture_001'));
      expect(deserialized.version, equals(1));
      expect(deserialized.rawText, equals('raw text here'));
      expect(deserialized.ocrText, isNull);
      expect(deserialized.ingredients, hasLength(2));
      expect(deserialized.confidence, equals(0.85));
    });

    test('handles null optional fields', () {
      const artifact = ExtractionArtifact(
        id: 'capture_002',
        version: 2,
        ingredients: [],
        steps: [],
        images: [],
        source: Source(platform: Platform.manual),
        confidence: 0.5,
      );
      final json = jsonDecode(jsonEncode(artifact.toJson()));
      final deserialized =
          ExtractionArtifact.fromJson(json as Map<String, dynamic>);
      expect(deserialized.rawText, isNull);
      expect(deserialized.ocrText, isNull);
      expect(deserialized.transcript, isNull);
    });
  });

  group('StructuredRecipeCandidate', () {
    test('roundtrips with all fields', () {
      const candidate = StructuredRecipeCandidate(
        title: 'Chocolate Cake',
        ingredientLines: ['2 cups flour', '1 cup sugar'],
        steps: ['Preheat oven', 'Mix dry ingredients'],
        servings: 8,
        timeMinutes: 45,
        tags: ['dessert', 'baking'],
        confidence: 0.92,
      );
      final json = jsonDecode(jsonEncode(candidate.toJson()));
      final deserialized =
          StructuredRecipeCandidate.fromJson(json as Map<String, dynamic>);
      expect(deserialized.title, equals('Chocolate Cake'));
      expect(deserialized.ingredientLines, hasLength(2));
      expect(deserialized.servings, equals(8));
      expect(deserialized.timeMinutes, equals(45));
    });

    test('handles null optional fields', () {
      const candidate = StructuredRecipeCandidate(
        ingredientLines: [],
        steps: [],
        tags: [],
        confidence: 0.5,
      );
      final json = jsonDecode(jsonEncode(candidate.toJson()));
      final deserialized =
          StructuredRecipeCandidate.fromJson(json as Map<String, dynamic>);
      expect(deserialized.title, isNull);
      expect(deserialized.servings, isNull);
      expect(deserialized.timeMinutes, isNull);
    });
  });
}
