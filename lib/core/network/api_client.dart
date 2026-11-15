import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/flavor_provider.dart';
import '../errors/app_failure.dart';
import '../errors/error_handler.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'network_info.dart';
import 'result.dart';
import '../../shared/services/storage_service.dart';

/// Abstract API Client contract
abstract class ApiClient {
  Future<Result<T, AppFailure>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  });

  Future<Result<T, AppFailure>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  });

  Future<Result<T, AppFailure>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  });

  Future<Result<T, AppFailure>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  });

  Future<Result<T, AppFailure>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  });
}

/// Concrete Dio-based implementation of ApiClient
class DioApiClient implements ApiClient {
  final Dio _dio;

  DioApiClient({
    required Dio dio,
  }) : _dio = dio;

  /// Factory to construct a fully configured DioApiClient with all interceptors
  factory DioApiClient.create({
    required String baseUrl,
    required Duration connectTimeout,
    required Duration receiveTimeout,
    required Duration sendTimeout,
    required bool enableLogging,
    required TokenProvider tokenProvider,
    required NetworkInfo networkInfo,
    Future<void> Function()? onUnauthorized,
  }) {
    final baseOptions = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    final dio = Dio(baseOptions);

    dio.interceptors.addAll([
      ConnectivityInterceptor(networkInfo: networkInfo),
      AuthInterceptor(
        tokenProvider: tokenProvider,
        onUnauthorized: onUnauthorized,
      ),
      LoggingInterceptor(enabled: enableLogging),
      ErrorInterceptor(),
    ]);

    return DioApiClient(dio: dio);
  }

  @override
  Future<Result<T, AppFailure>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, requiresAuth),
        cancelToken: cancelToken,
      ),
      decoder: decoder,
    );
  }

  @override
  Future<Result<T, AppFailure>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, requiresAuth),
        cancelToken: cancelToken,
      ),
      decoder: decoder,
    );
  }

  @override
  Future<Result<T, AppFailure>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, requiresAuth),
        cancelToken: cancelToken,
      ),
      decoder: decoder,
    );
  }

  @override
  Future<Result<T, AppFailure>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, requiresAuth),
        cancelToken: cancelToken,
      ),
      decoder: decoder,
    );
  }

  @override
  Future<Result<T, AppFailure>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic data)? decoder,
    bool requiresAuth = true,
  }) async {
    return _sendRequest<T>(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, requiresAuth),
        cancelToken: cancelToken,
      ),
      decoder: decoder,
    );
  }

  Options _mergeOptions(Options? options, bool requiresAuth) {
    final opt = options ?? Options();
    opt.extra = {
      ...?opt.extra,
      'requiresAuth': requiresAuth,
    };
    return opt;
  }

  Future<Result<T, AppFailure>> _sendRequest<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic data)? decoder,
  }) async {
    try {
      final response = await request();
      final data = response.data;

      if (decoder != null) {
        final decoded = decoder(data);
        return Result.success(decoded);
      }

      if (data is T) {
        return Result.success(data);
      }

      return Result.success(data as T);
    } catch (e) {
      final failure = ErrorHandler.handle(e);
      return Result.failure(failure);
    }
  }
}

/// Network Info Provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(storageServiceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return DioApiClient.create(
    baseUrl: config.apiBaseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    sendTimeout: config.sendTimeout,
    enableLogging: config.enableLogging,
    tokenProvider: () => storage.getToken(),
    networkInfo: networkInfo,
  );
});
