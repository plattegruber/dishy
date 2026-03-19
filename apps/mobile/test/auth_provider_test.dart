import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/auth/auth_provider.dart';
import 'package:dishy/core/auth/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    test('initial state is AuthLoading', () {
      final AuthNotifier notifier = AuthNotifier();
      expect(notifier.state, isA<AuthLoading>());
      notifier.dispose();
    });

    test('currentToken returns null when not authenticated', () {
      final AuthNotifier notifier = AuthNotifier();
      expect(notifier.currentToken, isNull);
      notifier.dispose();
    });

    test('signOut sets state to AuthUnauthenticated', () async {
      final AuthNotifier notifier = AuthNotifier();
      await notifier.signOut();
      expect(notifier.state, isA<AuthUnauthenticated>());
      notifier.dispose();
    });

    test('signIn without initialization returns AuthError', () async {
      final AuthNotifier notifier = AuthNotifier();
      await notifier.signIn(email: 'test@test.com', password: 'password');
      expect(notifier.state, isA<AuthError>());
      final AuthError error = notifier.state as AuthError;
      expect(error.message, contains('not initialized'));
      notifier.dispose();
    });
  });

  group('authProvider', () {
    test('provides AuthLoading as initial state', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AuthState state = container.read(authProvider);
      expect(state, isA<AuthLoading>());
    });

    test('provides access to AuthNotifier', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AuthNotifier notifier = container.read(authProvider.notifier);
      expect(notifier, isA<AuthNotifier>());
    });

    test('signOut through provider updates state', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).signOut();
      final AuthState state = container.read(authProvider);
      expect(state, isA<AuthUnauthenticated>());
    });
  });
}
