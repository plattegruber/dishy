/// Root application widget with Material 3 theming and GoRouter navigation.
///
/// Configures the [GoRouter] with an authentication guard that redirects
/// unauthenticated users to the sign-in screen. The router is rebuilt
/// whenever the auth state changes via a Riverpod [refreshListenable].
///
/// Routes:
/// - `/` -- shell screen with bottom navigation (recipes, grocery, profile)
/// - `/capture` -- capture screen
/// - `/recipes/:id` -- recipe detail
/// - `/sign-in` -- sign-in screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_guard.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_state.dart';
import 'presentation/screens/capture_screen.dart';
import 'presentation/screens/recipe_detail_screen.dart';
import 'presentation/screens/shell_screen.dart';
import 'presentation/screens/sign_in_screen.dart';

/// Provides the [GoRouter] instance configured with auth-aware routing.
///
/// The router watches [authProvider] and re-evaluates redirects whenever
/// the authentication state changes.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  // Create a listenable that triggers router refresh on auth changes.
  final GoRouterRefreshNotifier refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    refreshListenable: refreshNotifier,
    redirect: authGuard(ref),
    routes: <RouteBase>[
      GoRoute(
        path: homePath,
        builder: (BuildContext context, GoRouterState state) {
          return const ShellScreen();
        },
      ),
      GoRoute(
        path: '/capture',
        builder: (BuildContext context, GoRouterState state) {
          return const CaptureScreen();
        },
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (BuildContext context, GoRouterState state) {
          final String recipeId = state.pathParameters['id'] ?? '';
          return RecipeDetailScreen(recipeId: recipeId);
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
});

/// A [ChangeNotifier] that fires whenever the [AuthState] changes.
///
/// Used as [GoRouter.refreshListenable] so the router re-evaluates
/// its redirect logic whenever the user signs in or out.
class GoRouterRefreshNotifier extends ChangeNotifier {
  /// Creates the notifier and starts listening to auth state changes.
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (AuthState? previous, AuthState next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Root widget for the Dishy application.
///
/// Sets up [MaterialApp.router] with the GoRouter instance (which
/// includes the auth guard) and a warm Material 3 theme designed
/// for a food/cooking app.
class DishyApp extends ConsumerWidget {
  /// Creates the root application widget.
  const DishyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Dishy',
      theme: _buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  /// Builds the Material 3 theme with a warm food/cooking color palette.
  static ThemeData _buildTheme() {
    return ThemeData(
      colorSchemeSeed: Colors.deepOrange,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorShape: StadiumBorder(),
      ),
    );
  }
}
