import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';

/// Animated Favorite Heart Button with spring bounce
class AppFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final ValueChanged<bool>? onToggle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const AppFavoriteButton({
    super.key,
    this.isFavorite = false,
    this.onToggle,
    this.size = 36.0,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  State<AppFavoriteButton> createState() => _AppFavoriteButtonState();
}

class _AppFavoriteButtonState extends State<AppFavoriteButton>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.spring,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AppFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _controller.forward(from: 0.0);
    widget.onToggle?.call(_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedActiveColor = widget.activeColor ?? AppColors.error;
    final resolvedInactiveColor = widget.inactiveColor ??
        (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    final resolvedBg = widget.backgroundColor ??
        (isDark ? AppColors.darkSurfaceElevated.withOpacity(0.85) : Colors.white.withOpacity(0.85));

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Material(
        color: resolvedBg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: widget.size * 0.52,
                color: _isFavorite ? resolvedActiveColor : resolvedInactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
