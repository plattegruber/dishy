/// Widget tests for the capture screen.
library;

import 'package:dishy/presentation/screens/capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptureScreen', () {
    testWidgets('renders text field and submit button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      expect(find.text('Capture Recipe'), findsOneWidget);
      expect(find.text('Save Recipe'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('submit button is enabled when idle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      final Finder button = find.widgetWithText(FilledButton, 'Save Recipe');
      expect(button, findsOneWidget);

      final FilledButton filledButton =
          tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('shows hint text in text field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      expect(find.textContaining('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('shows instruction text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      expect(
          find.text('Paste or type your recipe below'), findsOneWidget);
    });
  });
}
