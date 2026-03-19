import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/core/logging/axiom_transport.dart';
import 'package:dishy/core/logging/log_service.dart';

/// A mock Dio adapter that records requests and returns configurable responses.
class _MockAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  int statusCode = 200;
  bool shouldThrow = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (shouldThrow) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AxiomTransport', () {
    late _MockAdapter mockAdapter;
    late Dio dio;
    late AxiomTransport transport;

    setUp(() {
      mockAdapter = _MockAdapter();
      dio = Dio();
      dio.httpClientAdapter = mockAdapter;
      transport = AxiomTransport(
        apiToken: 'test-token',
        dataset: 'test-dataset',
        dio: dio,
      );
    });

    test('send() returns true on empty entries without making a request',
        () async {
      final bool result = await transport.send(<LogEntry>[]);
      expect(result, isTrue);
      expect(mockAdapter.lastRequest, isNull);
    });

    test('send() posts to the correct Axiom URL', () async {
      final List<LogEntry> entries = <LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'test',
          correlationId: 'corr-1',
          sessionId: 'sess-1',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ];

      await transport.send(entries);

      expect(mockAdapter.lastRequest, isNotNull);
      expect(
        mockAdapter.lastRequest!.uri.toString(),
        equals('https://api.axiom.co/v1/datasets/test-dataset/ingest'),
      );
    });

    test('send() includes Authorization header with Bearer token', () async {
      final List<LogEntry> entries = <LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'test',
          correlationId: 'corr-1',
          sessionId: 'sess-1',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ];

      await transport.send(entries);

      expect(
        mockAdapter.lastRequest!.headers['Authorization'],
        equals('Bearer test-token'),
      );
    });

    test('send() includes Content-Type application/x-ndjson', () async {
      final List<LogEntry> entries = <LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'test',
          correlationId: 'corr-1',
          sessionId: 'sess-1',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ];

      await transport.send(entries);

      expect(
        mockAdapter.lastRequest!.headers['Content-Type'],
        equals('application/x-ndjson'),
      );
    });

    test('send() returns true on 2xx status', () async {
      mockAdapter.statusCode = 200;

      final bool result = await transport.send(<LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'ok',
          correlationId: 'c',
          sessionId: 's',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ]);

      expect(result, isTrue);
    });

    test('send() returns false on 4xx status', () async {
      mockAdapter.statusCode = 403;

      final bool result = await transport.send(<LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'fail',
          correlationId: 'c',
          sessionId: 's',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ]);

      expect(result, isFalse);
    });

    test('send() returns false on network error', () async {
      mockAdapter.shouldThrow = true;

      final bool result = await transport.send(<LogEntry>[
        const LogEntry(
          timestamp: '2026-03-19T12:00:00.000Z',
          level: LogLevel.info,
          message: 'error',
          correlationId: 'c',
          sessionId: 's',
          service: 'mobile',
          context: <String, Object>{},
        ),
      ]);

      expect(result, isFalse);
    });
  });
}
