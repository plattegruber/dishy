/// HTTP client for communicating with the Dishy Worker API.
///
/// Uses Dio for HTTP transport with JSON serialization. The base URL
/// points to the deployed Cloudflare Worker by default and can be
/// overridden for local development with `wrangler dev`.
///
/// Every outgoing request automatically includes `X-Correlation-ID`
/// (a fresh UUIDv4) and `X-Session-ID` headers so that backend logs
/// can be correlated with frontend logs in Axiom.
library;

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logging/log_service.dart';

/// Dio interceptor that attaches correlation and session ID headers
/// to every outgoing request and logs request/response lifecycle.
class CorrelationInterceptor extends Interceptor {
  /// Creates a [CorrelationInterceptor] backed by the given [logService].
  CorrelationInterceptor({required LogService logService})
      : _logService = logService;

  final LogService _logService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String correlationId = LogService.generateCorrelationId();
    options.headers['X-Correlation-ID'] = correlationId;
    options.headers['X-Session-ID'] = _logService.sessionId;

    _logService.info(
      'HTTP request: ${options.method} ${options.uri}',
      correlationId: correlationId,
      context: <String, Object>{
        'method': options.method,
        'url': options.uri.toString(),
      },
    );

    // Stash the correlation ID so onResponse/onError can read it.
    options.extra['correlation_id'] = correlationId;

    handler.next(options);
  }

  @override
  void onResponse(
      Response<Object?> response, ResponseInterceptorHandler handler) {
    final String correlationId =
        response.requestOptions.extra['correlation_id'] as String? ?? '';

    _logService.info(
      'HTTP response: ${response.statusCode} ${response.requestOptions.uri}',
      correlationId: correlationId,
      context: <String, Object>{
        'status_code': response.statusCode ?? 0,
        'url': response.requestOptions.uri.toString(),
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String correlationId =
        err.requestOptions.extra['correlation_id'] as String? ?? '';

    _logService.error(
      'HTTP error: ${err.message ?? err.type.name} ${err.requestOptions.uri}',
      correlationId: correlationId,
      context: <String, Object>{
        'error_type': err.type.name,
        'url': err.requestOptions.uri.toString(),
        if (err.response?.statusCode != null)
          'status_code': err.response!.statusCode!,
      },
    );

    handler.next(err);
  }
}

/// Typed API client for the Dishy backend.
///
/// Wraps [Dio] with pre-configured base URL, timeouts, headers, and
/// a [CorrelationInterceptor] that attaches `X-Correlation-ID` and
/// `X-Session-ID` to every request. All methods return strongly-typed
/// responses — no `dynamic` types.
class ApiClient {
  /// Creates an [ApiClient] with the given [logService].
  ///
  /// If no [dio] instance is provided, a default one is created with
  /// the production base URL from [AppConstants] and a
  /// [CorrelationInterceptor] for automatic header injection.
  ApiClient({required LogService logService, Dio? dio})
      : _dio = dio ??
            (Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            )..interceptors.add(
                CorrelationInterceptor(logService: logService),
              ));

  final Dio _dio;

  /// Checks whether the API is reachable and healthy.
  ///
  /// Calls `GET /health` and returns the parsed JSON map.
  /// Throws a [DioException] if the request fails.
  Future<Map<String, Object>> getHealth() async {
    final Response<Map<String, Object>> response =
        await _dio.get<Map<String, Object>>('/health');
    return response.data ?? <String, Object>{};
  }
}
