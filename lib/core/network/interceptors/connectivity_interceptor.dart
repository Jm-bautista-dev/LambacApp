import 'package:dio/dio.dart';
import '../network_info.dart';
import '../../errors/app_failure.dart';

/// Pre-flight interceptor ensuring network connectivity before dispatching HTTP calls
class ConnectivityInterceptor extends Interceptor {
  final NetworkInfo _networkInfo;

  ConnectivityInterceptor({required NetworkInfo networkInfo})
      : _networkInfo = networkInfo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkFailure(
            message: 'No internet connection detected. Please check your network.',
          ),
        ),
      );
    }
    return handler.next(options);
  }
}
