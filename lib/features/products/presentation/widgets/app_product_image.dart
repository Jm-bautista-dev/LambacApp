import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/app_skeleton.dart';

/// Reusable Product Image Container with Shimmer Placeholder, Web-Safe Decoding, and Fallback Icon
class AppProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static bool isValidNetworkImageUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  static Uint8List? tryDecodeDataUri(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (!trimmed.startsWith('data:image/')) return null;
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex == -1 || commaIndex + 1 >= trimmed.length) return null;
    final header = trimmed.substring(0, commaIndex).toLowerCase();
    if (!header.contains(';base64')) return null;
    // Reject SVG data URIs from raster Image.memory decoding
    if (header.contains('image/svg+xml')) return null;
    try {
      final bytes = base64Decode(trimmed.substring(commaIndex + 1));
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  double? _sanitizeDimension(double? value) {
    if (value == null || value.isNaN || value.isInfinite || value <= 0) {
      return null;
    }
    return value;
  }

  Widget _buildPlaceholder(double? safeWidth, double? safeHeight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = safeWidth ??
            (constraints.hasBoundedWidth && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 120.0);
        final resolvedHeight = safeHeight ??
            (constraints.hasBoundedHeight && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 120.0);

        return AppSkeleton(
          width: resolvedWidth,
          height: resolvedHeight,
          borderRadius: borderRadius ?? BorderRadius.zero,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if ((width != null && width! <= 0) || (height != null && height! <= 0)) {
      return const SizedBox.shrink();
    }
    final safeWidth = _sanitizeDimension(width);
    final safeHeight = _sanitizeDimension(height);
    final resolvedRadius = borderRadius ?? BorderRadius.zero;

    final fallbackContainer = Container(
      width: safeWidth,
      height: safeHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1A17) : const Color(0xFFEFE9DF),
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.coffee_rounded,
        size: (safeHeight != null && safeHeight < 100) ? 36 : 54,
        color: isDark
            ? AppColors.brandAmberLight.withValues(alpha: 0.6)
            : AppColors.brandAmber.withValues(alpha: 0.5),
      ),
    );

    final trimmed = imageUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return fallbackContainer;
    }

    // 1. Handle valid base64 data:image/* URIs safely (e.g., admin-uploaded product photos)
    final dataBytes = tryDecodeDataUri(trimmed);
    if (dataBytes != null) {
      return ClipRRect(
        borderRadius: resolvedRadius,
        child: Image.memory(
          dataBytes,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => fallbackContainer,
        ),
      );
    }

    // 2. Validate http/https URL before rendering
    if (!isValidNetworkImageUrl(trimmed)) {
      return fallbackContainer;
    }

    // 3. On Flutter Web (CanvasKit), Image.network uses the browser's native image
    // decoding pipeline and avoids CachedNetworkImage's Web texImage2D/makeTexture
    // race conditions during scrolling and fast rebuilds.
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: resolvedRadius,
        child: Image.network(
          trimmed,
          width: safeWidth,
          height: safeHeight,
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return _buildPlaceholder(safeWidth, safeHeight);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(safeWidth, safeHeight);
          },
          errorBuilder: (context, error, stackTrace) => fallbackContainer,
        ),
      );
    }

    // 4. On Mobile/Desktop native platforms, preserve CachedNetworkImage disk caching
    return ClipRRect(
      borderRadius: resolvedRadius,
      child: CachedNetworkImage(
        imageUrl: trimmed,
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildPlaceholder(safeWidth, safeHeight),
        errorWidget: (context, url, error) => fallbackContainer,
      ),
    );
  }
}
