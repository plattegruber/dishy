import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/auth/auth_state.dart';

void main() {
  group('AuthLoading', () {
    test('is an AuthState', () {
      const AuthLoading state = AuthLoading();
      expect(state, isA<AuthState>());
    });

    test('two instances are equal via const', () {
      const AuthLoading a = AuthLoading();
      const AuthLoading b = AuthLoading();
      expect(identical(a, b), isTrue);
    });
  });

  group('AuthAuthenticated', () {
    test('is an AuthState', () {
      const AuthAuthenticated state = AuthAuthenticated(
        userId: 'user_123',
        email: 'test@test.com',
      );
      expect(state, isA<AuthState>());
    });

    test('stores userId', () {
      const AuthAuthenticated state = AuthAuthenticated(userId: 'user_abc');
      expect(state.userId, equals('user_abc'));
    });

    test('stores email', () {
      const AuthAuthenticated state = AuthAuthenticated(
        userId: 'user_abc',
        email: 'hello@world.com',
      );
      expect(state.email, equals('hello@world.com'));
    });

    test('email defaults to null', () {
      const AuthAuthenticated state = AuthAuthenticated(userId: 'user_abc');
      expect(state.email, isNull);
    });
  });

  group('AuthUnauthenticated', () {
    test('is an AuthState', () {
      const AuthUnauthenticated state = AuthUnauthenticated();
      expect(state, isA<AuthState>());
    });

    test('two instances are equal via const', () {
      const AuthUnauthenticated a = AuthUnauthenticated();
      const AuthUnauthenticated b = AuthUnauthenticated();
      expect(identical(a, b), isTrue);
    });
  });

  group('AuthError', () {
    test('is an AuthState', () {
      const AuthError state = AuthError(message: 'something failed');
      expect(state, isA<AuthState>());
    });

    test('stores message', () {
      const AuthError state = AuthError(message: 'network error');
      expect(state.message, equals('network error'));
    });
  });

  group('Exhaustive pattern matching', () {
    test('switch covers all cases', () {
      // This test ensures the sealed class hierarchy is exhaustive.
      final List<AuthState> states = <AuthState>[
        const AuthLoading(),
        const AuthAuthenticated(userId: 'u'),
        const AuthUnauthenticated(),
        const AuthError(message: 'e'),
      ];

      for (final AuthState state in states) {
        final String label = switch (state) {
          AuthLoading() => 'loading',
          AuthAuthenticated() => 'authenticated',
          AuthUnauthenticated() => 'unauthenticated',
          AuthError() => 'error',
        };
        expect(label, isNotEmpty);
      }
    });
  });
}
