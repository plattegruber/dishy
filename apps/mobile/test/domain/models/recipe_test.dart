import 'dart:convert';

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform', () {
    test('all values are defined', () {
      expect(Platform.values, hasLength(6));
      expect(Platform.values, contains(Platform.instagram));
      expect(Platform.values, contains(Platform.tiktok));
      expect(Platform.values, contains(Platform.youtube));
      expect(Platform.values, contains(Platform.website));
      expect(Platform.values, contains(Platform.manual));
      expect(Platform.values, contains(Platform.unknown));
    });
  });

  group('Source', () {
    test('roundtrips with all fields', () {
      const source = Source(
        platform: Platform.instagram,
        url: 'https://instagram.com/p/abc123',
        creatorHandle: '@chefmike',
        creatorId: '12345678',
      );
      final json = jsonDecode(jsonEncode(source.toJson()));
      final deserialized = Source.fromJson(json as Map<String, dynamic>);
      expect(deserialized.platform, equals(Platform.instagram));
      expect(deserialized.url, equals('https://instagram.com/p/abc123'));
      expect(deserialized.creatorHandle, equals('@chefmike'));
      expect(deserialized.creatorId, equals('12345678'));
    });

    test('roundtrips with no optional fields', () {
      const source = Source(platform: Platform.manual);
      final json = jsonDecode(jsonEncode(source.toJson()));
      final deserialized = Source.fromJson(json as Map<String, dynamic>);
      expect(deserialized.platform, equals(Platform.manual));
      expect(deserialized.url, isNull);
      expect(deserialized.creatorHandle, isNull);
      expect(deserialized.creatorId, isNull);
    });
  });

  group('CoverOutput', () {
    test('sourceImage roundtrips', () {
      const cover = CoverOutput.sourceImage(assetId: 'img_001');
      final json = jsonDecode(jsonEncode(cover.toJson()));
      final deserialized =
          CoverOutput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CoverOutputSourceImage>());
      expect(
        (deserialized as CoverOutputSourceImage).assetId,
        equals('img_001'),
      );
    });

    test('enhancedImage roundtrips', () {
      const cover = CoverOutput.enhancedImage(assetId: 'img_enhanced_001');
      final json = jsonDecode(jsonEncode(cover.toJson()));
      final deserialized =
          CoverOutput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CoverOutputEnhancedImage>());
    });

    test('generatedCover roundtrips', () {
      const cover = CoverOutput.generatedCover(assetId: 'img_gen_001');
      final json = jsonDecode(jsonEncode(cover.toJson()));
      final deserialized =
          CoverOutput.fromJson(json as Map<String, dynamic>);
      expect(deserialized, isA<CoverOutputGeneratedCover>());
    });
  });

  group('Step', () {
    test('roundtrips with time', () {
      const step = Step(
        number: 1,
        instruction: 'Preheat oven to 350F',
        timeMinutes: 10,
      );
      final json = jsonDecode(jsonEncode(step.toJson()));
      final deserialized = Step.fromJson(json as Map<String, dynamic>);
      expect(deserialized.number, equals(1));
      expect(deserialized.instruction, equals('Preheat oven to 350F'));
      expect(deserialized.timeMinutes, equals(10));
    });

    test('roundtrips without time', () {
      const step = Step(
        number: 2,
        instruction: 'Mix dry ingredients',
      );
      final json = jsonDecode(jsonEncode(step.toJson()));
      final deserialized = Step.fromJson(json as Map<String, dynamic>);
      expect(deserialized.timeMinutes, isNull);
    });
  });

  group('ResolvedRecipe', () {
    test('roundtrips', () {
      const recipe = ResolvedRecipe(
        id: 'recipe_001',
        title: 'Chocolate Cake',
        ingredients: [
          ResolvedIngredient(
            parsed: ParsedIngredient(
              quantity: 2.0,
              unit: 'cups',
              name: 'flour',
            ),
            resolution: IngredientResolution.matched(
              foodId: 'usda_flour',
              confidence: 0.95,
            ),
          ),
        ],
        steps: [
          Step(number: 1, instruction: 'Preheat oven to 350F', timeMinutes: 10),
        ],
        servings: 8,
        timeMinutes: 60,
        source: Source(
          platform: Platform.instagram,
          url: 'https://instagram.com/p/abc',
          creatorHandle: '@baker',
        ),
        nutrition: NutritionComputation(
          perRecipe: NutritionFacts(
            calories: 3200.0,
            protein: 40.0,
            carbs: 450.0,
            fat: 140.0,
          ),
          perServing: NutritionFacts(
            calories: 400.0,
            protein: 5.0,
            carbs: 56.25,
            fat: 17.5,
          ),
          status: NutritionStatus.calculated,
        ),
        cover: CoverOutput.sourceImage(assetId: 'cover_001'),
        tags: ['dessert', 'baking'],
      );
      final json = jsonDecode(jsonEncode(recipe.toJson()));
      final deserialized =
          ResolvedRecipe.fromJson(json as Map<String, dynamic>);
      expect(deserialized.id, equals('recipe_001'));
      expect(deserialized.title, equals('Chocolate Cake'));
      expect(deserialized.ingredients, hasLength(1));
      expect(deserialized.steps, hasLength(1));
      expect(deserialized.servings, equals(8));
      expect(deserialized.tags, hasLength(2));
    });
  });

  group('UserRecipeView', () {
    test('roundtrips with patches', () {
      const view = UserRecipeView(
        recipeId: 'recipe_001',
        userId: 'user_abc',
        saved: true,
        favorite: false,
        notes: 'Delicious!',
        patches: [
          RecipePatch(
            field: 'servings',
            value: 12,
            createdAt: '2026-03-19T12:00:00Z',
          ),
        ],
      );
      final json = jsonDecode(jsonEncode(view.toJson()));
      final deserialized =
          UserRecipeView.fromJson(json as Map<String, dynamic>);
      expect(deserialized.recipeId, equals('recipe_001'));
      expect(deserialized.userId, equals('user_abc'));
      expect(deserialized.saved, isTrue);
      expect(deserialized.favorite, isFalse);
      expect(deserialized.notes, equals('Delicious!'));
      expect(deserialized.patches, hasLength(1));
      expect(deserialized.patches.first.field, equals('servings'));
    });

    test('roundtrips with empty patches', () {
      const view = UserRecipeView(
        recipeId: 'recipe_002',
        userId: 'user_def',
        saved: true,
        favorite: true,
        patches: [],
      );
      final json = jsonDecode(jsonEncode(view.toJson()));
      final deserialized =
          UserRecipeView.fromJson(json as Map<String, dynamic>);
      expect(deserialized.notes, isNull);
      expect(deserialized.patches, isEmpty);
    });
  });
}
