import 'dart:convert';

import 'package:dishy/domain/models/nutrition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NutritionFacts', () {
    test('roundtrips', () {
      const facts = NutritionFacts(
        calories: 350.5,
        protein: 12.3,
        carbs: 45.0,
        fat: 15.2,
      );
      final json = jsonDecode(jsonEncode(facts.toJson()));
      final deserialized =
          NutritionFacts.fromJson(json as Map<String, dynamic>);
      expect(deserialized.calories, equals(350.5));
      expect(deserialized.protein, equals(12.3));
      expect(deserialized.carbs, equals(45.0));
      expect(deserialized.fat, equals(15.2));
    });
  });

  group('NutritionComputation', () {
    test('roundtrips with per-serving', () {
      const computation = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2800.0,
          protein: 80.0,
          carbs: 320.0,
          fat: 120.0,
        ),
        perServing: NutritionFacts(
          calories: 350.0,
          protein: 10.0,
          carbs: 40.0,
          fat: 15.0,
        ),
        status: NutritionStatus.calculated,
      );
      final json = jsonDecode(jsonEncode(computation.toJson()));
      final deserialized =
          NutritionComputation.fromJson(json as Map<String, dynamic>);
      expect(deserialized.perRecipe.calories, equals(2800.0));
      expect(deserialized.perServing, isNotNull);
      expect(deserialized.perServing?.calories, equals(350.0));
      expect(deserialized.status, equals(NutritionStatus.calculated));
    });

    test('roundtrips without per-serving', () {
      const computation = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 500.0,
          protein: 20.0,
          carbs: 60.0,
          fat: 10.0,
        ),
        status: NutritionStatus.estimated,
      );
      final json = jsonDecode(jsonEncode(computation.toJson()));
      final deserialized =
          NutritionComputation.fromJson(json as Map<String, dynamic>);
      expect(deserialized.perServing, isNull);
      expect(deserialized.status, equals(NutritionStatus.estimated));
    });
  });

  group('NutritionStatus', () {
    test('all values are defined', () {
      expect(NutritionStatus.values, hasLength(4));
      expect(NutritionStatus.values, contains(NutritionStatus.pending));
      expect(NutritionStatus.values, contains(NutritionStatus.calculated));
      expect(NutritionStatus.values, contains(NutritionStatus.estimated));
      expect(NutritionStatus.values, contains(NutritionStatus.unavailable));
    });
  });
}
