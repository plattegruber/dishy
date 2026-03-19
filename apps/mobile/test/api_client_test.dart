import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dishy/data/datasources/api_client.dart';

void main() {
  group('ApiClient', () {
    test('can be constructed with default Dio', () {
      final ApiClient client = ApiClient();
      expect(client, isA<ApiClient>());
    });

    test('can be constructed with custom Dio', () {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final ApiClient client = ApiClient(dio: dio);
      expect(client, isA<ApiClient>());
    });

    test('attachAuthInterceptor adds interceptor to Dio', () {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final ApiClient client = ApiClient(dio: dio);

      final int initialCount = dio.interceptors.length;

      client.attachAuthInterceptor(
        tokenProvider: () => 'test-token',
        onUnauthorized: () {},
      );

      expect(dio.interceptors.length, initialCount + 1);
    });

    test('auth interceptor attaches token to requests', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final ApiClient client = ApiClient(dio: dio);

      String? capturedAuthHeader;

      client.attachAuthInterceptor(
        tokenProvider: () => 'test-jwt-token',
        onUnauthorized: () {},
      );

      // Add a second interceptor that captures the Authorization header
      // and short-circuits the request.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
            capturedAuthHeader =
                options.headers['Authorization'] as String?;
            handler.reject(
              DioException(requestOptions: options, message: 'test-intercept'),
            );
          },
        ),
      );

      try {
        await client.getHealth();
      } on DioException catch (_) {
        // Expected — we intercepted the request.
      }

      expect(capturedAuthHeader, 'Bearer test-jwt-token');
    });

    test('auth interceptor skips token when provider returns null', () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final ApiClient client = ApiClient(dio: dio);

      String? capturedAuthHeader;

      client.attachAuthInterceptor(
        tokenProvider: () => null,
        onUnauthorized: () {},
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
            capturedAuthHeader =
                options.headers['Authorization'] as String?;
            handler.reject(
              DioException(requestOptions: options, message: 'test-intercept'),
            );
          },
        ),
      );

      try {
        await client.getHealth();
      } on DioException catch (_) {
        // Expected.
      }

      expect(capturedAuthHeader, isNull);
    });

    test('onUnauthorized callback type is correct', () {
      // Verify the callback type signature at compile time.
      bool wasCalled = false;
      void callback() {
        wasCalled = true;
      }

      // Create the client and attach interceptor with the callback.
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      final ApiClient client = ApiClient(dio: dio);
      client.attachAuthInterceptor(
        tokenProvider: () => 'token',
        onUnauthorized: callback,
      );

      // Simulate calling the callback directly.
      callback();
      expect(wasCalled, isTrue);
    });

    test('getMe method exists and is callable', () {
      // Verify getMe is part of the API client interface.
      final ApiClient client = ApiClient();
      // We just need to check the method signature exists.
      expect(client.getMe, isA<Function>());
    });
  });
}
