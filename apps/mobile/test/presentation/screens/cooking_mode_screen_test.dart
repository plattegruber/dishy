/// Widget tests for the cooking mode screen.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/screens/cooking_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a test recipe with steps for cooking mode tests.
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
      recipe_model.Step(
        number: 2,
        instruction: 'Mix dry ingredients for 5 minutes',
      ),
      recipe_model.Step(number: 3, instruction: 'Bake for 30 minutes'),
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
      status: NutritionStatus.unavailable,
    ),
    cover: CoverOutput.generatedCover(assetId: 'cover-001'),
    tags: <String>['dessert'],
  );
}

void main() {
  group('CookingModeScreen', () {
    testWidgets('shows recipe title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      expect(find.text('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('shows first step by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Preheat oven to 350F'), findsOneWidget);
    });

    testWidgets('shows step number badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      // The step number "1" appears in the badge
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('has navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('navigates to next step on next tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 3'), findsOneWidget);
    });

    testWidgets('shows Done button on last step',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Navigate to step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('detects timer in step instruction',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      // Navigate to step 2 which has "5 minutes"
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Start 5 min Timer'), findsOneWidget);
    });

    testWidgets('has ingredients checklist button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      // The checklist icon button should be in the app bar
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('opens ingredient checklist bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();

      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('2 cups flour'), findsOneWidget);
      expect(find.text('1 cup sugar'), findsOneWidget);
    });

    testWidgets('has progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      expect(
        find.byType(LinearProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('uses dark theme for high contrast',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeScreen(recipe: _testRecipe()),
        ),
      );

      // The scaffold background should be dark
      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF1A1A1A));
    });
  });
}
