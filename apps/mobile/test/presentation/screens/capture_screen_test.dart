/// Widget tests for the capture screen.
library;

import 'package:dishy/presentation/screens/capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptureScreen', () {
    testWidgets('renders tab bar with three tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      expect(find.text('Capture Recipe'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
    });

    testWidgets('text tab shows text field and save button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      // Text tab is default (index 0)
      expect(find.text('Paste or type your recipe below'), findsOneWidget);
      expect(find.text('Save Recipe'), findsOneWidget);
    });

    testWidgets('text tab save button is enabled when idle',
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

      final FilledButton filledButton = tester.widget<FilledButton>(button);
      expect(filledButton.onPressed, isNotNull);
    });

    testWidgets('text tab shows hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      expect(find.textContaining('Chocolate Cake'), findsOneWidget);
    });

    testWidgets('link tab shows URL input after tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      // Tap the Link tab
      await tester.tap(find.text('Link'));
      await tester.pumpAndSettle();

      expect(
        find.text('Paste a recipe URL from social media'),
        findsOneWidget,
      );
      expect(find.text('Extract Recipe'), findsOneWidget);
    });

    testWidgets('photo tab shows camera and gallery buttons after tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CaptureScreen(),
          ),
        ),
      );

      // Tap the Photo tab
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      expect(
        find.text('Take a photo or pick a screenshot'),
        findsOneWidget,
      );
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });
}
