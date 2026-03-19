/// GoRouter redirect guard for authenticated routes.
///
/// Checks the current [AuthState] and redirects unauthenticated users
/// to the sign-in screen. Loading states are allowed through so the
/// app can show a splash/loading indicator while auth initialises.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import 'auth_state.dart';

/// Route path for the sign-in screen.
const String signInPath = '/sign-in';

/// Route path for the home screen.
const String homePath = '/';

/// GoRouter redirect function that enforces authentication.
///
/// Returns the sign-in path if the user is unauthenticated or in an
/// error state and is not already navigating to the sign-in screen.
/// Returns `null` (no redirect) for authenticated and loading states.
///
/// Usage with GoRouter:
/// ```dart
/// GoRouter(
///   redirect: authGuard(ref),
///   routes: [...],
/// )
/// ```
GoRouterRedirect authGuard(Ref ref) {
  return (BuildContext context, GoRouterState routerState) {
    final AuthState authState = ref.read(authProvider);
    final bool isOnSignIn = routerState.matchedLocation == signInPath;

    switch (authState) {
      case AuthLoading():
        // Allow through — the app is still initialising.
        return null;

      case AuthAuthenticated():
        // If authenticated and on sign-in, redirect to home.
        if (isOnSignIn) {
          return homePath;
        }
        return null;

      case AuthUnauthenticated():
      case AuthError():
        // Redirect to sign-in if not already there.
        if (!isOnSignIn) {
          return signInPath;
        }
        return null;
    }
  };
}
