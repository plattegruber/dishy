import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dishy/core/auth/auth_guard.dart';
import 'package:dishy/core/auth/auth_provider.dart';
import 'package:dishy/core/auth/auth_state.dart';

void main() {
  group('auth guard', () {
    testWidgets('redirects to sign-in when unauthenticated',
        (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      // Force the auth state to unauthenticated.
      await container.read(authProvider.notifier).signOut();
      await tester.pump();

      final GoRouter router = GoRouter(
        redirect: (BuildContext context, GoRouterState state) {
          final AuthState authState = container.read(authProvider);
          final bool isOnSignIn = state.matchedLocation == signInPath;
          if (authState is AuthUnauthenticated || authState is AuthError) {
            return isOnSignIn ? null : signInPath;
          }
          if (authState is AuthAuthenticated && isOnSignIn) {
            return '/';
          }
          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(body: Text('Home'));
            },
          ),
          GoRoute(
            path: signInPath,
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(body: Text('Sign In'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Should have been redirected to sign-in.
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    test('signInPath constant is /sign-in', () {
      expect(signInPath, '/sign-in');
    });
  });
}
