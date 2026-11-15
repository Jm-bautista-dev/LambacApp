import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/spotlight_step_model.dart';
import 'admin_spotlight_provider.dart';
import 'spotlight_background_effect.dart';
import 'spotlight_instructional_card.dart';

export 'inverted_spotlight_clipper.dart';
export 'spotlight_background_effect.dart';

/// CustomPainter rendering a glowing luxury roastery amber perimeter and
/// crisp accent stroke around the unblurred spotlight cutout.
class SpotlightBorderPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;
  final SpotlightShape shape;
  final Color glowColor;
  final double pulseValue;

  const SpotlightBorderPainter({
    required this.targetRect,
    required this.borderRadius,
    this.shape = SpotlightShape.roundedRect,
    required this.glowColor,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect.isEmpty || targetRect == Rect.zero) return;

    final RRect rrect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(borderRadius),
    );

    // 1. Soft breathing luxury amber glow halo (spread outward)
    final double glowSpread = 7.0 + (5.0 * pulseValue);
    final double glowAlpha = 0.28 + (0.22 * pulseValue);

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

    // 2. Crisp, refined golden accent border
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
  bool shouldRepaint(covariant SpotlightBorderPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shape != shape ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.glowColor != glowColor;
  }
}

/// Custom hit-test barrier: absorbs taps on the outside dimmed backdrop to prevent accidental
/// clicks on background UI, while letting touches inside the spotlight hole fall through to
/// the active target widget.
class _SpotlightHitTestBarrier extends SingleChildRenderObjectWidget {
  final Rect? targetRect;
  final bool allowTargetInteraction;

  const _SpotlightHitTestBarrier({
    required this.targetRect,
    this.allowTargetInteraction = true,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSpotlightHitTestBarrier(
      targetRect: targetRect,
      allowTargetInteraction: allowTargetInteraction,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderSpotlightHitTestBarrier renderObject) {
    renderObject
      ..targetRect = targetRect
      ..allowTargetInteraction = allowTargetInteraction;
  }
}

class _RenderSpotlightHitTestBarrier extends RenderProxyBox {
  Rect? targetRect;
  bool allowTargetInteraction;

  _RenderSpotlightHitTestBarrier({
    this.targetRect,
    this.allowTargetInteraction = true,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If the tap falls inside the active spotlight hole, let it pass through to the real widget
    if (allowTargetInteraction && targetRect != null && targetRect!.contains(position)) {
      return false;
    }
    // Absorbs touches outside the hole
    return super.hitTest(result, position: position) || true;
  }
}

/// Full-screen interactive Spotlight Coach-Mark Overlay for Administrator & Governance onboarding
class AdminSpotlightOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AdminSpotlightOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AdminSpotlightOverlay> createState() => _AdminSpotlightOverlayState();
}

class _AdminSpotlightOverlayState extends ConsumerState<AdminSpotlightOverlay>
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
    _pulseController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Immediate dynamic recalculation of target coordinates when browser or viewport resizes
    final step = ref.read(adminSpotlightProvider).currentStep;
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

    // When switching across navigation branches, clear leftover coordinates so previous screen's rect doesn't linger
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

    final targetContext = step.targetKey.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      // Clear previous rect if target is in a new screen/tab that is currently mounting
      if (attempt == 0 && mounted) {
        setState(() {
          _currentRect = null;
        });
      }
      if (attempt < 10) {
        // Wait for tab switch / scroll view layout build to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (mounted && token == _searchToken) {
          await _locateAndAnimateTarget(step, token, attempt: attempt + 1);
        }
      }
      return;
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
    } else if (attempt < 10) {
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

    if (_currentRect == target) return;

    _previousRect = _currentRect;
    _rectAnimation = RectTween(
      begin: _previousRect,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _transitionController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _currentRect = target;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotlightState = ref.watch(adminSpotlightProvider);
    final notifier = ref.read(adminSpotlightProvider.notifier);

    // Manage pulse controller animation state
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
        // Continuous scroll tracking: keeps spotlight hole aligned with target at 60fps
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
          // 1. Underlying Main Admin UI
          widget.child,

          // 2. Interactive Spotlight Scrim & Unblurred Cutout Layer
          if (spotlightState.isActive && currentStep != null) ...[
            Positioned.fill(
              child: _SpotlightHitTestBarrier(
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
                            scrimColor: const Color(0xD80D0A08), // Luxury deep roasted espresso
                            blurSigma: 4.5,
                          ),
                        ),

                        // B. Glowing roastery amber perimeter & crisp gold accent border
                        if (rect != null && !rect.isEmpty && rect != Rect.zero)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SpotlightBorderPainter(
                                targetRect: rect,
                                borderRadius: currentStep.borderRadius,
                                shape: currentStep.shape,
                                glowColor: AppColors.brandAmberLight,
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
    AdminSpotlightState state,
    SpotlightStepModel currentStep,
    AdminSpotlightNotifier notifier,
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
            key: ValueKey('admin_spotlight_step_${currentStep.id}'),
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
