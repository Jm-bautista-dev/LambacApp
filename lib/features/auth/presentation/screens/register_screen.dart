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
import '../providers/auth_provider.dart';
import 'register_otp_verification_screen.dart';
import '../widgets/password_strength_indicator.dart';

/// Secure Production Customer Registration Screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _fullNameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting) return;

    _clearErrors();

    // 1. Client-side Form Validation
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      // Focus first invalid input field
      if (Validators.fullName(_fullNameController.text) != null) {
        _fullNameFocus.requestFocus();
      } else if (Validators.email(_emailController.text) != null) {
        _emailFocus.requestFocus();
      } else if (_phoneController.text.isNotEmpty && Validators.phone(_phoneController.text) != null) {
        _phoneFocus.requestFocus();
      } else if (Validators.password(_passwordController.text) != null) {
        _passwordFocus.requestFocus();
      } else if (Validators.confirmPassword(_confirmPasswordController.text, _passwordController.text) != null) {
        _confirmPasswordFocus.requestFocus();
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phoneNumber = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;

    // Request 6-digit verification OTP dispatched to customer Gmail
    final result = await authNotifier.requestRegisterOtp(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    result.when(
      success: (response) {
        AppToast.info(
          context,
          'Verification code dispatched to ${response.maskedEmail}',
        );
        context.push(
          AppRoutes.registerOtp,
          extra: RegisterOtpScreenArgs(
            fullName: fullName,
            email: email,
            password: password,
            phoneNumber: phoneNumber,
            maskedEmail: response.maskedEmail,
            debugOtp: response.debugOtp,
          ),
        );
      },
      failure: (failure) {
        setState(() {
          if (failure is ValidationFailure && failure.fieldErrors != null) {
            _fullNameError = failure.fieldErrors!['fullName']?.first;
            _emailError = failure.fieldErrors!['email']?.first;
            _phoneError = failure.fieldErrors!['phoneNumber']?.first;
            _passwordError = failure.fieldErrors!['password']?.first;
            _confirmPasswordError = failure.fieldErrors!['confirmPassword']?.first;

            if (_emailError != null) {
              _emailFocus.requestFocus();
            } else if (_fullNameError != null) {
              _fullNameFocus.requestFocus();
            } else if (_passwordError != null) {
              _passwordFocus.requestFocus();
            }
          } else if (failure is NetworkFailure) {
            _generalError = 'Unable to connect. Please check your internet connection and try again.';
          } else {
            _generalError = failure.message;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isBusy = _isSubmitting || authState.isAuthenticating;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Create Account',
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
                      Center(
                        child: Lambac3DCoffeeBean(
                          size: 74,
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
                        'Join the Lambac\nCoffee Guild',
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
                      'Create your member profile to unlock exclusive micro-lot allocations, roast updates, and loyalty beans points.',
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
                          color: isDark ? AppColors.error.withOpacity(0.15) : AppColors.errorBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.5)),
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

                    // Full Name
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Kenji Takahashi',
                      controller: _fullNameController,
                      focusNode: _fullNameFocus,
                      errorText: _fullNameError,
                      onChanged: (_) {
                        if (_fullNameError != null) setState(() => _fullNameError = null);
                      },
                      validator: Validators.fullName,
                      prefix: const Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    // Email Address
                    AppTextField(
                      label: 'Email Address',
                      hint: 'name@example.com',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      validator: Validators.email,
                      prefix: const Icon(Icons.email_outlined, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    // Mobile Number (Optional for SMS Pickup Alert)
                    AppTextField(
                      label: 'Mobile Number (Optional)',
                      hint: '09123456789',
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      errorText: _phoneError,
                      onChanged: (_) {
                        if (_phoneError != null) setState(() => _phoneError = null);
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.phone(v);
                      },
                      prefix: const Icon(Icons.phone_outlined, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    // Password
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      isPassword: true,
                      errorText: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      validator: Validators.password,
                      prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),

                    // Live Password Strength Indicator & Checklist
                    PasswordStrengthIndicator(password: _passwordController.text),
                    AppSpacing.vSpaceLg,

                    // Confirm Password
                    AppTextField(
                      label: 'Confirm Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      isPassword: true,
                      errorText: _confirmPasswordError,
                      onChanged: (_) {
                        if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                      },
                      validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                      prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                    AppSpacing.vSpaceXxl,

                    // Submit Button
                    AppButton.primary(
                      text: isBusy ? 'Sending Verification Code...' : 'Create Account',
                      isLoading: isBusy,
                      onPressed: isBusy ? null : _handleRegister,
                    ),
                    AppSpacing.vSpaceXl,

                    // Already have an account
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: isBusy ? null : () => context.pop(),
                          child: Text(
                            'Sign In',
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
