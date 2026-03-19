import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dishy/core/auth/auth_guard.dart';
import 'package:dishy/core/auth/auth_provider.dart';
import 'package:dishy/core/auth/auth_state.dart';

void main() {
  group('Auth guard constants', () {
    test('signInPath is /sign-in', () {
      expect(signInPath, equals('/sign-in'));
    });

    test('homePath is /', () {
      expect(homePath, equals('/'));
    });
  });

  group('Auth guard redirect logic', () {
    testWidgets('unauthenticated user sees sign-in screen',
        (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      // Set state to unauthenticated
      container.read(authProvider.notifier).setUnauthenticated();

      final GoRouter router = GoRouter(
        redirect: (BuildContext context, GoRouterState state) {
          final AuthState authState = container.read(authProvider);
          final bool isOnSignIn = state.matchedLocation == signInPath;

          switch (authState) {
            case AuthLoading():
              return null;
            case AuthAuthenticated():
              return isOnSignIn ? homePath : null;
            case AuthUnauthenticated():
            case AuthError():
              return isOnSignIn ? null : signInPath;
          }
        },
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: signInPath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Sign In')),
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

      // Should be redirected to sign-in
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('authenticated user sees home screen',
        (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      // Set state to authenticated
      container
          .read(authProvider.notifier)
          .setAuthenticated(userId: 'user_123');

      final GoRouter router = GoRouter(
        redirect: (BuildContext context, GoRouterState state) {
          final AuthState authState = container.read(authProvider);
          final bool isOnSignIn = state.matchedLocation == signInPath;

          switch (authState) {
            case AuthLoading():
              return null;
            case AuthAuthenticated():
              return isOnSignIn ? homePath : null;
            case AuthUnauthenticated():
            case AuthError():
              return isOnSignIn ? null : signInPath;
          }
        },
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: signInPath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Sign In')),
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

      // Should stay on home
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('loading state shows home (no redirect)',
        (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      // AuthLoading is the initial state — do not change it.

      final GoRouter router = GoRouter(
        redirect: (BuildContext context, GoRouterState state) {
          final AuthState authState = container.read(authProvider);
          final bool isOnSignIn = state.matchedLocation == signInPath;

          switch (authState) {
            case AuthLoading():
              return null;
            case AuthAuthenticated():
              return isOnSignIn ? homePath : null;
            case AuthUnauthenticated():
            case AuthError():
              return isOnSignIn ? null : signInPath;
          }
        },
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: signInPath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Sign In')),
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

      // Should show home (loading passes through)
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('error state redirects to sign-in',
        (WidgetTester tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(authProvider.notifier).setError('Token expired');

      final GoRouter router = GoRouter(
        redirect: (BuildContext context, GoRouterState state) {
          final AuthState authState = container.read(authProvider);
          final bool isOnSignIn = state.matchedLocation == signInPath;

          switch (authState) {
            case AuthLoading():
              return null;
            case AuthAuthenticated():
              return isOnSignIn ? homePath : null;
            case AuthUnauthenticated():
            case AuthError():
              return isOnSignIn ? null : signInPath;
          }
        },
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: signInPath,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Sign In')),
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

      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
