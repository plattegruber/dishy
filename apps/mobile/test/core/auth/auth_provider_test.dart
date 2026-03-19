import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/auth/auth_provider.dart';
import 'package:dishy/core/auth/auth_state.dart';
import 'package:dishy/core/logging/log_service.dart';

void main() {
  group('AuthNotifier', () {
    late AuthNotifier notifier;

    setUp(() {
      final LogService logService = LogService(sessionId: 'test-session');
      notifier = AuthNotifier(logService: logService);
    });

    test('initial state is AuthLoading', () {
      expect(notifier.state, isA<AuthLoading>());
    });

    test('sessionToken is initially null', () {
      expect(notifier.sessionToken, isNull);
    });

    test('setAuthenticated transitions to AuthAuthenticated', () {
      notifier.setAuthenticated(
        userId: 'user_123',
        email: 'test@test.com',
        sessionToken: 'token-abc',
      );

      expect(notifier.state, isA<AuthAuthenticated>());
      final AuthAuthenticated state = notifier.state as AuthAuthenticated;
      expect(state.userId, equals('user_123'));
      expect(state.email, equals('test@test.com'));
    });

    test('setAuthenticated stores the session token', () {
      notifier.setAuthenticated(
        userId: 'user_123',
        sessionToken: 'my-token',
      );

      expect(notifier.sessionToken, equals('my-token'));
    });

    test('setUnauthenticated transitions to AuthUnauthenticated', () {
      // First authenticate
      notifier.setAuthenticated(
        userId: 'user_123',
        sessionToken: 'token',
      );
      expect(notifier.state, isA<AuthAuthenticated>());

      // Then sign out
      notifier.setUnauthenticated();
      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    test('setUnauthenticated clears the session token', () {
      notifier.setAuthenticated(
        userId: 'user_123',
        sessionToken: 'token',
      );
      expect(notifier.sessionToken, equals('token'));

      notifier.setUnauthenticated();
      expect(notifier.sessionToken, isNull);
    });

    test('setError transitions to AuthError', () {
      notifier.setError('something went wrong');

      expect(notifier.state, isA<AuthError>());
      final AuthError state = notifier.state as AuthError;
      expect(state.message, equals('something went wrong'));
    });

    test('setError clears the session token', () {
      notifier.setAuthenticated(
        userId: 'user_123',
        sessionToken: 'token',
      );

      notifier.setError('failed');
      expect(notifier.sessionToken, isNull);
    });

    test('setLoading transitions to AuthLoading', () {
      notifier.setAuthenticated(userId: 'user_123');

      notifier.setLoading();
      expect(notifier.state, isA<AuthLoading>());
    });

    test('updateSessionToken updates the token without changing state', () {
      notifier.setAuthenticated(
        userId: 'user_123',
        sessionToken: 'old-token',
      );

      notifier.updateSessionToken('new-token');
      expect(notifier.sessionToken, equals('new-token'));
      // State should remain AuthAuthenticated
      expect(notifier.state, isA<AuthAuthenticated>());
    });
  });

  group('authProvider', () {
    test('provides an AuthNotifier with initial AuthLoading state', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AuthState state = container.read(authProvider);
      expect(state, isA<AuthLoading>());
    });

    test('notifier is accessible', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AuthNotifier notifier = container.read(authProvider.notifier);
      expect(notifier, isA<AuthNotifier>());
    });

    test('state updates propagate through the provider', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AuthNotifier notifier = container.read(authProvider.notifier);
      notifier.setAuthenticated(userId: 'user_abc');

      final AuthState state = container.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
    });
  });

  group('clerkPublishableKeyProvider', () {
    test('returns a string (empty when not configured)', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final String key = container.read(clerkPublishableKeyProvider);
      // In tests, the dart-define is not set, so it defaults to empty.
      expect(key, isA<String>());
    });
  });
}
