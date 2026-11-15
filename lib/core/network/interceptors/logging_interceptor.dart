import 'dart:developer' as developer;
import 'package:dio/dio.dart';

/// Clean logging interceptor for development and staging environments
class LoggingInterceptor extends Interceptor {
  final bool enabled;

  LoggingInterceptor({this.enabled = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      final logBuffer = StringBuffer()
        ..writeln('➡️ HTTP REQUEST [${options.method}]')
        ..writeln('   URL: ${options.baseUrl}${options.path}')
        ..writeln('   Query: ${options.queryParameters}');

      // Mask sensitive headers in logs
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
      }
      logBuffer.writeln('   Headers: $sanitizedHeaders');

      if (options.data != null) {
        logBuffer.writeln('   Body: ${options.data}');
      }

      developer.log(logBuffer.toString(), name: 'LambacApi');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (enabled) {
      final logBuffer = StringBuffer()
        ..writeln('⬅️ HTTP RESPONSE [${response.statusCode}]')
        ..writeln('   URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}')
        ..writeln('   Data: ${response.data}');

      developer.log(logBuffer.toString(), name: 'LambacApi');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final logBuffer = StringBuffer()
        ..writeln('❌ HTTP ERROR [${err.response?.statusCode ?? 'NO_STATUS'}]')
        ..writeln('   URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}')
        ..writeln('   Message: ${err.message}')
        ..writeln('   Response: ${err.response?.data}');

      developer.log(logBuffer.toString(), name: 'LambacApi', error: err);
    }
    super.onError(err, handler);
  }
}
