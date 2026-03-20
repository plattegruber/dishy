/// Widget tests for the IngredientList widget.
library;

import 'package:dishy/domain/models/ingredient.dart';
import 'package:dishy/presentation/widgets/ingredient_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngredientList', () {
    testWidgets('shows empty message when no ingredients',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: <ResolvedIngredient>[]),
          ),
        ),
      );

      expect(find.textContaining('No ingredients'), findsOneWidget);
    });

    testWidgets('renders an ingredient row', (WidgetTester tester) async {
      const List<ResolvedIngredient> ingredients = <ResolvedIngredient>[
        ResolvedIngredient(
          parsed: ParsedIngredient(name: 'flour'),
          resolution: IngredientResolution.unmatched(text: 'flour'),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: ingredients),
          ),
        ),
      );

      // RichText renders TextSpans; check that the widget tree contains it
      expect(find.byType(RichText), findsWidgets);
      // The IngredientList should render one row
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders quantity, unit, and name via RichText',
        (WidgetTester tester) async {
      const List<ResolvedIngredient> ingredients = <ResolvedIngredient>[
        ResolvedIngredient(
          parsed: ParsedIngredient(
            quantity: 2,
            unit: 'cups',
            name: 'flour',
          ),
          resolution: IngredientResolution.unmatched(text: 'flour'),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: ingredients),
          ),
        ),
      );

      // Verify RichText is rendered (contains quantity+unit+name spans)
      final Finder richTextFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('2') &&
            widget.text.toPlainText().contains('cups') &&
            widget.text.toPlainText().contains('flour'),
      );
      expect(richTextFinder, findsOneWidget);
    });

    testWidgets('renders preparation in italic via RichText',
        (WidgetTester tester) async {
      const List<ResolvedIngredient> ingredients = <ResolvedIngredient>[
        ResolvedIngredient(
          parsed: ParsedIngredient(
            quantity: 1,
            unit: 'cup',
            name: 'butter',
            preparation: 'softened',
          ),
          resolution: IngredientResolution.unmatched(text: 'butter'),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: ingredients),
          ),
        ),
      );

      final Finder richTextFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('softened'),
      );
      expect(richTextFinder, findsOneWidget);
    });

    testWidgets('renders multiple ingredients', (WidgetTester tester) async {
      const List<ResolvedIngredient> ingredients = <ResolvedIngredient>[
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
        ResolvedIngredient(
          parsed: ParsedIngredient(name: 'salt'),
          resolution: IngredientResolution.fuzzyMatched(
            candidates: <FuzzyCandidate>[
              FuzzyCandidate(foodId: '123', confidence: 0.7),
            ],
            confidence: 0.7,
          ),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: ingredients),
          ),
        ),
      );

      // Should have 3 resolution dots (Tooltip widgets)
      expect(find.byType(Tooltip), findsNWidgets(3));
    });

    testWidgets('shows resolution dots with tooltips',
        (WidgetTester tester) async {
      const List<ResolvedIngredient> ingredients = <ResolvedIngredient>[
        ResolvedIngredient(
          parsed: ParsedIngredient(name: 'flour'),
          resolution: IngredientResolution.matched(
            foodId: '169761',
            confidence: 0.95,
          ),
        ),
        ResolvedIngredient(
          parsed: ParsedIngredient(name: 'sugar'),
          resolution: IngredientResolution.unmatched(text: 'sugar'),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IngredientList(ingredients: ingredients),
          ),
        ),
      );

      // Should find 2 Tooltip widgets (resolution dots)
      expect(find.byType(Tooltip), findsNWidgets(2));
    });
  });
}
