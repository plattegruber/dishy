/// Widget tests for the recipe detail screen.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/providers/recipe_detail_provider.dart';
import 'package:dishy/presentation/screens/recipe_detail_screen.dart';
import 'package:dishy/presentation/widgets/nutrition_card.dart';
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
        resolution: IngredientResolution.matched(
          foodId: '169761',
          confidence: 0.95,
        ),
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
        calories: 3200,
        protein: 40,
        carbs: 450,
        fat: 140,
      ),
      perServing: NutritionFacts(
        calories: 400,
        protein: 5,
        carbs: 56.25,
        fat: 17.5,
      ),
      status: NutritionStatus.estimated,
    ),
    cover: CoverOutput.generatedCover(assetId: 'cover-001'),
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

      expect(find.text('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('shows ingredients with checkboxes',
        (WidgetTester tester) async {
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
      // Checkboxes for ingredients
      expect(find.byType(Checkbox), findsAtLeast(2));
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

    testWidgets('shows NutritionCard widget', (WidgetTester tester) async {
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
      expect(find.byType(NutritionCard), findsOneWidget);
      expect(find.text('Nutrition Facts'), findsOneWidget);
      expect(find.text('Estimated'), findsOneWidget);
    });

    testWidgets('shows Start Cooking button', (WidgetTester tester) async {
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

      expect(find.text('Start Cooking'), findsOneWidget);
    });

    testWidgets('shows favorite button in app bar',
        (WidgetTester tester) async {
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

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('shows share button in app bar',
        (WidgetTester tester) async {
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

      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}
