import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Production Firestore Cursor Page container.
/// Holds retrieved items, the authoritative [lastDocument] cursor,
/// and whether subsequent pages exist without loading entire collections.
class FirestoreCursorPage<T> extends Equatable {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final int? totalCount;

  const FirestoreCursorPage({
    required this.items,
    this.lastDocument,
    required this.hasMore,
    this.totalCount,
  });

  factory FirestoreCursorPage.empty() => const FirestoreCursorPage(
        items: [],
        lastDocument: null,
        hasMore: false,
        totalCount: 0,
      );

  @override
  List<Object?> get props => [items, lastDocument?.id, hasMore, totalCount];
}

/// Helper utility for deterministic Firestore cursor pagination.
class FirestorePaginationHelper {
  const FirestorePaginationHelper._();

  /// Fetches a bounded cursor-based page from a Firestore [query].
  ///
  /// Uses native `limit(pageSize)` and `startAfterDocument(startAfter)`
  /// to ensure only the requested slice is retrieved over the wire.
  static Future<FirestoreCursorPage<T>> fetchPage<T>({
    required Query<Map<String, dynamic>> query,
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required T Function(DocumentSnapshot<Map<String, dynamic>> doc) mapper,
    bool fetchCount = false,
  }) async {
    Query<Map<String, dynamic>> pagedQuery = query.limit(limit);

    if (startAfter != null) {
      pagedQuery = pagedQuery.startAfterDocument(startAfter);
    }

    final snapshot = await pagedQuery.get();
    final items = snapshot.docs.map(mapper).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length >= limit;

    int? totalCount;
    if (fetchCount) {
      try {
        final countSnap = await query.count().get();
        totalCount = countSnap.count;
      } catch (_) {
        // Fallback: aggregation not supported in offline/emulator mode
      }
    }

    return FirestoreCursorPage<T>(
      items: items,
      lastDocument: lastDoc,
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }
}
