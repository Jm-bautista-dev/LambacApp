import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/feedback/app_loading_indicator.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// App Splash Screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _minAnimationElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();

    // Ensure splash visual completes minimum duration
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _minAnimationElapsed = true;
        _evaluateNavigation();
      }
    });
  }

  void _evaluateNavigation() {
    if (_hasNavigated || !_minAnimationElapsed || !mounted) return;

    final authState = ref.read(authNotifierProvider);
    // Never navigate prematurely while session bootstrapping is active
    if (authState.isInitial || authState.isAuthenticating) {
      return;
    }

    _hasNavigated = true;
    final user = authState.user;
    if (user != null && !user.isGuest) {
      if (user.mustChangePassword) {
        context.go(AppRoutes.firstLoginSetup);
        return;
      }
      if (user.isAdmin) {
        context.go(AppRoutes.adminDashboard);
        return;
      } else if (user.isEmployee || user.isBarista) {
        context.go(AppRoutes.staffOrders);
        return;
      }
    }

    // Customer or Guest Session: Explore Lambac Home
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state resolution if minimum animation time already passed
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (!next.isInitial && !next.isAuthenticating) {
        _evaluateNavigation();
      }
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: CinematicRoasteryBackground.hero(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3D Signature Coffee Bean
                  const Lambac3DCoffeeBean.hero(
                    size: 140,
                    roastStyle: BeanRoastStyle.mediumRoast,
                    enableFloating: true,
                    enableRotation: true,
                    showGlow: true,
                  ),
                  AppSpacing.vSpaceXxl,
                  Text(
                    'LAMBAC',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  AppSpacing.vSpaceXs,
                  Text(
                    'COFFEE ROASTERY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.0,
                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                    ),
                  ),
                  AppSpacing.vSpaceSm,
                  Text(
                    'Crafted with intention.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  AppSpacing.vSpaceXxxl,
                  const AppLoadingIndicator(size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
