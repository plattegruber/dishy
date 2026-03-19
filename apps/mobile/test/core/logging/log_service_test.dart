import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:dishy/core/logging/log_service.dart';

void main() {
  group('LogService', () {
    late LogService logService;

    setUp(() {
      logService = LogService(sessionId: 'test-session-id');
    });

    test('starts with an empty buffer', () {
      expect(logService.entryCount, equals(0));
      expect(logService.entries, isEmpty);
    });

    test('info() buffers an info-level entry', () {
      logService.info('hello');

      expect(logService.entryCount, equals(1));
      expect(logService.entries.first.level, equals(LogLevel.info));
      expect(logService.entries.first.message, equals('hello'));
    });

    test('debug() buffers a debug-level entry', () {
      logService.debug('debug msg');

      expect(logService.entryCount, equals(1));
      expect(logService.entries.first.level, equals(LogLevel.debug));
    });

    test('warn() buffers a warn-level entry', () {
      logService.warn('warning');

      expect(logService.entryCount, equals(1));
      expect(logService.entries.first.level, equals(LogLevel.warn));
    });

    test('error() buffers an error-level entry', () {
      logService.error('failure');

      expect(logService.entryCount, equals(1));
      expect(logService.entries.first.level, equals(LogLevel.error));
    });

    test('entries carry the session ID', () {
      logService.info('test');

      expect(logService.entries.first.sessionId, equals('test-session-id'));
    });

    test('entries carry the service name "mobile"', () {
      logService.info('test');

      expect(logService.entries.first.service, equals('mobile'));
    });

    test('entries carry a custom correlation ID when provided', () {
      logService.info('test', correlationId: 'custom-corr');

      expect(logService.entries.first.correlationId, equals('custom-corr'));
    });

    test('entries get an auto-generated correlation ID when none provided',
        () {
      logService.info('test');

      // Should be a valid UUIDv4
      final String corrId = logService.entries.first.correlationId;
      expect(Uuid.isValidUUID(fromString: corrId), isTrue);
    });

    test('entries carry context when provided', () {
      logService.info(
        'test',
        context: <String, Object>{'key': 'value', 'count': 42},
      );

      expect(logService.entries.first.context['key'], equals('value'));
      expect(logService.entries.first.context['count'], equals(42));
    });

    test('entries have empty context by default', () {
      logService.info('test');

      expect(logService.entries.first.context, isEmpty);
    });

    test('flush() returns all entries and clears the buffer', () {
      logService.info('one');
      logService.warn('two');
      logService.error('three');

      expect(logService.entryCount, equals(3));

      final List<LogEntry> flushed = logService.flush();
      expect(flushed, hasLength(3));
      expect(logService.entryCount, equals(0));
    });

    test('flush() on empty buffer returns empty list', () {
      final List<LogEntry> flushed = logService.flush();
      expect(flushed, isEmpty);
    });

    test('entries have ISO-8601 timestamps', () {
      logService.info('test');

      final String timestamp = logService.entries.first.timestamp;
      // Should parse without error
      expect(() => DateTime.parse(timestamp), returnsNormally);
    });
  });

  group('LogEntry.toJson', () {
    test('produces the expected schema', () {
      const LogEntry entry = LogEntry(
        timestamp: '2026-03-19T12:00:00.000Z',
        level: LogLevel.info,
        message: 'test message',
        correlationId: '550e8400-e29b-41d4-a716-446655440000',
        sessionId: '660e8400-e29b-41d4-a716-446655440000',
        service: 'mobile',
        context: <String, Object>{},
      );

      final Map<String, Object> json = entry.toJson();

      expect(json['timestamp'], equals('2026-03-19T12:00:00.000Z'));
      expect(json['level'], equals('info'));
      expect(json['message'], equals('test message'));
      expect(json['correlation_id'],
          equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(json['session_id'],
          equals('660e8400-e29b-41d4-a716-446655440000'));
      expect(json['service'], equals('mobile'));
      expect(json['context'], isA<Map<String, Object>>());
    });

    test('serializes context fields', () {
      const LogEntry entry = LogEntry(
        timestamp: '2026-03-19T12:00:00.000Z',
        level: LogLevel.warn,
        message: 'slow',
        correlationId: 'corr',
        sessionId: 'sess',
        service: 'mobile',
        context: <String, Object>{'method': 'GET', 'status': 200},
      );

      final Map<String, Object> json = entry.toJson();
      final Map<String, Object> ctx =
          json['context']! as Map<String, Object>;
      expect(ctx['method'], equals('GET'));
      expect(ctx['status'], equals(200));
    });
  });

  group('LogLevel', () {
    test('debug has value "debug"', () {
      expect(LogLevel.debug.value, equals('debug'));
    });

    test('info has value "info"', () {
      expect(LogLevel.info.value, equals('info'));
    });

    test('warn has value "warn"', () {
      expect(LogLevel.warn.value, equals('warn'));
    });

    test('error has value "error"', () {
      expect(LogLevel.error.value, equals('error'));
    });
  });

  group('LogService.generateCorrelationId', () {
    test('returns a valid UUIDv4', () {
      final String id = LogService.generateCorrelationId();
      expect(Uuid.isValidUUID(fromString: id), isTrue);
    });

    test('returns unique IDs on successive calls', () {
      final String id1 = LogService.generateCorrelationId();
      final String id2 = LogService.generateCorrelationId();
      expect(id1, isNot(equals(id2)));
    });
  });
}
