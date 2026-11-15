import 'package:dio/dio.dart';

/// Callback type for retrieving the active auth token
typedef TokenProvider = Future<String?> Function();

/// Interceptor for injecting JWT Bearer token into outgoing requests
class AuthInterceptor extends QueuedInterceptor {
  final TokenProvider _tokenProvider;
  final Future<void> Function()? _onUnauthorized;

  AuthInterceptor({
    required TokenProvider tokenProvider,
    Future<void> Function()? onUnauthorized,
  })  : _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the request explicitly opts out of authentication
    final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;

    if (requiresAuth) {
      final token = await _tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Always ensure JSON accept and content headers
    options.headers['Accept'] = 'application/json';
    if (options.data != null && options.headers['Content-Type'] == null) {
      options.headers['Content-Type'] = 'application/json';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Trigger unauthorized session handler (e.g., logout or token refresh)
      if (_onUnauthorized != null) {
        await _onUnauthorized();
      }
    }
    return handler.next(err);
  }
}
