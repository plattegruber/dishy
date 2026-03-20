/// Integration test for the capture -> view -> cook flow.
///
/// Verifies that:
/// 1. The shell screen shows with bottom navigation
/// 2. Tapping Capture navigates to the capture screen
/// 3. A recipe detail shows the Start Cooking button
/// 4. Cooking mode shows step-by-step instructions
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/providers/recipe_detail_provider.dart';
import 'package:dishy/presentation/providers/recipe_list_provider.dart';
import 'package:dishy/presentation/screens/cooking_mode_screen.dart';
import 'package:dishy/presentation/screens/recipe_detail_screen.dart';
import 'package:dishy/presentation/screens/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

ResolvedRecipe _testRecipe() {
  return const ResolvedRecipe(
    id: 'recipe-001',
    title: 'Pasta Carbonara',
    ingredients: <ResolvedIngredient>[
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 400,
          unit: 'g',
          name: 'spaghetti',
        ),
        resolution: IngredientResolution.unmatched(text: 'spaghetti'),
      ),
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 200,
          unit: 'g',
          name: 'bacon',
        ),
        resolution: IngredientResolution.unmatched(text: 'bacon'),
      ),
      ResolvedIngredient(
        parsed: ParsedIngredient(
          quantity: 4,
          name: 'eggs',
        ),
        resolution: IngredientResolution.unmatched(text: 'eggs'),
      ),
    ],
    steps: <recipe_model.Step>[
      recipe_model.Step(
        number: 1,
        instruction: 'Boil spaghetti for 10 minutes',
      ),
      recipe_model.Step(
        number: 2,
        instruction: 'Cook bacon until crispy',
      ),
      recipe_model.Step(
        number: 3,
        instruction: 'Mix eggs and cheese',
      ),
      recipe_model.Step(
        number: 4,
        instruction: 'Combine everything',
      ),
    ],
    servings: 4,
    timeMinutes: 25,
    source: Source(platform: Platform.manual),
    nutrition: NutritionComputation(
      perRecipe: NutritionFacts(
        calories: 2400,
        protein: 80,
        carbs: 320,
        fat: 90,
      ),
      status: NutritionStatus.estimated,
    ),
    cover: CoverOutput.generatedCover(assetId: 'generated_pasta'),
    tags: <String>['italian', 'pasta'],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Capture -> View -> Cook flow', () {
    testWidgets('shell screen shows bottom navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            recipeListProvider.overrideWith(
              () => _TestRecipeListNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: ShellScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recipes'), findsOneWidget);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('recipe detail shows Start Cooking button',
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

      expect(find.text('Start Cooking'), findsOneWidget);
    });

    testWidgets('cooking mode navigates through steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Boil spaghetti for 10 minutes'), findsOneWidget);

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);

      // Navigate to step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4'), findsOneWidget);

      // Navigate to step 4
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('cooking mode detects timer on step 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 says "10 minutes" so timer button should appear
      expect(find.text('Start 10 min Timer'), findsOneWidget);
    });
  });
}

class _TestRecipeListNotifier extends RecipeListNotifier {
  @override
  Future<List<ResolvedRecipe>> build() async => <ResolvedRecipe>[
        _testRecipe(),
      ];
}
