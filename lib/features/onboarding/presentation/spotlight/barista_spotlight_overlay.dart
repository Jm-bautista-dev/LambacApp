import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/spotlight_step_model.dart';
import 'barista_spotlight_provider.dart';
import 'spotlight_background_effect.dart';
import 'spotlight_instructional_card.dart';
import 'spotlight_keys.dart';

export 'inverted_spotlight_clipper.dart';
export 'spotlight_background_effect.dart';
/// around the unblurred spotlight cutout.
class BaristaSpotlightBorderPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final SpotlightShape shape;
  final Color glowColor;
  final Color accentColor;
  final double pulseValue;

  const BaristaSpotlightBorderPainter({
    required this.targetRect,
    this.borderRadius = 14.0,
    this.shape = SpotlightShape.roundedRect,
    required this.glowColor,
    this.accentColor = AppColors.cremaGold,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (targetRect.isEmpty || targetRect == Rect.zero) return;

    final RRect rrect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(borderRadius),
    );

    // 1. Soft breathing operational matcha-amber glow halo
    final double glowSpread = 7.0 + (5.0 * pulseValue);
    final double glowAlpha = 0.28 + (0.20 * pulseValue);

    final Paint glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (2.0 * pulseValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSpread);

    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      canvas.drawCircle(targetRect.center, radius + 1.0, glowPaint);
    } else {
      canvas.drawRRect(rrect, glowPaint);
    }

    // 2. Crisp, refined matcha-sage / gold accent border
    final Paint borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (shape == SpotlightShape.circle) {
      final double radius = max(targetRect.width, targetRect.height) / 2.0;
      canvas.drawCircle(targetRect.center, radius, borderPaint);
    } else {
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BaristaSpotlightBorderPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shape != shape ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pulseValue != pulseValue;
  }
}

/// Hit-test barrier that lets touches inside the spotlight hole pass directly through
/// to the underlying interactive widget while absorbing touches outside to prevent accidental orders changes.
class _BaristaSpotlightHitTestBarrier extends SingleChildRenderObjectWidget {
  final Rect? targetRect;
  final bool allowTargetInteraction;

  const _BaristaSpotlightHitTestBarrier({
    required this.targetRect,
    this.allowTargetInteraction = true,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBaristaSpotlightHitTestBarrier(
      targetRect: targetRect,
      allowTargetInteraction: allowTargetInteraction,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderBaristaSpotlightHitTestBarrier renderObject) {
    renderObject
      ..targetRect = targetRect
      ..allowTargetInteraction = allowTargetInteraction;
  }
}

class _RenderBaristaSpotlightHitTestBarrier extends RenderProxyBox {
  Rect? targetRect;
  bool allowTargetInteraction;

  _RenderBaristaSpotlightHitTestBarrier({
    required this.targetRect,
    required this.allowTargetInteraction,
    RenderBox? child,
  }) : super(child);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (allowTargetInteraction && targetRect != null && targetRect!.contains(position)) {
      // Allows user to interact directly with the targeted control
      return false;
    }
    // Absorbs touches outside the hole to prevent background side-effects
    return super.hitTest(result, position: position) || true;
  }
}

/// Full-screen interactive Spotlight Coach-Mark Overlay for Barista / Staff Operations onboarding
class BaristaSpotlightOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const BaristaSpotlightOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<BaristaSpotlightOverlay> createState() => _BaristaSpotlightOverlayState();
}

