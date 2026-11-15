import 'package:equatable/equatable.dart';

/// Generic Container for Paginated Collections
class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) itemDecoder,
  ) {
    final rawItems = (json['items'] ?? json['data'] ?? []) as List<dynamic>;

    return PaginatedResult<T>(
      items: rawItems.map((e) => itemDecoder(e as Map<String, dynamic>)).toList(),
      page: (json['page'] ?? json['meta']?['page'] ?? 1) as int,
      limit: (json['limit'] ?? json['meta']?['limit'] ?? 20) as int,
      totalItems: (json['total_items'] ?? json['meta']?['total_items'] ?? rawItems.length) as int,
      totalPages: (json['total_pages'] ?? json['meta']?['total_pages'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T item) itemEncoder) {
    return {
      'items': items.map((i) => itemEncoder(i)).toList(),
      'page': page,
      'limit': limit,
      'total_items': totalItems,
      'total_pages': totalPages,
    };
  }

  @override
  List<Object?> get props => [items, page, limit, totalItems, totalPages];
}
