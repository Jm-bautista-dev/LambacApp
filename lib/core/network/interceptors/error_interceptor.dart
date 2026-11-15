import 'package:dio/dio.dart';
import '../../errors/error_handler.dart';

/// Interceptor that wraps DioExceptions into standardized AppFailures
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Standardize error message & failure object
    final failure = ErrorHandler.handle(err);
    
    // Attach domain failure into Dio extra for consumption by ApiClient
    err.requestOptions.extra['domainFailure'] = failure;
    return handler.next(err);
  }
}