class _BaristaSpotlightOverlayState extends ConsumerState<BaristaSpotlightOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final AnimationController _transitionController;

  Rect? _currentRect;
  Rect? _previousRect;
  Animation<Rect?>? _rectAnimation;

  int _lastStepIndex = -1;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchToken++;
    _pulseController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Immediate dynamic recalculation of target coordinates when browser or viewport resizes
    final step = ref.read(baristaSpotlightProvider).currentStep;
    if (step != null && mounted) {
      final targetContext = step.targetKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        final rect = _calculateTargetBounds(targetContext, step);
        if (rect != null && rect != _currentRect) {
          setState(() {
            _currentRect = rect;
          });
        }
      }
    }
  }

  void _updateTargetRect(SpotlightStepModel? step) {
    if (step == null) {
      if (mounted) {
        setState(() {
          _currentRect = null;
          _previousRect = null;
        });
      }
      return;
    }

    if (step.targetBranchIndex != null && mounted) {
      setState(() {
        _currentRect = null;
      });
    }

    final token = ++_searchToken;
    _locateAndAnimateTarget(step, token, attempt: 0);
  }

  Future<void> _locateAndAnimateTarget(SpotlightStepModel step, int token,
      {int attempt = 0}) async {
    if (!mounted || token != _searchToken) return;

    var targetContext = step.targetKey.currentContext;

    // Graceful fallback resolution if primary key context is not yet mounted
    if (targetContext == null || !targetContext.mounted) {
      // Clear leftover rect on attempt 0 so old coordinates don't momentarily linger
      if (attempt == 0 && mounted) {
        setState(() {
          _currentRect = null;
        });
      }

      if (attempt < 5) {
        // Wait for tab switch / order queue layout to complete (up to 250ms)
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (mounted && token == _searchToken) {
          await _locateAndAnimateTarget(step, token, attempt: attempt + 1);
        }
        return;
      }

      // Check context fallbacks if available
      if (step.targetKey == SpotlightKeys.staffInboxBanner) {
        targetContext = SpotlightKeys.staffNavConcierge.currentContext;
      } else if (step.targetKey == SpotlightKeys.staffShiftControls) {
        targetContext = SpotlightKeys.staffNavShift.currentContext;
      } else if (step.targetKey == SpotlightKeys.staffFirstOrderCard ||
          step.targetKey == SpotlightKeys.staffOrderPickupBadge ||
          step.targetKey == SpotlightKeys.staffOrderActionBtn) {
        targetContext = SpotlightKeys.staffFirstOrderCard.currentContext ??
            SpotlightKeys.staffQueueHeader.currentContext;
      }

      // If still not mounted (e.g., empty queue where no order exists), do NOT highlight arbitrary coords
      if (targetContext == null || !targetContext.mounted) {
        if (mounted && token == _searchToken) {
          setState(() {
            _currentRect = null;
          });
        }
        return;
      }
    }

    // Target context is mounted
    if (step.scrollTargetIntoView) {
      try {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          alignment: 0.35,
        );
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted || token != _searchToken || !targetContext.mounted) return;
    }

    final rect = _calculateTargetBounds(targetContext, step);
    if (rect != null) {
      _animateToRect(rect);
    } else if (attempt < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted && token == _searchToken) {
        await _locateAndAnimateTarget(step, token, attempt: attempt + 1);
      }
    }
  }

  Rect? _calculateTargetBounds(BuildContext targetContext, SpotlightStepModel step) {
    try {
      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || !renderBox.attached) return null;

      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx - step.padding.left,
        offset.dy - step.padding.top,
        size.width + step.padding.horizontal,
        size.height + step.padding.vertical,
      );
    } catch (_) {
      return null;
    }
  }

  void _animateToRect(Rect target) {
    if (!mounted) return;

    if (_currentRect == null) {
      setState(() {
        _currentRect = target;
        _previousRect = target;
      });
      return;
    }

    _previousRect = _rectAnimation != null && _transitionController.isAnimating
        ? _rectAnimation!.value ?? _currentRect
        : _currentRect;

    _rectAnimation = RectTween(
      begin: _previousRect,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _currentRect = target;
    _transitionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final spotlightState = ref.watch(baristaSpotlightProvider);
    final notifier = ref.read(baristaSpotlightProvider.notifier);

    // Synchronize animation controllers
    if (spotlightState.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!spotlightState.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    // Step changed: recalculate geometry
    if (spotlightState.isActive && spotlightState.currentStepIndex != _lastStepIndex) {
      _lastStepIndex = spotlightState.currentStepIndex;
      _updateTargetRect(spotlightState.currentStep);
    } else if (!spotlightState.isActive) {
      _lastStepIndex = -1;
      _currentRect = null;
    }

    final currentStep = spotlightState.currentStep;

    final activeRect = _rectAnimation != null && _transitionController.isAnimating
        ? _rectAnimation!.value ?? _currentRect
        : _currentRect;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Continuous scroll tracking: keeps spotlight hole aligned with order card at 60fps
        if (spotlightState.isActive && currentStep != null && !_transitionController.isAnimating) {
          final targetContext = currentStep.targetKey.currentContext;
          if (targetContext != null && targetContext.mounted) {
            final rect = _calculateTargetBounds(targetContext, currentStep);
            if (rect != null && rect != _currentRect) {
              setState(() {
                _currentRect = rect;
              });
            }
          }
        }
        return false;
      },
      child: Stack(
        children: [
          // 1. Underlying Main Barista UI
          widget.child,

          // 2. Interactive Spotlight Scrim & Unblurred Cutout Layer
          if (spotlightState.isActive && currentStep != null) ...[
            Positioned.fill(
              child: _BaristaSpotlightHitTestBarrier(
                targetRect: activeRect,
                allowTargetInteraction: true,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _transitionController]),
                  builder: (context, _) {
                    final rect = _rectAnimation != null && _transitionController.isAnimating
                        ? _rectAnimation!.value ?? _currentRect
                        : _currentRect;

                    return Stack(
                      children: [
                        // A. True Physical Spotlight Hole: 4 peripheral blur strips + even-odd dimming scrim
                        // Guarantees zero blur and zero tint over the target, keeping it 100% sharp.
                        Positioned.fill(
                          child: SpotlightBackgroundEffect(
                            targetRect: rect,
                            borderRadius: currentStep.borderRadius,
                            shape: currentStep.shape,
                            scrimColor: const Color(0xD80B120E), // Deep roasted matcha obsidian scrim
                            blurSigma: 4.5,
                          ),
                        ),

                        // B. Glowing matcha-sage perimeter & crisp golden accent border
                        if (rect != null && !rect.isEmpty && rect != Rect.zero)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BaristaSpotlightBorderPainter(
                                targetRect: rect,
                                borderRadius: currentStep.borderRadius,
                                shape: currentStep.shape,
                                glowColor: AppColors.matchaSageLight,
                                accentColor: AppColors.cremaGold,
                                pulseValue: _pulseController.value,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 3. Intelligently Positioned Instructional Tooltip Card
            _buildPositionedCard(
              context,
              spotlightState,
              currentStep,
              notifier,
              activeRect,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionedCard(
    BuildContext context,
    BaristaSpotlightState state,
    SpotlightStepModel currentStep,
    BaristaSpotlightNotifier notifier,
    Rect? activeRect,
  ) {
    final screenSize = MediaQuery.sizeOf(context);
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;

    const double cardEstimatedHeight = 320.0;
    const double cardVerticalSpacing = 12.0;

    double top;
    bool placeBelow = true;

    final maxSafeTop = (screenSize.height - cardEstimatedHeight - bottomInset - 16).clamp(topInset + 8, double.infinity);

    if (activeRect != null && !activeRect.isEmpty) {
      final spaceBelow = screenSize.height - activeRect.bottom - bottomInset;
      final spaceAbove = activeRect.top - topInset;

      if (currentStep.preferredPosition == TooltipPosition.below) {
        placeBelow = spaceBelow >= cardEstimatedHeight + cardVerticalSpacing || spaceBelow >= spaceAbove;
      } else if (currentStep.preferredPosition == TooltipPosition.above) {
        placeBelow = spaceAbove < cardEstimatedHeight + cardVerticalSpacing && spaceBelow > spaceAbove;
      } else {
        placeBelow = spaceBelow >= spaceAbove;
      }

      if (placeBelow) {
        final desiredTop = activeRect.bottom + cardVerticalSpacing;
        if (desiredTop > maxSafeTop && spaceAbove >= cardEstimatedHeight) {
          top = (activeRect.top - cardEstimatedHeight - cardVerticalSpacing).clamp(topInset + 8, maxSafeTop);
        } else {
          top = desiredTop.clamp(topInset + 8, maxSafeTop);
        }
      } else {
        final desiredTop = activeRect.top - cardEstimatedHeight - cardVerticalSpacing;
        if (desiredTop < topInset + 8 && spaceBelow >= cardEstimatedHeight) {
          top = (activeRect.bottom + cardVerticalSpacing).clamp(topInset + 8, maxSafeTop);
        } else {
          top = desiredTop.clamp(topInset + 8, maxSafeTop);
        }
      }
    } else {
      // Default safe center when geometry is pending or queue is currently empty
      top = (screenSize.height - cardEstimatedHeight) / 2;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, placeBelow ? 0.06 : -0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('barista_spotlight_step_${currentStep.id}'),
            child: SpotlightInstructionalCard(
              step: currentStep,
              totalSteps: state.totalSteps,
              isFirstStep: state.isFirstStep,
              isLastStep: state.isLastStep,
              onNext: () => notifier.nextStep(),
              onPrevious: () => notifier.previousStep(),
              onSkip: () => notifier.skipTour(),
              isDark: true,
              finishButtonText: 'Finish Tour',
            ),
          ),
        ),
      ),
    );
  }
}
