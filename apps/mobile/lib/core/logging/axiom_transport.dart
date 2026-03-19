/// Axiom ingest transport for sending batched log entries.
///
/// Converts [LogEntry] instances to NDJSON and POSTs them to the Axiom
/// ingest API endpoint. This transport is designed to be called
/// periodically (e.g. on a timer or when the buffer reaches a threshold)
/// and is best-effort — failures are silently ignored so they never
/// disrupt the user experience.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

import 'log_service.dart';

/// Sends batched [LogEntry] instances to the Axiom ingest API.
///
/// Uses Dio for HTTP transport. Entries are serialized as
/// newline-delimited JSON (NDJSON) matching the Axiom ingest format.
class AxiomTransport {
  /// Creates an [AxiomTransport] targeting the given [dataset].
  ///
  /// [apiToken] is the Axiom API token for authentication.
  /// [dataset] is the Axiom dataset name (e.g. `"dishy-mobile"`).
  /// An optional [dio] instance can be injected for testing.
  AxiomTransport({
    required String apiToken,
    required String dataset,
    Dio? dio,
  })  : _apiToken = apiToken,
        _dataset = dataset,
        _dio = dio ?? Dio();

  final String _apiToken;
  final String _dataset;
  final Dio _dio;

  /// Sends a batch of log entries to Axiom.
  ///
  /// Returns `true` if the ingest succeeded (HTTP 2xx), `false` otherwise.
  /// Never throws — all errors are caught and result in a `false` return.
  Future<bool> send(List<LogEntry> entries) async {
    if (entries.isEmpty) {
      return true;
    }

    final String ndjson = entries
        .map((LogEntry e) => jsonEncode(e.toJson()))
        .join('\n');

    final String url =
        'https://api.axiom.co/v1/datasets/$_dataset/ingest';

    try {
      final Response<void> response = await _dio.post<void>(
        url,
        data: ndjson,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/x-ndjson',
          },
        ),
      );

      final int statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } on DioException {
      // Best-effort — swallow transport errors.
      return false;
    }
  }
}
