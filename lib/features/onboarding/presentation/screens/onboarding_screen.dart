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
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/tutorial_provider.dart';
import '../spotlight/customer_spotlight_provider.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/tutorial_completion_view.dart';
import '../widgets/tutorial_progress_bar.dart';
import '../widgets/tutorial_skip_dialog.dart';
import '../../domain/models/tutorial_state.dart';
import '../../data/models/tutorial_step_model.dart';

/// Production Customer Interactive Tutorial and Guided Onboarding Screen
class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isReplay;
  final int initialStep;

  const OnboardingScreen({
    super.key,
    this.isReplay = false,
    this.initialStep = 0,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _isCompletedView = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialStep);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      final notifier = ref.read(tutorialNotifierProvider.notifier);

      // 1. Role Check: Strictly prevent Admins and Staff from entering Customer Onboarding
      if (currentUser != null && !currentUser.isGuest) {
        if (currentUser.isAdmin) {
          try { context.go(AppRoutes.adminDashboard); } catch (_) {}
          return;
        } else if (currentUser.isEmployee) {
          try { context.go(AppRoutes.staffOrders); } catch (_) {}
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
    final confirmed = await TutorialSkipDialog.show(context);
    if (confirmed && mounted) {
      await ref.read(tutorialNotifierProvider.notifier).skipTutorial();
      if (mounted) {
        AppToast.info(context, 'You can replay this tutorial anytime from Profile.');
        context.go(AppRoutes.home);
      }
    }
  }

  Future<void> _handleNext(int currentStep, int totalSteps) async {
    if (currentStep < totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      ref.read(tutorialNotifierProvider.notifier).goToStep(currentStep + 1);
    } else {
      // Last step -> mark completed & show celebration screen
      await ref.read(tutorialNotifierProvider.notifier).completeTutorial();
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
      ref.read(tutorialNotifierProvider.notifier).previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tutorialState = ref.watch(tutorialNotifierProvider);
    final notifier = ref.read(tutorialNotifierProvider.notifier);
    final steps = tutorialState.steps;

    if (steps.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStepIndex = tutorialState.currentStepIndex.clamp(0, steps.length - 1);
    final currentStep = steps[currentStepIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: CinematicRoasteryBackground(
        mode: RoasteryAtmosphereMode.warmDiscovery,
        showAmbientParticles: true,
        child: SafeArea(
          child: ResponsiveContentContainer(
            maxWidth: 680,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _isCompletedView
                  ? TutorialCompletionView(
                      isDark: isDark,
                      onStartExploring: () => context.go(AppRoutes.home),
                      onBrowseMenu: () => context.go(AppRoutes.products),
                      onViewAgain: () {
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
      ),
    );
  }

  /// 1. Premium Welcome Screen introducing Lambac Coffee Roastery
  Widget _buildWelcomeIntroduction(
    BuildContext context,
    bool isDark,
    TutorialNotifier notifier,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
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
          AppSpacing.vSpaceMd,

          // 3D Coffee Bean Hero Anchor
          Lambac3DCoffeeBean.hero(
            size: 120,
            roastStyle: BeanRoastStyle.mediumRoast,
            enableFloating: true,
            enableRotation: true,
            showGlow: true,
          ),
          AppSpacing.vSpaceLg,

          Text(
            'Welcome to Lambac Coffee Roastery',
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
              "Let's take a quick interactive tour of everything you can do in the Lambac app: from browsing single-origin micro-lots to scheduling fresh pickups and chatting with our baristas.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AppSpacing.vSpaceLg,

          // Guest Notice Card
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
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can explore our menu without an account. An account is required only when you want to place an order or use customer features.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSpaceXl,

          // Primary Action Buttons
          AppButton.primary(
            text: 'Start Interactive Tour',
            leadingIcon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            onPressed: () {
              notifier.startTour();
            },
          ),
          AppSpacing.vSpaceMd,
          AppButton.outlined(
            text: 'Explore Directly',
            onPressed: () async {
              await notifier.skipTutorial();
              await ref.read(customerSpotlightProvider.notifier).skipTour();
              if (context.mounted) {
                context.go(AppRoutes.home);
              }
            },
          ),
          AppSpacing.vSpaceLg,
        ],
      ),
    );
  }

  /// 2. Interactive Step-by-Step Guided Walkthrough
  Widget _buildInteractiveWalkthrough(
    BuildContext context,
    bool isDark,
    TutorialState tutorialState,
    int currentStepIndex,
    TutorialStepModel currentStep,
    List<TutorialStepModel> steps,
    TutorialNotifier notifier,
  ) {
    final totalSteps = steps.length;
    final isLastStep = currentStepIndex == totalSteps - 1;

    return Column(
      children: [
        // Top Step Progress Bar & Skip Controls
        TutorialProgressBar(
          currentStep: currentStepIndex,
          totalSteps: totalSteps,
          category: currentStep.category,
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
              return TutorialCard(
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
                    leadingIcon: Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
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
