/// Riverpod provider for authentication state management.
///
/// Wraps the Clerk Flutter SDK to expose a reactive [AuthState] stream.
/// Handles sign-in, sign-out, and session token management. The
/// [authProvider] is the single source of truth for whether the current
/// user is authenticated.
library;

import 'package:clerk_flutter/clerk_flutter.dart' as clerk;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/correlation_provider.dart';
import '../logging/log_service.dart';
import 'auth_state.dart';

/// Publishable key for Clerk, passed via `--dart-define`.
///
/// Must be set at build time:
/// ```
/// flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_...
/// ```
const String _clerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
);

/// Provides the Clerk [clerk.ClerkAuth] widget configuration.
///
/// Returns the publishable key so the [clerk.ClerkAuth] widget at the
/// root of the widget tree can initialise the SDK.
final Provider<String> clerkPublishableKeyProvider = Provider<String>(
  (Ref ref) => _clerkPublishableKey,
);

/// StateNotifier that manages authentication state transitions.
///
/// Wraps Clerk SDK calls in structured logging and maps outcomes to
/// the sealed [AuthState] hierarchy. All sign-in/sign-out operations
/// log through the shared [LogService] for observability.
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates the notifier with the given [LogService].
  AuthNotifier({required LogService logService})
      : _logService = logService,
        super(const AuthLoading());

  final LogService _logService;

  /// The current session token, if available.
  ///
  /// Updated after successful authentication. Cleared on sign-out.
  /// Used by the auth interceptor to attach Bearer tokens to API
  /// requests.
  String? _sessionToken;

  /// Returns the current session token, or `null` if unauthenticated.
  String? get sessionToken => _sessionToken;

  /// Marks the user as authenticated with the given details.
  ///
  /// Called by the [clerk.ClerkAuthBuilder] when Clerk reports a
  /// signed-in state. Updates the auth state and stores the session
  /// token for API requests.
  void setAuthenticated({
    required String userId,
    String? email,
    String? sessionToken,
  }) {
    _sessionToken = sessionToken;
    state = AuthAuthenticated(userId: userId, email: email);
    _logService.info(
      'User authenticated',
      context: <String, Object>{'user_id': userId},
    );
  }

  /// Marks the user as unauthenticated.
  ///
  /// Called when Clerk reports no active session or after a successful
  /// sign-out.
  void setUnauthenticated() {
    _sessionToken = null;
    state = const AuthUnauthenticated();
    _logService.info('User unauthenticated');
  }

  /// Records an authentication error.
  ///
  /// Sets the state to [AuthError] with the given message so the UI
  /// can display an error and offer a retry option.
  void setError(String message) {
    _sessionToken = null;
    state = AuthError(message: message);
    _logService.error(
      'Authentication error',
      context: <String, Object>{'error': message},
    );
  }

  /// Sets the state to loading.
  ///
  /// Used during asynchronous operations like sign-in or token refresh.
  void setLoading() {
    state = const AuthLoading();
  }

  /// Updates the stored session token.
  ///
  /// Called when Clerk refreshes the token. Does not change the
  /// auth state — only updates the token for subsequent API calls.
  void updateSessionToken(String? token) {
    _sessionToken = token;
  }
}

/// Provides the [AuthNotifier] for the entire application.
///
/// Inject this provider into any widget or service that needs to read
/// or modify the current authentication state.
final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (Ref ref) {
    final LogService logService = ref.watch(logServiceProvider);
    return AuthNotifier(logService: logService);
  },
);
