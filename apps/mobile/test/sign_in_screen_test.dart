import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/auth/auth_provider.dart';
import 'package:dishy/core/auth/auth_state.dart';
import 'package:dishy/presentation/screens/sign_in_screen.dart';

/// A test-only [AuthNotifier] that starts in [AuthUnauthenticated] state
/// without touching the Clerk SDK (avoids timer/network side effects).
class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super() {
    state = const AuthUnauthenticated();
  }
}

void main() {
  group('SignInScreen', () {
    Widget buildTestWidget() {
      return ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(
            (Ref ref) => _TestAuthNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      );
    }

    testWidgets('displays email and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays sign in button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('displays welcome text', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Welcome to Dishy'), findsOneWidget);
      expect(find.text('Sign in to access your recipes'), findsOneWidget);
    });

    testWidgets('validates empty email on submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap sign in without entering anything.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('validates invalid email on submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter email without @ sign.
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('validates empty password on submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter valid email but leave password empty.
      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('has password visibility toggle icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // The visibility off icon should be present (password obscured by default).
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('displays the restaurant icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
