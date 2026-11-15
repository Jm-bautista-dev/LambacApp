import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/providers/pending_action_provider.dart';
import '../providers/auth_provider.dart';

/// Production Customer Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectPath;
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.redirectPath,
    this.initialEmail,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting || ref.read(authNotifierProvider).isAuthenticating) return;

    // Immediately lock submission to prevent duplicate concurrent taps
    setState(() {
      _isSubmitting = true;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Standard email & password authentication (NO OTP on login)
    final result = await authNotifier.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    result.when(
      success: (user) {
        // Restore and synchronize any pending cart action
        final pendingAction = ref.read(pendingActionProvider.notifier).consumePendingAction();
        if (pendingAction != null) {
          ref.read(cartNotifierProvider.notifier).addItem(
            product: pendingAction.product,
            sizeVariant: pendingAction.sizeVariant,
            grindVariant: pendingAction.grindVariant,
            quantity: pendingAction.quantity,
            specialInstructions: pendingAction.specialInstructions,
          );

          final sizeName = pendingAction.sizeVariant?.name ?? '250g Bag';
          final grindName = pendingAction.grindVariant?.name ?? 'Whole Bean';

          AppToast.cartItemAdded(
            context,
            productName: pendingAction.product.name,
            quantity: pendingAction.quantity,
            variantDescription: '$sizeName, $grindName',
            onViewCart: () => context.push(AppRoutes.cart),
          );
        } else {
          AppToast.success(context, 'Welcome back, ${user.fullName.isNotEmpty ? user.fullName.split(' ').first : 'Coffee Lover'}!');
        }

        final redirect = widget.redirectPath;
        if (redirect != null && redirect.isNotEmpty) {
          context.go(redirect);
        } else if (user.isAdmin) {
          context.go(AppRoutes.adminDashboard);
        } else if (user.isEmployee || user.isBarista) {
          context.go(AppRoutes.staffOrders);
        } else {
          context.go(AppRoutes.home);
        }
      },
      failure: (failure) {
        setState(() {
          if (failure is ValidationFailure && failure.fieldErrors != null) {
            _emailError = failure.fieldErrors!['email']?.first;
            _passwordError = failure.fieldErrors!['password']?.first;
          }
          _generalError = failure.message;
        });
      },
    );
  }

  void _handleGuest() {
    ref.read(authNotifierProvider.notifier).continueAsGuest();
    AppToast.info(context, 'Browsing as Guest Coffee Enthusiast');
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticating = _isSubmitting || authState.isAuthenticating;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Sign In',
        showBackButton: true,
      ),
      body: CinematicRoasteryBackground.hero(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Signature 3D Coffee Bean Visual Anchor
                      Center(
                        child: Lambac3DCoffeeBean(
                          size: 78,
                          roastStyle: isDark ? BeanRoastStyle.mediumRoast : BeanRoastStyle.honeyGold,
                          intensity: BeanIntensity.high,
                          enableFloating: true,
                          enableRotation: true,
                          showGlow: true,
                          speedMultiplier: 1.0,
                        ),
                      ),
                      AppSpacing.vSpaceMd,
                    Text(
                      'Welcome to\nLambac Roastery',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        height: 1.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Text(
                      'Sign in to access your custom roast profiles, pickup tracking, and member beans points.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.vSpaceXxl,

                    // General Error Banner (if any)
                    if (_generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.error.withValues(alpha: 0.15) : AppColors.errorBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vSpaceLg,
                    ],

                    // Email Input Field
                    AppTextField(
                      label: 'Email Address',
                      hint: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      validator: Validators.email,
                      prefix: const Icon(Icons.email_outlined, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    // Password Input Field
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      errorText: _passwordError,
                      validator: Validators.loginPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: isAuthenticating ? null : (_) => _handleLogin(),
                      prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isAuthenticating
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    AppSpacing.vSpaceLg,

                    // Primary Sign In Button (Prevents duplicate taps)
                    AppButton.primary(
                      text: 'Sign In',
                      isLoading: isAuthenticating,
                      onPressed: isAuthenticating ? null : _handleLogin,
                    ),
                    AppSpacing.vSpaceMd,

                    // Guest Mode Button
                    AppButton.outlined(
                      text: 'Continue as Guest',
                      onPressed: isAuthenticating ? null : _handleGuest,
                    ),
                    AppSpacing.vSpaceXxl,

                    // Register Navigation Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: isAuthenticating ? null : () => context.push(AppRoutes.register),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vSpaceLg,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
