import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_tutorial_provider.dart';
import '../spotlight/admin_spotlight_provider.dart';
import '../spotlight/barista_spotlight_provider.dart';
import '../spotlight/customer_spotlight_provider.dart';
import '../widgets/admin_tutorial_card.dart';
import '../widgets/admin_tutorial_completion_view.dart';
import '../widgets/admin_tutorial_progress_bar.dart';
import '../widgets/admin_tutorial_skip_dialog.dart';
import '../../data/models/admin_tutorial_step_model.dart';
import '../../domain/models/admin_tutorial_state.dart';

/// Production Administrator & Business Intelligence Interactive Tutorial Screen
class AdminTutorialScreen extends ConsumerStatefulWidget {
  final bool isReplay;
  final int initialStep;

  const AdminTutorialScreen({
    super.key,
    this.isReplay = false,
    this.initialStep = 0,
  });

  @override
  ConsumerState<AdminTutorialScreen> createState() => _AdminTutorialScreenState();
}

class _AdminTutorialScreenState extends ConsumerState<AdminTutorialScreen> {
  late final PageController _pageController;
  bool _isCompletedView = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialStep);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      final notifier = ref.read(adminTutorialNotifierProvider.notifier);

      // 1. Role Check: Strictly ensure only Administrators access this onboarding
      if (currentUser == null || !currentUser.isAdmin) {
        if (currentUser != null && currentUser.isEmployee) {
          try { context.go(AppRoutes.staffOrders); } catch (_) {}
          return;
        } else {
          try { context.go(AppRoutes.home); } catch (_) {}
          return;
        }
      }

      // 2. Initialize replay mode if requested
      if (widget.isReplay) {
        notifier.startReplay(startStep: widget.initialStep);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    final confirmed = await AdminTutorialSkipDialog.show(context);
    if (confirmed && mounted) {
      await ref.read(adminTutorialNotifierProvider.notifier).skipTutorial();
      if (mounted) {
        AppToast.info(context, 'You can replay this guide anytime from Admin Profile.');
        context.go(AppRoutes.adminDashboard);
      }
    }
  }

  Future<void> _handleNext(int currentStep, int totalSteps) async {
    if (currentStep < totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      ref.read(adminTutorialNotifierProvider.notifier).goToStep(currentStep + 1);
    } else {
      // Last step -> mark completed & show celebration screen
      await ref.read(adminTutorialNotifierProvider.notifier).completeTutorial();
      if (mounted) {
        setState(() => _isCompletedView = true);
      }
    }
  }

  void _handlePrevious(int currentStep) {
    if (currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      ref.read(adminTutorialNotifierProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorialState = ref.watch(adminTutorialNotifierProvider);
    final notifier = ref.read(adminTutorialNotifierProvider.notifier);
    final steps = tutorialState.steps;

    if (steps.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStepIndex = tutorialState.currentStepIndex.clamp(0, steps.length - 1);
    final currentStep = steps[currentStepIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12100E) : const Color(0xFFFAF8F5),
      body: SafeArea(
        child: ResponsiveContentContainer(
          maxWidth: 680,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isCompletedView
                ? AdminTutorialCompletionView(
                    isDark: isDark,
                    onOpenDashboard: () => context.go(AppRoutes.adminDashboard),
                    onReplayTutorial: () {
                      setState(() => _isCompletedView = false);
                      notifier.startReplay(startStep: 0);
                      _pageController.jumpToPage(0);
                    },
                  )
                : !tutorialState.hasStartedTour && !widget.isReplay
                    ? _buildWelcomeIntroduction(context, isDark, notifier)
                    : _buildInteractiveWalkthrough(
                        context,
                        isDark,
                        tutorialState,
                        currentStepIndex,
                        currentStep,
                        steps,
                        notifier,
                      ),
          ),
        ),
      ),
    );
  }

  /// 1. Welcome Introduction Screen for Executive BI Hub
  Widget _buildWelcomeIntroduction(
    BuildContext context,
    bool isDark,
    AdminTutorialNotifier notifier,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: _handleSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Spacer(),

        // Executive BI Seal
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF261E16) : const Color(0xFFFAF3EC),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.brandAmber,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandAmber.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_graph_rounded,
            size: 46,
            color: AppColors.brandAmberLight,
          ),
        ),
        AppSpacing.vSpaceXxl,

        Text(
          'Welcome to the Lambac Business Intelligence Hub',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vSpaceMd,

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Let's walk through the tools you use to manage operations, understand business performance, and make data-driven decisions.",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        AppSpacing.vSpaceXxl,

        // Replay explanation reminder banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.9,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: AppColors.brandAmberLight,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You can replay this complete guide anytime from Admin Profile → Help & Guide.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Primary Action Buttons
        AppButton.primary(
          text: 'Start Tour',
          leadingIcon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          onPressed: () {
            notifier.startTour();
          },
        ),
        AppSpacing.vSpaceMd,
        AppButton.outlined(
          text: 'Skip',
          onPressed: _handleSkip,
        ),
        AppSpacing.vSpaceLg,
      ],
    );
  }

  /// 2. Interactive Guided Executive Walkthrough
  Widget _buildInteractiveWalkthrough(
    BuildContext context,
    bool isDark,
    AdminTutorialState tutorialState,
    int currentStepIndex,
    AdminTutorialStepModel currentStep,
    List<AdminTutorialStepModel> steps,
    AdminTutorialNotifier notifier,
  ) {
    final totalSteps = steps.length;
    final isLastStep = currentStepIndex == totalSteps - 1;

    return Column(
      children: [
        // Top Step Progress Bar & Skip Controls
        AdminTutorialProgressBar(
          currentStep: currentStepIndex,
          totalSteps: totalSteps,
          chapter: currentStep.chapter,
          isDark: isDark,
          onBack: currentStepIndex > 0 ? () => _handlePrevious(currentStepIndex) : null,
          onSkip: _handleSkip,
        ),
        AppSpacing.vSpaceSm,

        // Step Content Carousel
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              notifier.goToStep(index);
            },
            itemCount: totalSteps,
            itemBuilder: (context, index) {
              final step = steps[index];
              return AdminTutorialCard(
                step: step,
                isDark: isDark,
              );
            },
          ),
        ),

        // Bottom Navigation Action Bar (Back / Next / Finish)
        Container(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              if (currentStepIndex > 0) ...[
                Expanded(
                  flex: 1,
                  child: AppButton.outlined(
                    text: 'Back',
                    leadingIcon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppColors.brandAmberLight,
                    ),
                    onPressed: () => _handlePrevious(currentStepIndex),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: AppButton.primary(
                  text: isLastStep ? 'Complete Tour' : 'Next Step',
                  leadingIcon: Icon(
                    isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _handleNext(currentStepIndex, totalSteps),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
