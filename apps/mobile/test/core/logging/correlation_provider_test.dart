import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:dishy/core/logging/correlation_provider.dart';
import 'package:dishy/core/logging/log_service.dart';

void main() {
  group('sessionIdProvider', () {
    test('returns a valid UUIDv4', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final String sessionId = container.read(sessionIdProvider);
      expect(Uuid.isValidUUID(fromString: sessionId), isTrue);
    });

    test('returns the same ID on repeated reads (stable per session)', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final String first = container.read(sessionIdProvider);
      final String second = container.read(sessionIdProvider);
      expect(first, equals(second));
    });

    test('different containers get different session IDs', () {
      final ProviderContainer container1 = ProviderContainer();
      final ProviderContainer container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      final String id1 = container1.read(sessionIdProvider);
      final String id2 = container2.read(sessionIdProvider);
      // Technically could collide but UUIDv4 collision is vanishingly rare.
      expect(id1, isNot(equals(id2)));
    });
  });

  group('logServiceProvider', () {
    test('returns a LogService instance', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final LogService service = container.read(logServiceProvider);
      expect(service, isA<LogService>());
    });

    test('LogService has the session ID from sessionIdProvider', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final String sessionId = container.read(sessionIdProvider);
      final LogService service = container.read(logServiceProvider);
      expect(service.sessionId, equals(sessionId));
    });
  });
}
