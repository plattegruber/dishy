/// Sealed authentication state classes.
///
/// Represents the four possible states of the authentication lifecycle:
/// loading, authenticated, unauthenticated, and error. Uses sealed
/// classes to enable exhaustive pattern matching in the UI layer.
///
/// No `dynamic` types — every field is strongly typed.
library;

/// Base class for authentication states.
///
/// Sealed to ensure all possible states are defined within this file,
/// enabling exhaustive `switch` expressions in consuming code.
sealed class AuthState {
  /// Creates the base auth state.
  const AuthState();
}

/// Authentication state is being determined.
///
/// Shown while the app initializes Clerk or checks for an existing
/// session token. The UI should display a loading indicator.
final class AuthLoading extends AuthState {
  /// Creates the loading state.
  const AuthLoading();
}

/// User is authenticated with a valid session.
///
/// Contains the Clerk user ID and optional email for display purposes.
/// The session token is managed separately by the auth provider.
final class AuthAuthenticated extends AuthState {
  /// Creates an authenticated state with user details.
  const AuthAuthenticated({
    required this.userId,
    this.email,
  });

  /// Clerk user ID (corresponds to the JWT `sub` claim).
  final String userId;

  /// User's primary email address, if available.
  final String? email;
}

/// User is not authenticated — no valid session exists.
///
/// The UI should show the sign-in screen or redirect via the auth guard.
final class AuthUnauthenticated extends AuthState {
  /// Creates the unauthenticated state.
  const AuthUnauthenticated();
}

/// Authentication encountered an error.
///
/// Contains a human-readable error message for display.
/// The user should be offered a retry option.
final class AuthError extends AuthState {
  /// Creates an error state with a descriptive message.
  const AuthError({required this.message});

  /// Human-readable description of the authentication error.
  final String message;
}
