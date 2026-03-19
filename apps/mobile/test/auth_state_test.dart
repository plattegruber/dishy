import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/auth/auth_state.dart';

void main() {
  group('AuthState', () {
    test('AuthLoading is an AuthState', () {
      const AuthState state = AuthLoading();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthLoading>());
    });

    test('AuthUnauthenticated is an AuthState', () {
      const AuthState state = AuthUnauthenticated();
      expect(state, isA<AuthState>());
      expect(state, isA<AuthUnauthenticated>());
    });

    test('AuthAuthenticated holds user data', () {
      const AuthState state = AuthAuthenticated(
        userId: 'user_abc123',
        sessionToken: 'jwt-token-here',
        email: 'test@example.com',
      );
      expect(state, isA<AuthAuthenticated>());

      const AuthAuthenticated authenticated = state as AuthAuthenticated;
      expect(authenticated.userId, 'user_abc123');
      expect(authenticated.sessionToken, 'jwt-token-here');
      expect(authenticated.email, 'test@example.com');
    });

    test('AuthAuthenticated email is optional', () {
      const AuthState state = AuthAuthenticated(
        userId: 'user_abc123',
        sessionToken: 'jwt-token-here',
      );

      const AuthAuthenticated authenticated = state as AuthAuthenticated;
      expect(authenticated.email, isNull);
    });

    test('AuthError holds error message', () {
      const AuthState state = AuthError(message: 'Something went wrong');
      expect(state, isA<AuthError>());

      const AuthError error = state as AuthError;
      expect(error.message, 'Something went wrong');
    });

    test('sealed class hierarchy is exhaustive', () {
      // Verifies that switch statements can exhaustively match all states.
      const AuthState state = AuthLoading();

      final String result = switch (state) {
        AuthLoading() => 'loading',
        AuthUnauthenticated() => 'unauthenticated',
        AuthAuthenticated() => 'authenticated',
        AuthError() => 'error',
      };

      expect(result, 'loading');
    });
  });
}
