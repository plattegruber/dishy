/// Immutable authentication state model.
///
/// Represents the current authentication status of the user.
/// Used by [authProvider] to expose auth state throughout the widget tree.
library;

/// The current authentication state of the user.
///
/// Modelled as a sealed class hierarchy to ensure exhaustive matching.
/// No `dynamic` types are used — all fields are strongly typed.
sealed class AuthState {
  /// Creates an [AuthState].
  const AuthState();
}

/// The auth system is still initializing (e.g. restoring a saved session).
class AuthLoading extends AuthState {
  /// Creates the loading state.
  const AuthLoading();
}

/// The user is not authenticated.
class AuthUnauthenticated extends AuthState {
  /// Creates the unauthenticated state.
  const AuthUnauthenticated();
}

/// The user is authenticated with a valid session.
class AuthAuthenticated extends AuthState {
  /// Creates the authenticated state with user details.
  const AuthAuthenticated({
    required this.userId,
    required this.sessionToken,
    this.email,
  });

  /// The Clerk user ID (e.g. `user_xxx`).
  final String userId;

  /// The current session JWT used to authenticate API requests.
  final String sessionToken;

  /// The user's primary email address, if available.
  final String? email;
}

/// Authentication failed with an error.
class AuthError extends AuthState {
  /// Creates the error state.
  const AuthError({required this.message});

  /// Human-readable error message describing what went wrong.
  final String message;
}
