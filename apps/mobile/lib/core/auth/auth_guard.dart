/// GoRouter redirect guard for authentication.
///
/// Redirects unauthenticated users to the sign-in screen and prevents
/// authenticated users from accessing the sign-in screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import 'auth_state.dart';

/// Route path for the sign-in screen.
const String signInPath = '/sign-in';

/// GoRouter redirect function that enforces authentication.
///
/// Must be called with a [WidgetRef] to read the current [AuthState].
/// Returns `null` if no redirect is needed, or a path string to redirect to.
///
/// Behaviour:
/// - If auth is still loading, no redirect (allow current page to show).
/// - If unauthenticated and not on sign-in page, redirect to `/sign-in`.
/// - If authenticated and on sign-in page, redirect to `/`.
/// - Otherwise, no redirect.
String? authGuardRedirect(WidgetRef ref, BuildContext context, GoRouterState state) {
  final AuthState authState = ref.read(authProvider);
  final bool isOnSignIn = state.matchedLocation == signInPath;

  // While loading, don't redirect — let the current page render.
  if (authState is AuthLoading) {
    return null;
  }

  // Unauthenticated (or error): send to sign-in unless already there.
  if (authState is AuthUnauthenticated || authState is AuthError) {
    return isOnSignIn ? null : signInPath;
  }

  // Authenticated: redirect away from sign-in to home.
  if (authState is AuthAuthenticated && isOnSignIn) {
    return '/';
  }

  return null;
}
