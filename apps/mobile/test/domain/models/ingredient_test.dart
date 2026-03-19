import 'dart:convert';

import 'package:dishy/domain/models/ingredient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngredientLine', () {
    test('roundtrips with parsed ingredient', () {
      const line = IngredientLine(
        rawText: '2 cups all-purpose flour, sifted',
        parsed: ParsedIngredient(
          quantity: 2.0,
          unit: 'cups',
          name: 'all-purpose flour',
          preparation: 'sifted',
        ),
      );
      final json = jsonDecode(jsonEncode(line.toJson()));
      final deserialized =
          IngredientLine.fromJson(json as Map<String, dynamic>);
      expect(deserialized.rawText, equals('2 cups all-purpose flour, sifted'));
      expect(deserialized.parsed, isNotNull);
      expect(deserialized.parsed?.quantity, equals(2.0));
      expect(deserialized.parsed?.unit, equals('cups'));
      expect(deserialized.parsed?.name, equals('all-purpose flour'));
      expect(deserialized.parsed?.preparation, equals('sifted'));
    });

    test('roundtrips without parsed ingredient', () {
      const line = IngredientLine(rawText: 'a pinch of salt');
      final json = jsonDecode(jsonEncode(line.toJson()));
      final deserialized =
          IngredientLine.fromJson(json as Map<String, dynamic>);
      expect(deserialized.rawText, equals('a pinch of salt'));
      expect(deserialized.parsed, isNull);
    });
  });

  group('ParsedIngredient', () {
    test('roundtrips with all fields', () {
      const parsed = ParsedIngredient(
        quantity: 1.5,
        unit: 'tbsp',
        name: 'olive oil',
        preparation: 'extra virgin',
      );
      final json = jsonDecode(jsonEncode(parsed.toJson()));
      final deserialized =
          ParsedIngredient.fromJson(json as Map<String, dynamic>);
      expect(deserialized.quantity, equals(1.5));
      expect(deserialized.unit, equals('tbsp'));
      expect(deserialized.name, equals('olive oil'));
      expect(deserialized.preparation, equals('extra virgin'));
    });

    test('roundtrips with minimal fields', () {
      const parsed = ParsedIngredient(name: 'salt');
      final json = jsonDecode(jsonEncode(parsed.toJson()));
      final deserialized =
          ParsedIngredient.fromJson(json as Map<String, dynamic>);
      expect(deserialized.quantity, isNull);
      expect(deserialized.unit, isNull);
      expect(deserialized.name, equals('salt'));
      expect(deserialized.preparation, isNull);
    });
  });

  group('IngredientResolution', () {
    test('matched roundtrips', () {
      const resolution = IngredientResolution.matched(
        foodId: 'usda_12345',
        confidence: 0.95,
      );
      final json = jsonDecode(jsonEncode(resolution.toJson()));
      final deserialized =
          IngredientResolution.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<IngredientResolutionMatched>());
      final matched = deserialized as IngredientResolutionMatched;
      expect(matched.foodId, equals('usda_12345'));
      expect(matched.confidence, equals(0.95));
    });

    test('fuzzyMatched roundtrips', () {
      const resolution = IngredientResolution.fuzzyMatched(
        candidates: [
          FuzzyCandidate(foodId: 'usda_111', confidence: 0.8),
          FuzzyCandidate(foodId: 'usda_222', confidence: 0.6),
        ],
        confidence: 0.8,
      );
      final json = jsonDecode(jsonEncode(resolution.toJson()));
      final deserialized =
          IngredientResolution.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<IngredientResolutionFuzzyMatched>());
      final fuzzy = deserialized as IngredientResolutionFuzzyMatched;
      expect(fuzzy.candidates, hasLength(2));
      expect(fuzzy.confidence, equals(0.8));
    });

    test('unmatched roundtrips', () {
      const resolution = IngredientResolution.unmatched(
        text: 'secret spice mix',
      );
      final json = jsonDecode(jsonEncode(resolution.toJson()));
      final deserialized =
          IngredientResolution.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<IngredientResolutionUnmatched>());
      expect(
        (deserialized as IngredientResolutionUnmatched).text,
        equals('secret spice mix'),
      );
    });
  });

  group('ResolvedIngredient', () {
    test('roundtrips', () {
      const resolved = ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 1.0,
          unit: 'cup',
          name: 'sugar',
        ),
        resolution: IngredientResolution.matched(
          foodId: 'usda_sugar',
          confidence: 0.97,
        ),
      );
      final json = jsonDecode(jsonEncode(resolved.toJson()));
      final deserialized =
          ResolvedIngredient.fromJson(json as Map<String, dynamic>);
      expect(deserialized.parsed.name, equals('sugar'));
      expect(deserialized.resolution, isA<IngredientResolutionMatched>());
    });
  });

  group('FuzzyCandidate', () {
    test('roundtrips', () {
      const candidate = FuzzyCandidate(
        foodId: 'usda_abc',
        confidence: 0.75,
      );
      final json = jsonDecode(jsonEncode(candidate.toJson()));
      final deserialized =
          FuzzyCandidate.fromJson(json as Map<String, dynamic>);
      expect(deserialized.foodId, equals('usda_abc'));
      expect(deserialized.confidence, equals(0.75));
    });
  });
}
