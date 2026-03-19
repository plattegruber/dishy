/// Root application widget with Material theming and GoRouter navigation.
///
/// Includes authentication guard that redirects unauthenticated users
/// to the sign-in screen. The router listens to [authProvider] changes
/// to trigger re-evaluation of the redirect logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_guard.dart';
import 'core/auth/auth_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/sign_in_screen.dart';

/// Top-level router configuration.
///
/// Defines all application routes including the sign-in flow.
/// The [redirect] callback enforces authentication on protected routes
/// while keeping the sign-in screen accessible to unauthenticated users.
GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    redirect: (BuildContext context, GoRouterState state) {
      return authGuardRedirect(ref, context, state);
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: signInPath,
        builder: (BuildContext context, GoRouterState state) {
          return const SignInScreen();
        },
      ),
    ],
  );
}

/// Root widget for the Dishy application.
///
/// Sets up [MaterialApp.router] with the GoRouter instance and the
/// application theme. This widget sits directly under [ProviderScope]
/// in the widget tree. Uses [ConsumerWidget] to access the auth state
/// for router redirect decisions.
class DishyApp extends ConsumerWidget {
  /// Creates the root application widget.
  const DishyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state so router redirect re-evaluates on auth changes.
    ref.watch(authProvider);
    final GoRouter router = createRouter(ref);

    return MaterialApp.router(
      title: 'Dishy',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
