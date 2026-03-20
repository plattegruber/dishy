/// Widget tests for the NutritionCard widget.
library;

import 'package:dishy/domain/models/nutrition.dart';
import 'package:dishy/presentation/widgets/nutrition_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NutritionCard', () {
    testWidgets('shows calculated status badge when calculated',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2500,
          protein: 80,
          carbs: 300,
          fat: 100,
        ),
        status: NutritionStatus.calculated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition),
          ),
        ),
      );

      expect(find.text('Nutrition Facts'), findsOneWidget);
      expect(find.text('Calculated'), findsOneWidget);
    });

    testWidgets('shows macro values for calculated nutrition',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2500,
          protein: 80,
          carbs: 300,
          fat: 100,
        ),
        status: NutritionStatus.calculated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition),
          ),
        ),
      );

      expect(find.text('2500'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
    });

    testWidgets('shows estimated badge and note when estimated',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 1500,
          protein: 50,
          carbs: 200,
          fat: 60,
        ),
        status: NutritionStatus.estimated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition),
          ),
        ),
      );

      expect(find.text('Estimated'), findsOneWidget);
      expect(find.textContaining('estimated'), findsWidgets);
    });

    testWidgets('shows unavailable message when unavailable',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
        status: NutritionStatus.unavailable,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition),
          ),
        ),
      );

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.textContaining('not yet available'), findsOneWidget);
    });

    testWidgets('shows per-serving toggle when servings provided',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2000,
          protein: 60,
          carbs: 250,
          fat: 80,
        ),
        perServing: NutritionFacts(
          calories: 500,
          protein: 15,
          carbs: 62.5,
          fat: 20,
        ),
        status: NutritionStatus.calculated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition, servings: 4),
          ),
        ),
      );

      expect(find.text('Per recipe'), findsOneWidget);
      expect(find.textContaining('Per serving'), findsOneWidget);
    });

    testWidgets('toggles to per-serving values', (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2000,
          protein: 60,
          carbs: 250,
          fat: 80,
        ),
        perServing: NutritionFacts(
          calories: 500,
          protein: 15,
          carbs: 62.5,
          fat: 20,
        ),
        status: NutritionStatus.calculated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition, servings: 4),
          ),
        ),
      );

      // Initially shows per-recipe values
      expect(find.text('2000'), findsOneWidget);

      // Tap per-serving toggle
      await tester.tap(find.textContaining('Per serving'));
      await tester.pumpAndSettle();

      // Now shows per-serving values
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('does not show toggle without servings',
        (WidgetTester tester) async {
      const NutritionComputation nutrition = NutritionComputation(
        perRecipe: NutritionFacts(
          calories: 2000,
          protein: 60,
          carbs: 250,
          fat: 80,
        ),
        status: NutritionStatus.calculated,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NutritionCard(nutrition: nutrition),
          ),
        ),
      );

      expect(find.text('Per recipe'), findsNothing);
      expect(find.textContaining('Per serving'), findsNothing);
    });
  });
}
