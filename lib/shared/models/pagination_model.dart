import 'package:equatable/equatable.dart';

/// Generic Paginated List container for paginated API endpoints & Firestore cursor pagination
class PaginatedList<T> extends Equatable {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;
  final dynamic cursor;

  const PaginatedList({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasNextPage,
    this.cursor,
  });

  bool get hasMore => hasNextPage;

  factory PaginatedList.empty() {
    return const PaginatedList(
      items: [],
      page: 1,
      pageSize: 20,
      totalCount: 0,
      hasNextPage: false,
      cursor: null,
    );
  }

  factory PaginatedList.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic item) itemDecoder,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? json['data'] as List<dynamic>? ?? [];
    final items = rawItems.map(itemDecoder).toList();
    final page = (json['page'] ?? json['current_page'] ?? 1) as int;
    final pageSize = (json['page_size'] ?? json['per_page'] ?? items.length) as int;
    final totalCount = (json['total'] ?? json['total_count'] ?? items.length) as int;
    final hasNextPage = json['has_next'] as bool? ?? (page * pageSize < totalCount);

    return PaginatedList<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      hasNextPage: hasNextPage,
      cursor: json['cursor'],
    );
  }

  PaginatedList<T> copyWith({
    List<T>? items,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasNextPage,
    dynamic cursor,
  }) {
    return PaginatedList<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      cursor: cursor ?? this.cursor,
    );
  }

  @override
  List<Object?> get props => [items, page, pageSize, totalCount, hasNextPage, cursor];
}
