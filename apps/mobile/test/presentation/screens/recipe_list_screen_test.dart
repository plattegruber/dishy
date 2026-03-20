/// Widget tests for the recipe list screen.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/providers/recipe_list_provider.dart';
import 'package:dishy/presentation/screens/recipe_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a test recipe for use in widget tests.
ResolvedRecipe _testRecipe({
  String id = 'recipe-001',
  String title = 'Chocolate Cake',
  int? servings = 8,
  int? timeMinutes = 60,
}) {
  return ResolvedRecipe(
    id: id,
    title: title,
    ingredients: const <ResolvedIngredient>[
      ResolvedIngredient(
        parsed: ParsedIngredient(name: 'flour'),
        resolution: IngredientResolution.unmatched(text: 'flour'),
      ),
    ],
    steps: const <recipe_model.Step>[
      recipe_model.Step(number: 1, instruction: 'Bake'),
    ],
    servings: servings,
    timeMinutes: timeMinutes,
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
  group('RecipeListScreen', () {
    testWidgets('shows empty state when no recipes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: RecipeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recipes yet'), findsOneWidget);
      expect(find.text('Tap + to capture your first recipe'), findsOneWidget);
    });

    testWidgets('shows recipe cards when recipes exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _PopulatedRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: RecipeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chocolate Cake'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
    });

    testWidgets('has a FAB for capturing new recipes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: RecipeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows app title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _EmptyRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: RecipeListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dishy'), findsOneWidget);
    });
  });
}

/// A notifier that returns an empty list.
class _EmptyRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[];
}

/// A notifier that returns a list with one recipe.
class _PopulatedRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[
        _testRecipe(),
      ];
}

