import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/visuals/cinematic_roastery_background.dart';
import '../../../../core/widgets/visuals/lambac_3d_coffee_bean.dart';
import '../providers/auth_provider.dart';

/// Screen arguments passed during customer OTP registration flow
class RegisterOtpScreenArgs {
  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? maskedEmail;
  final String? debugOtp;

  const RegisterOtpScreenArgs({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.maskedEmail,
    this.debugOtp,
  });
}

/// Dedicated Premium 6-Digit Gmail OTP Email Verification Screen for Customer Registration
class RegisterOtpVerificationScreen extends ConsumerStatefulWidget {
  final RegisterOtpScreenArgs args;
  final bool autoStartCooldown;

  const RegisterOtpVerificationScreen({
    super.key,
    required this.args,
    this.autoStartCooldown = true,
  });

  @override
  ConsumerState<RegisterOtpVerificationScreen> createState() => _RegisterOtpVerificationScreenState();
}

class _RegisterOtpVerificationScreenState extends ConsumerState<RegisterOtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _initialCooldownSeconds = 45;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _cooldownTimer;
  int _secondsRemaining = _initialCooldownSeconds;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _currentDebugOtp;

  @override
  void initState() {
    super.initState();
    _currentDebugOtp = kDebugMode ? widget.args.debugOtp : null;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    if (widget.autoStartCooldown) {
      _startCooldownTimer();
    }
    if (widget.args.email.trim().isEmpty || widget.args.password.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppToast.error(context, 'Registration session expired. Please restart registration.');
          context.go(AppRoutes.register);
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _secondsRemaining = _initialCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _currentOtpCode {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete => _currentOtpCode.length == _otpLength;

  void _onDigitChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    // Handle paste of full 6-digit code
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _otpLength && i < digits.length; i++) {
          _controllers[i].text = digits[i];
        }
        final nextFocusIndex = digits.length < _otpLength ? digits.length : _otpLength - 1;
        _focusNodes[nextFocusIndex].requestFocus();

        if (digits.length >= _otpLength) {
          _handleVerify();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete) {
          _handleVerify();
        }
      }
    }
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].text = '';
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_secondsRemaining > 0 || _isResending || _isVerifying) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = await ref.read(authNotifierProvider.notifier).resendRegisterOtp(widget.args.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    result.when(
      success: (response) {
        setState(() {
          _currentDebugOtp = kDebugMode ? (response.debugOtp ?? _currentDebugOtp) : null;
        });
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
        _startCooldownTimer();
        AppToast.success(context, 'A new verification code has been sent to your email.');
      },
      failure: (failure) {
        setState(() {
          _errorMessage = failure.message;
        });
      },
    );
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final otpCode = _currentOtpCode;
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // 1. Verify 6-digit OTP code against backend
    final verifyResult = await authNotifier.verifyRegisterOtp(
      email: widget.args.email,
      otp: otpCode,
    );

    if (!mounted) return;

    if (verifyResult.isFailure) {
      setState(() {
        _isVerifying = false;
        final failure = verifyResult.failureOrNull;
        if (failure is ValidationFailure && failure.fieldErrors?['otp'] != null) {
          _errorMessage = failure.fieldErrors!['otp']!.first;
        } else {
          _errorMessage = failure?.message ?? 'The verification code is incorrect.';
        }
      });
      return;
    }

    final verificationToken = verifyResult.dataOrNull!.verificationToken;

    // 2. Finalize Customer Account Registration on Backend using valid token
    final registerResult = await authNotifier.register(
      fullName: widget.args.fullName,
      email: widget.args.email,
      password: widget.args.password,
      phoneNumber: widget.args.phoneNumber,
      verificationToken: verificationToken,
    );

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    registerResult.when(
      success: (user) {
        AppToast.success(
          context,
          'Registration successful! Welcome to Lambac Coffee Roastery.',
        );
        context.go(AppRoutes.home);
      },
      failure: (failure) {
        setState(() {
          _errorMessage = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayEmail = widget.args.maskedEmail ?? EmailService.maskEmail(widget.args.email);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Verify Your Email',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Floating Bean
                    Center(
                      child: Lambac3DCoffeeBean(
                        size: 72,
                        roastStyle: isDark ? BeanRoastStyle.mediumRoast : BeanRoastStyle.honeyGold,
                        intensity: BeanIntensity.high,
                        enableFloating: true,
                        enableRotation: true,
                        showGlow: true,
                        speedMultiplier: 1.0,
                      ),
                    ),
                    AppSpacing.vSpaceMd,

                    // Header
                    Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,

                    // Subtitle with Masked Recipient
                    Text(
                      "We've sent a 6-digit verification code to",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.brandAmber.withOpacity(0.15) : AppColors.brandAmber.withOpacity(0.1),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(
                            color: isDark ? AppColors.brandAmber.withOpacity(0.3) : AppColors.brandAmber.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              size: 14,
                              color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                displayEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (kDebugMode && _currentDebugOtp != null) ...[
                      AppSpacing.vSpaceSm,
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              for (int i = 0; i < _otpLength && i < _currentDebugOtp!.length; i++) {
                                _controllers[i].text = _currentDebugOtp![i];
                              }
                              _handleVerify();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.brandAmber.withValues(alpha: 0.15)
                                    : AppColors.brandAmber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.brandAmber.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  const Icon(Icons.vpn_key_rounded, size: 15, color: AppColors.brandAmber),
                                  Text(
                                    'Code: $_currentDebugOtp',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandAmber,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandAmber.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Tap to Fill ⚡',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    AppSpacing.vSpaceLg,

                    Text(
                      'Enter the 6-digit code below',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    AppSpacing.vSpaceMd,

                    // Error Message Banner (if any)
                    if (_errorMessage != null) ...[
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
                                _errorMessage!,
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
                      AppSpacing.vSpaceMd,
                    ],

                    // 6-Digit Individual OTP Input Boxes (Responsive across 320px+ screens)
                    LayoutBuilder(
                      builder: (context, otpConstraints) {
                        final boxWidth = ((otpConstraints.maxWidth - 30) / _otpLength).clamp(36.0, 48.0);
                        final boxHeight = boxWidth < 42 ? 50.0 : 56.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_otpLength, (index) {
                            return _buildDigitBox(
                              index: index,
                              isDark: isDark,
                              hasError: _errorMessage != null,
                              boxWidth: boxWidth,
                              boxHeight: boxHeight,
                            );
                          }),
                        );
                      },
                    ),
                    AppSpacing.vSpaceXxl,

                    // Resend Code Section
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        if (_secondsRemaining > 0)
                          Text(
                            'Resend code in ${_secondsRemaining}s',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _isResending || _isVerifying ? null : _handleResendCode,
                            child: _isResending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                                    ),
                                  ),
                          ),
                      ],
                    ),
                    AppSpacing.vSpaceXxl,

                    // Verify Email Button
                    AppButton.primary(
                      text: _isVerifying ? 'Verifying Code...' : 'Verify Email',
                      isLoading: _isVerifying,
                      onPressed: _isOtpComplete && !_isVerifying ? _handleVerify : null,
                    ),
                    AppSpacing.vSpaceLg,

                    // Back / Change Email
                    Center(
                      child: TextButton.icon(
                        onPressed: _isVerifying ? null : () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Change Email / Edit Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox({
    required int index,
    required bool isDark,
    required bool hasError,
    double boxWidth = 48.0,
    double boxHeight = 56.0,
  }) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: isDark
            ? (isFocused ? AppColors.darkSurfaceElevated : AppColors.darkSurface)
            : (isFocused ? Colors.white : AppColors.lightSurface),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: hasError
              ? AppColors.error
              : (isFocused
                  ? (isDark ? AppColors.brandAmberLight : AppColors.brandAmber)
                  : (hasValue
                      ? (isDark ? AppColors.brandAmber.withOpacity(0.5) : AppColors.brandAmber.withOpacity(0.4))
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder))),
          width: isFocused ? 2.0 : 1.2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.brandAmber.withOpacity(isDark ? 0.25 : 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(), // auxiliary wrapper node for raw keyboard detection
        onKey: (event) => _onKeyDown(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: index == 0 ? 6 : 1, // First box allows pasting 6-digit code
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: hasError
                ? AppColors.error
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          decoration: const InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => _onDigitChanged(index, value),
        ),
      ),
    );
  }
}
