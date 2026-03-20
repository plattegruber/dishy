/// Unit tests for the grocery service -- merging, categorization, formatting.
library;

import 'package:dishy/domain/models/grocery.dart';
import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/domain/services/grocery_service.dart';
import 'package:flutter_test/flutter_test.dart';

ResolvedRecipe _makeRecipe({
  required String id,
  required List<ResolvedIngredient> ingredients,
}) {
  return ResolvedRecipe(
    id: id,
    title: 'Recipe $id',
    ingredients: ingredients,
    steps: const <recipe_model.Step>[
      recipe_model.Step(number: 1, instruction: 'Do something'),
    ],
    source: const Source(platform: Platform.manual),
    nutrition: const NutritionComputation(
      perRecipe: NutritionFacts(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
      status: NutritionStatus.unavailable,
    ),
    cover: const CoverOutput.generatedCover(assetId: 'c'),
    tags: const <String>[],
  );
}

ResolvedIngredient _ingredient({
  required String name,
  double? quantity,
  String? unit,
}) {
  return ResolvedIngredient(
    parsed: ParsedIngredient(
      name: name,
      quantity: quantity,
      unit: unit,
    ),
    resolution: IngredientResolution.unmatched(text: name),
  );
}

void main() {
  const GroceryService service = GroceryService();

  group('GroceryService.buildGroceryList', () {
    test('returns empty list for no recipes', () {
      final GroceryList list = service.buildGroceryList(<ResolvedRecipe>[]);
      expect(list.items, isEmpty);
      expect(list.recipeIds, isEmpty);
    });

    test('returns items for a single recipe', () {
      final ResolvedRecipe recipe = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 2, unit: 'cups'),
          _ingredient(name: 'sugar', quantity: 1, unit: 'cup'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe]);

      expect(list.items.length, 2);
      expect(list.recipeIds, <String>['r1']);
    });

    test('merges duplicate ingredients across recipes', () {
      final ResolvedRecipe recipe1 = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 2, unit: 'cups'),
        ],
      );
      final ResolvedRecipe recipe2 = _makeRecipe(
        id: 'r2',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 1, unit: 'cups'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe1, recipe2]);

      // Should merge into 3 cups flour
      final GroceryItem flourItem = list.items.firstWhere(
        (GroceryItem item) => item.name == 'flour',
      );
      expect(flourItem.quantity, 3);
      expect(flourItem.recipeIds.length, 2);
    });

    test('normalizes plural units before merging', () {
      final ResolvedRecipe recipe1 = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 2, unit: 'cup'),
        ],
      );
      final ResolvedRecipe recipe2 = _makeRecipe(
        id: 'r2',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 1, unit: 'cups'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe1, recipe2]);

      final GroceryItem flourItem = list.items.firstWhere(
        (GroceryItem item) => item.name == 'flour',
      );
      expect(flourItem.quantity, 3);
    });

    test('does not merge ingredients with different units', () {
      final ResolvedRecipe recipe = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 2, unit: 'cups'),
          _ingredient(name: 'flour', quantity: 100, unit: 'g'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe]);

      final List<GroceryItem> flourItems = list.items
          .where((GroceryItem item) => item.name == 'flour')
          .toList();
      expect(flourItems.length, 2);
    });

    test('items are sorted by category then name', () {
      final ResolvedRecipe recipe = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'sugar', quantity: 1, unit: 'cup'),
          _ingredient(name: 'tomato', quantity: 2),
          _ingredient(name: 'chicken', quantity: 1, unit: 'lb'),
          _ingredient(name: 'milk', quantity: 1, unit: 'cup'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe]);

      // Check categories are in order
      final List<GroceryCategory> categories =
          list.items.map((GroceryItem item) => item.category).toList();

      // produce < dairy < meat < pantry
      for (int i = 0; i < categories.length - 1; i++) {
        expect(
          categories[i].index,
          lessThanOrEqualTo(categories[i + 1].index),
        );
      }
    });

    test('items start unchecked', () {
      final ResolvedRecipe recipe = _makeRecipe(
        id: 'r1',
        ingredients: <ResolvedIngredient>[
          _ingredient(name: 'flour', quantity: 2, unit: 'cups'),
        ],
      );

      final GroceryList list =
          service.buildGroceryList(<ResolvedRecipe>[recipe]);

      expect(list.items.first.checked, false);
    });
  });

  group('GroceryService.categorizeIngredient', () {
    test('categorizes produce', () {
      expect(
        GroceryService.categorizeIngredient('tomato'),
        GroceryCategory.produce,
      );
      expect(
        GroceryService.categorizeIngredient('fresh basil'),
        GroceryCategory.produce,
      );
    });

    test('categorizes dairy', () {
      expect(
        GroceryService.categorizeIngredient('whole milk'),
        GroceryCategory.dairy,
      );
      expect(
        GroceryService.categorizeIngredient('eggs'),
        GroceryCategory.dairy,
      );
      expect(
        GroceryService.categorizeIngredient('butter'),
        GroceryCategory.dairy,
      );
    });

    test('categorizes meat', () {
      expect(
        GroceryService.categorizeIngredient('chicken breast'),
        GroceryCategory.meat,
      );
      expect(
        GroceryService.categorizeIngredient('ground beef'),
        GroceryCategory.meat,
      );
    });

    test('categorizes pantry items', () {
      expect(
        GroceryService.categorizeIngredient('all-purpose flour'),
        GroceryCategory.pantry,
      );
      expect(
        GroceryService.categorizeIngredient('granulated sugar'),
        GroceryCategory.pantry,
      );
    });

    test('defaults unknown items to pantry', () {
      expect(
        GroceryService.categorizeIngredient('xanthan gum'),
        GroceryCategory.pantry,
      );
    });
  });

  group('formatGroceryQuantity', () {
    test('formats quantity with unit', () {
      const GroceryItem item = GroceryItem(
        name: 'flour',
        quantity: 2,
        unit: 'cups',
        category: GroceryCategory.pantry,
        recipeIds: <String>['r1'],
      );
      expect(formatGroceryQuantity(item), '2 cups flour');
    });

    test('formats quantity without unit', () {
      const GroceryItem item = GroceryItem(
        name: 'eggs',
        quantity: 3,
        category: GroceryCategory.dairy,
        recipeIds: <String>['r1'],
      );
      expect(formatGroceryQuantity(item), '3 eggs');
    });

    test('formats name only when no quantity', () {
      const GroceryItem item = GroceryItem(
        name: 'salt',
        category: GroceryCategory.pantry,
        recipeIds: <String>['r1'],
      );
      expect(formatGroceryQuantity(item), 'salt');
    });

    test('formats fractional quantities', () {
      const GroceryItem item = GroceryItem(
        name: 'butter',
        quantity: 0.5,
        unit: 'cup',
        category: GroceryCategory.dairy,
        recipeIds: <String>['r1'],
      );
      expect(formatGroceryQuantity(item), '0.5 cup butter');
    });
  });

  group('groceryCategoryLabel', () {
    test('returns correct labels', () {
      expect(groceryCategoryLabel(GroceryCategory.produce), 'Produce');
      expect(groceryCategoryLabel(GroceryCategory.dairy), 'Dairy & Eggs');
      expect(groceryCategoryLabel(GroceryCategory.meat), 'Meat & Seafood');
      expect(groceryCategoryLabel(GroceryCategory.pantry), 'Pantry');
      expect(groceryCategoryLabel(GroceryCategory.frozen), 'Frozen');
      expect(groceryCategoryLabel(GroceryCategory.bakery), 'Bakery');
      expect(groceryCategoryLabel(GroceryCategory.other), 'Other');
    });
  });
}
