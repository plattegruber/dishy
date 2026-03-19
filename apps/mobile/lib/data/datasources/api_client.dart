/// HTTP client for communicating with the Dishy Worker API.
///
/// Uses Dio for HTTP transport with JSON serialization. The base URL
/// points to the deployed Cloudflare Worker by default and can be
/// overridden for local development with `wrangler dev`.
library;

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';

/// Typed API client for the Dishy backend.
///
/// Wraps [Dio] with pre-configured base URL, timeouts, and headers.
/// All methods return strongly-typed responses — no `dynamic` types.
class ApiClient {
  /// Creates an [ApiClient] with an optional custom [Dio] instance.
  ///
  /// If no [dio] instance is provided, a default one is created with
  /// the production base URL from [AppConstants].
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

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
