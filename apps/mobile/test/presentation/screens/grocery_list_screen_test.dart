/// Widget tests for the grocery list screen.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/providers/recipe_list_provider.dart';
import 'package:dishy/presentation/screens/grocery_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ResolvedRecipe _testRecipe({
  String id = 'recipe-001',
  String title = 'Chocolate Cake',
}) {
  return ResolvedRecipe(
    id: id,
    title: title,
    ingredients: const <ResolvedIngredient>[
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 2,
          unit: 'cups',
          name: 'flour',
        ),
        resolution: IngredientResolution.unmatched(text: 'flour'),
      ),
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 1,
          unit: 'cup',
          name: 'sugar',
        ),
        resolution: IngredientResolution.unmatched(text: 'sugar'),
      ),
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 3,
          name: 'eggs',
        ),
        resolution: IngredientResolution.unmatched(text: 'eggs'),
      ),
    ],
    steps: const <recipe_model.Step>[
      recipe_model.Step(number: 1, instruction: 'Bake'),
    ],
    servings: 8,
    timeMinutes: 60,
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
    cover: const CoverOutput.generatedCover(assetId: 'cover-001'),
    tags: const <String>['dessert'],
  );
}

void main() {
  group('GroceryListScreen', () {
    testWidgets('shows empty state when no recipes exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recipes yet'), findsOneWidget);
    });

    testWidgets('shows recipe selector when recipes exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select Recipes'), findsOneWidget);
      expect(find.text('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('shows no-selection state initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select recipes above'), findsOneWidget);
    });

    testWidgets('shows grocery items after selecting a recipe',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the recipe chip to select it
      await tester.tap(find.text('Chocolate Cake'));
      await tester.pumpAndSettle();

      // Should show ingredient items
      expect(find.textContaining('flour'), findsOneWidget);
      expect(find.textContaining('sugar'), findsOneWidget);
      expect(find.textContaining('eggs'), findsOneWidget);
    });

    testWidgets('shows Grocery List title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Grocery List'), findsOneWidget);
    });

    testWidgets('has Select All button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('items are grouped by category',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: GroceryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select the recipe
      await tester.tap(find.text('Chocolate Cake'));
      await tester.pumpAndSettle();

      // eggs should be in Dairy & Eggs
      expect(find.text('Dairy & Eggs'), findsOneWidget);
      // flour and sugar should be in Pantry
      expect(find.text('Pantry'), findsOneWidget);
    });
  });
}

class _EmptyRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[];
}

class _PopulatedRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[
        _testRecipe(),
      ];
}
