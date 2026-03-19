/// HTTP client for communicating with the Dishy Worker API.
///
/// Uses Dio for HTTP transport with JSON serialization. The base URL
/// points to the deployed Cloudflare Worker by default and can be
/// overridden for local development with `wrangler dev`.
///
/// Includes an auth interceptor that automatically attaches the Clerk
/// session token to all requests and handles 401 responses.
library;

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';

/// Callback type for retrieving the current session token.
///
/// Returns `null` if the user is not authenticated.
typedef TokenProvider = String? Function();

/// Callback type for handling 401 Unauthorized responses.
///
/// Invoked when the API returns a 401, signalling that the user
/// should be redirected to sign-in.
typedef OnUnauthorized = void Function();

/// Typed API client for the Dishy backend.
///
/// Wraps [Dio] with pre-configured base URL, timeouts, and headers.
/// All methods return strongly-typed responses — no `dynamic` types.
///
/// Supports automatic token attachment via [attachAuthInterceptor]
/// and 401 handling via the [OnUnauthorized] callback.
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

  /// Attaches an authentication interceptor to the Dio client.
  ///
  /// The interceptor adds the `Authorization: Bearer <token>` header
  /// to every request (when a token is available) and invokes
  /// [onUnauthorized] when the server returns a 401 response.
  void attachAuthInterceptor({
    required TokenProvider tokenProvider,
    required OnUnauthorized onUnauthorized,
  }) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Checks whether the API is reachable and healthy.
  ///
  /// Calls `GET /health` and returns the parsed JSON map.
  /// Throws a [DioException] if the request fails.
  Future<Map<String, Object>> getHealth() async {
    final Response<Map<String, Object>> response =
        await _dio.get<Map<String, Object>>('/health');
    return response.data ?? <String, Object>{};
  }

  /// Fetches the authenticated user's profile from `GET /me`.
  ///
  /// Requires a valid session token (attached automatically by the
  /// auth interceptor). Returns the parsed user data map.
  /// Throws a [DioException] if the request fails or returns 401.
  Future<Map<String, Object>> getMe() async {
    final Response<Map<String, Object>> response =
        await _dio.get<Map<String, Object>>('/me');
    return response.data ?? <String, Object>{};
  }
}
