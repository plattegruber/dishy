/// Widget tests for the recipe detail screen.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/providers/recipe_detail_provider.dart';
import 'package:dishy/presentation/screens/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a test recipe for use in widget tests.
ResolvedRecipe _testRecipe() {
  return const ResolvedRecipe(
    id: 'recipe-001',
    title: 'Chocolate Cake',
    ingredients: <ResolvedIngredient>[
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
    ],
    steps: <recipe_model.Step>[
      recipe_model.Step(number: 1, instruction: 'Preheat oven to 350F'),
      recipe_model.Step(number: 2, instruction: 'Mix dry ingredients'),
    ],
    servings: 8,
    timeMinutes: 60,
    source: Source(platform: Platform.manual),
    nutrition: NutritionComputation(
      perRecipe: NutritionFacts(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      ),
      status: NutritionStatus.unavailable,
    ),
    cover: CoverOutput.generatedCover(assetId: 'generated_cover-001'),
    tags: <String>['dessert', 'baking'],
  );
}

void main() {
  group('RecipeDetailScreen', () {
    testWidgets('shows recipe title', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title appears in both app bar and hero cover placeholder.
      expect(find.text('Chocolate Cake'), findsWidgets);
    });

    testWidgets('shows ingredients', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.textContaining('flour'), findsOneWidget);
      expect(find.textContaining('sugar'), findsOneWidget);
    });

    testWidgets('shows steps', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Preheat oven to 350F'), findsOneWidget);
      expect(find.text('Mix dry ingredients'), findsOneWidget);
    });

    testWidgets('shows metadata', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('8 servings'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
    });

    testWidgets('shows tags', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('dessert'), findsOneWidget);
      expect(find.text('baking'), findsOneWidget);
    });

    testWidgets('shows nutrition section', (WidgetTester tester) async {
      final ResolvedRecipe recipe = _testRecipe();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeDetailProvider('recipe-001')
                .overrideWith((Ref ref) async => recipe),
          ],
          child: const MaterialApp(
            home: RecipeDetailScreen(recipeId: 'recipe-001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nutrition'), findsOneWidget);
    });
  });
}
