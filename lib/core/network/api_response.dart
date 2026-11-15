import 'package:equatable/equatable.dart';

/// Standard Pagination Metadata DTO
class PaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] ?? 1) as int,
      limit: (json['limit'] ?? 20) as int,
      totalItems: (json['total_items'] ?? json['totalItems'] ?? 0) as int,
      totalPages: (json['total_pages'] ?? json['totalPages'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total_items': totalItems,
      'total_pages': totalPages,
    };
  }

  @override
  List<Object?> get props => [page, limit, totalItems, totalPages];
}

/// Generic Standardized v1 API Response Envelope Container
class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String message;
  final List<String>? errors;
  final PaginationMeta? meta;

  const ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.errors,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? decoder,
  ) {
    final rawData = json['data'];
    final dataObj = (rawData != null && decoder != null) ? decoder(rawData) : rawData as T?;
    final rawErrors = json['errors'] as List<dynamic>?;

    return ApiResponse<T>(
      success: (json['success'] ?? true) as bool,
      data: dataObj,
      message: (json['message'] ?? '').toString(),
      errors: rawErrors?.map((e) => e.toString()).toList(),
      meta: json['meta'] != null ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson([Map<String, dynamic> Function(T data)? encoder]) {
    return {
      'success': success,
      if (data != null) 'data': encoder != null ? encoder(data as T) : data,
      'message': message,
      if (errors != null) 'errors': errors,
      if (meta != null) 'meta': meta!.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, data, message, errors, meta];
}
