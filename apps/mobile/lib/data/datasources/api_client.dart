/// HTTP client for communicating with the Dishy Worker API.
///
/// Uses Dio for HTTP transport with JSON serialization. The base URL
/// points to the deployed Cloudflare Worker by default and can be
/// overridden for local development with `wrangler dev`.
///
/// Every outgoing request automatically includes `X-Correlation-ID`
/// (a fresh UUIDv4) and `X-Session-ID` headers so that backend logs
/// can be correlated with frontend logs in Axiom.
///
/// Authenticated requests also include a `Bearer` token in the
/// `Authorization` header, obtained from the [AuthNotifier].
library;

import 'package:dio/dio.dart';

import '../../core/auth/auth_provider.dart';
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

/// Dio interceptor that attaches the Clerk session Bearer token to
/// every outgoing request.
///
/// Works alongside [CorrelationInterceptor] — this interceptor runs
/// first to add the `Authorization` header, then the correlation
/// interceptor adds tracking headers.
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor] backed by the given [authNotifier].
  ///
  /// The notifier is read on each request to get the current session
  /// token. If no token is available the request proceeds without an
  /// `Authorization` header (for unauthenticated endpoints like
  /// `/health`).
  AuthInterceptor({required AuthNotifier authNotifier})
      : _authNotifier = authNotifier;

  final AuthNotifier _authNotifier;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = _authNotifier.sessionToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Typed API client for the Dishy backend.
///
/// Wraps [Dio] with pre-configured base URL, timeouts, headers, and
/// interceptors for authentication and correlation ID tracking. All
/// methods return strongly-typed responses — no `dynamic` types.
class ApiClient {
  /// Creates an [ApiClient] with the given [logService] and optional
  /// [authNotifier].
  ///
  /// If no [dio] instance is provided, a default one is created with
  /// the production base URL from [AppConstants], an [AuthInterceptor]
  /// for Bearer token injection, and a [CorrelationInterceptor] for
  /// automatic header injection and logging.
  ApiClient({
    required LogService logService,
    AuthNotifier? authNotifier,
    Dio? dio,
  }) : _dio = dio ??
            _createDefaultDio(
              logService: logService,
              authNotifier: authNotifier,
            );

  final Dio _dio;

  /// Creates the default Dio instance with all interceptors.
  static Dio _createDefaultDio({
    required LogService logService,
    AuthNotifier? authNotifier,
  }) {
    final Dio dio = Dio(
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

    // Auth interceptor runs first to add the Bearer token.
    if (authNotifier != null) {
      dio.interceptors.add(AuthInterceptor(authNotifier: authNotifier));
    }

    // Correlation interceptor runs second to add tracking headers and log.
    dio.interceptors.add(CorrelationInterceptor(logService: logService));

    return dio;
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

  /// Fetches the authenticated user's profile from the API.
  ///
  /// Calls `GET /me` with the Bearer token. Requires an active session.
  /// Throws a [DioException] on failure (including 401 if the token is
  /// invalid or expired).
  Future<Map<String, Object>> getMe() async {
    final Response<Map<String, Object>> response =
        await _dio.get<Map<String, Object>>('/me');
    return response.data ?? <String, Object>{};
  }

  /// Captures a recipe from raw text via the extraction pipeline.
  ///
  /// Calls `POST /recipes/capture` with the manual input text.
  /// The API runs Claude extraction, structures the recipe, and saves it.
  /// Returns the saved recipe as a JSON map.
  ///
  /// Throws a [DioException] on failure.
  Future<Map<String, Object?>> captureRecipe(String text) async {
    final Response<Map<String, Object?>> response =
        await _dio.post<Map<String, Object?>>(
      '/recipes/capture',
      data: <String, String>{
        'input_type': 'manual',
        'text': text,
      },
    );
    return response.data ?? <String, Object?>{};
  }

  /// Fetches all recipes for the authenticated user.
  ///
  /// Calls `GET /recipes` and returns a list of recipe JSON maps.
  /// Throws a [DioException] on failure.
  Future<List<Map<String, Object?>>> getRecipes() async {
    final Response<List<Object?>> response =
        await _dio.get<List<Object?>>('/recipes');
    final List<Object?> data = response.data ?? <Object?>[];
    return data
        .whereType<Map<String, Object?>>()
        .toList();
  }

  /// Fetches a single recipe by ID.
  ///
  /// Calls `GET /recipes/:id` and returns the recipe JSON map.
  /// Throws a [DioException] on failure (including 404 if not found).
  Future<Map<String, Object?>> getRecipe(String id) async {
    final Response<Map<String, Object?>> response =
        await _dio.get<Map<String, Object?>>('/recipes/$id');
    return response.data ?? <String, Object?>{};
  }

  /// Fetches detailed nutrition data for a recipe.
  ///
  /// Calls `GET /recipes/:id/nutrition` and returns the nutrition
  /// breakdown including per-ingredient detail.
  /// Throws a [DioException] on failure (including 404 if not found).
  Future<Map<String, Object?>> getRecipeNutrition(String id) async {
    final Response<Map<String, Object?>> response =
        await _dio.get<Map<String, Object?>>('/recipes/$id/nutrition');
    return response.data ?? <String, Object?>{};
  }

  /// Captures a recipe from a social link URL.
  ///
  /// Calls `POST /recipes/capture` with `input_type: "social_link"`.
  /// Returns 202 Accepted with a capture ID for polling.
  ///
  /// Throws a [DioException] on failure.
  Future<Map<String, Object?>> captureSocialLink(String url) async {
    final Response<Map<String, Object?>> response =
        await _dio.post<Map<String, Object?>>(
      '/recipes/capture',
      data: <String, String>{
        'input_type': 'social_link',
        'url': url,
      },
    );
    return response.data ?? <String, Object?>{};
  }

  /// Captures a recipe from a screenshot image.
  ///
  /// Calls `POST /recipes/capture` with `input_type: "screenshot"`.
  /// The image is sent as base64-encoded data.
  /// Returns 202 Accepted with a capture ID for polling.
  ///
  /// Throws a [DioException] on failure.
  Future<Map<String, Object?>> captureScreenshot({
    required String imageBase64,
    required String contentType,
  }) async {
    final Response<Map<String, Object?>> response =
        await _dio.post<Map<String, Object?>>(
      '/recipes/capture',
      data: <String, String>{
        'input_type': 'screenshot',
        'image_data': imageBase64,
        'content_type': contentType,
      },
    );
    return response.data ?? <String, Object?>{};
  }

  /// Polls the status of an async capture.
  ///
  /// Calls `GET /captures/:id` and returns the capture status.
  /// The response includes `status`, `recipe_id`, and `error_message`.
  ///
  /// Throws a [DioException] on failure.
  Future<Map<String, Object?>> getCaptureStatus(String captureId) async {
    final Response<Map<String, Object?>> response =
        await _dio.get<Map<String, Object?>>('/captures/$captureId');
    return response.data ?? <String, Object?>{};
  }
}
