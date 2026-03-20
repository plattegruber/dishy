/// Widget tests for the RecipeCard widget.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/domain/models/recipe.dart' as recipe_model;
import 'package:dishy/domain/models/recipe.dart' hide Step;
import 'package:dishy/presentation/widgets/recipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a test recipe for use in widget tests.
ResolvedRecipe _testRecipe({
  String id = 'recipe-001',
  String title = 'Chocolate Cake',
  int? servings = 8,
  int? timeMinutes = 60,
  String coverAssetId = 'generated_12345',
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
    cover: CoverOutput.generatedCover(assetId: coverAssetId),
    tags: const <String>['dessert'],
  );
}

void main() {
  group('RecipeCard', () {
    testWidgets('shows recipe title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(recipe: _testRecipe()),
            ),
          ),
        ),
      );

      expect(find.text('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('shows time when present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(recipe: _testRecipe(timeMinutes: 45)),
            ),
          ),
        ),
      );

      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('shows servings when present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(recipe: _testRecipe(servings: 4)),
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('hides time when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(recipe: _testRecipe(timeMinutes: null)),
            ),
          ),
        ),
      );

      expect(find.text('min'), findsNothing);
    });

    testWidgets('shows placeholder for generated cover',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(
                recipe: _testRecipe(coverAssetId: 'generated_abc'),
              ),
            ),
          ),
        ),
      );

      // Placeholder should show the initial letter
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('calls onTap callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(
                recipe: _testRecipe(),
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RecipeCard));
      expect(tapped, isTrue);
    });

    testWidgets('renders as a Card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: RecipeCard(recipe: _testRecipe()),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
