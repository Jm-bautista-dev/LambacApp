import 'package:flutter/widgets.dart';

/// Helper to attach an infinite scroll listener to a [ScrollController] or [NotificationListener].
class PaginationScrollHelper {
  const PaginationScrollHelper._();

  /// Returns true if the scroll position is within [thresholdPixels] from the bottom.
  static bool isNearBottom(ScrollPosition position, {double thresholdPixels = 200.0}) {
    if (!position.hasContentDimensions) return false;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    return currentScroll >= (maxScroll - thresholdPixels);
  }

  /// Creates a listener on a [ScrollController] that invokes [onLoadMore]
  /// when scrolling near the end, respecting [canLoadMore] conditions.
  static VoidCallback createScrollListener({
    required ScrollController scrollController,
    required bool Function() canLoadMore,
    required VoidCallback onLoadMore,
    double thresholdPixels = 200.0,
  }) {
    return () {
      if (scrollController.hasClients &&
          isNearBottom(scrollController.position, thresholdPixels: thresholdPixels)) {
        if (canLoadMore()) {
          onLoadMore();
        }
      }
    };
  }
}
