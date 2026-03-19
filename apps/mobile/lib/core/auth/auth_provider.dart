/// Riverpod providers for authentication state.
///
/// Wraps the Clerk `Auth` SDK to expose reactive authentication state
/// throughout the app. Handles initialization, sign-in, sign-out, and
/// session token access.
library;

import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';

/// Riverpod provider that exposes the current [AuthState].
///
/// The provider initializes the Clerk SDK on first read and keeps
/// the auth state up to date as the user signs in or out.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authProvider);
/// ```
final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (Ref ref) => AuthNotifier(),
);

/// State notifier managing authentication lifecycle.
///
/// Wraps the Clerk [Auth] client and translates SDK events into
/// strongly-typed [AuthState] values. Handles initialization,
/// credential-based sign-in, and sign-out.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates the notifier in [AuthLoading] state.
  AuthNotifier() : super(const AuthLoading());

  clerk.Auth? _auth;
  StreamSubscription<clerk.SessionToken>? _tokenSubscription;

  /// Initialize the Clerk SDK with the given publishable key.
  ///
  /// Must be called before any sign-in or sign-out operations.
  /// Typically invoked during app startup.
  Future<void> initialize(String publishableKey) async {
    try {
      _auth = clerk.Auth(
        config: clerk.AuthConfig(
          publishableKey: publishableKey,
          persistor: clerk.Persistor.none,
        ),
      );

      await _auth?.initialize();

      // Listen for session token changes to keep auth state in sync.
      _tokenSubscription = _auth?.sessionTokenStream.listen(
        _onSessionTokenChanged,
      );

      // Check if user is already signed in from a persisted session.
      final clerk.User? user = _auth?.user;
      if (user != null) {
        // Try to get a session token for the authenticated user.
        final String? jwt = await _fetchCurrentJwt();
        if (jwt != null && jwt.isNotEmpty) {
          state = AuthAuthenticated(
            userId: user.id,
            sessionToken: jwt,
            email: user.email,
          );
          return;
        }
      }

      state = const AuthUnauthenticated();
    } on Exception catch (e) {
      state = AuthError(message: 'Failed to initialize auth: $e');
    }
  }

  /// Sign in with email and password credentials.
  ///
  /// Updates the auth state to [AuthAuthenticated] on success,
  /// or [AuthError] on failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final clerk.Auth? auth = _auth;
    if (auth == null) {
      state = const AuthError(message: 'Auth not initialized');
      return;
    }

    state = const AuthLoading();

    try {
      await auth.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      );

      final clerk.User? user = auth.user;
      final String? jwt = await _fetchCurrentJwt();

      if (user != null && jwt != null && jwt.isNotEmpty) {
        state = AuthAuthenticated(
          userId: user.id,
          sessionToken: jwt,
          email: user.email,
        );
      } else {
        state = const AuthError(message: 'Sign-in succeeded but no session created');
      }
    } on Exception catch (e) {
      state = AuthError(message: 'Sign-in failed: $e');
    }
  }

  /// Sign out the current user.
  ///
  /// Clears the session and sets the state to [AuthUnauthenticated].
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } on Exception catch (_) {
      // Even if the sign-out request fails, clear local state.
    }
    state = const AuthUnauthenticated();
  }

  /// Returns the current session token, or `null` if not authenticated.
  ///
  /// Used by the API client interceptor to attach the Bearer token.
  String? get currentToken {
    final AuthState current = state;
    if (current is AuthAuthenticated) {
      return current.sessionToken;
    }
    return null;
  }

  Future<String?> _fetchCurrentJwt() async {
    try {
      final clerk.SessionToken token = await _auth!.sessionToken();
      return token.jwt;
    } on Exception catch (_) {
      return null;
    }
  }

  void _onSessionTokenChanged(clerk.SessionToken sessionToken) {
    final String jwt = sessionToken.jwt;
    if (jwt.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }

    final clerk.User? user = _auth?.user;
    if (user != null) {
      state = AuthAuthenticated(
        userId: user.id,
        sessionToken: jwt,
        email: user.email,
      );
    }
  }

  @override
  void dispose() {
    _tokenSubscription?.cancel();
    _auth?.terminate();
    super.dispose();
  }
}
