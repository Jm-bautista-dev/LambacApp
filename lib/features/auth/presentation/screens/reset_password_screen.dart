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
import '../providers/auth_provider.dart';

/// Screen for submitting verification code and setting a new password
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController(text: '123456');
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _tokenError;
  String? _generalError;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _tokenError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = widget.email ?? 'coffee.lover@lambac.com';
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final result = await ref.read(authNotifierProvider.notifier).resetPassword(
          email: email,
          token: token,
          newPassword: newPassword,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (_) {
        AppToast.success(context, 'Password reset successful! Please sign in with your new password.');
        context.go(AppRoutes.login);
      },
      failure: (failure) {
        setState(() {
          if (failure is ValidationFailure && failure.fieldErrors != null) {
            _tokenError = failure.fieldErrors!['token']?.first;
          }
          _generalError = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      appBar: const LambacAppBar(
        title: 'Create New Password',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Verification\n& New Password',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.2,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    AppSpacing.vSpaceSm,
                    Text(
                      'We have sent a verification code to ${widget.email ?? "your email"}. Enter the code below along with your new password.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.vSpaceXxl,

                    if (_generalError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.error.withOpacity(0.15) : AppColors.errorBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.5)),
                        ),
                        child: Text(
                          _generalError!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      AppSpacing.vSpaceLg,
                    ],

                    AppTextField(
                      label: '6-Digit Verification Code',
                      hint: '123456',
                      controller: _tokenController,
                      keyboardType: TextInputType.number,
                      errorText: _tokenError,
                      validator: (v) => Validators.required(v, 'Please enter the verification code'),
                      prefix: const Icon(Icons.pin_outlined, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    AppTextField(
                      label: 'New Password',
                      hint: '•••••••• (min. 8 characters)',
                      controller: _newPasswordController,
                      isPassword: true,
                      validator: Validators.password,
                      prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                    AppSpacing.vSpaceLg,

                    AppTextField(
                      label: 'Confirm New Password',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      validator: (v) => Validators.confirmPassword(v, _newPasswordController.text),
                      prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                    AppSpacing.vSpaceXxl,

                    AppButton.primary(
                      text: 'Update Password & Sign In',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleResetPassword,
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
}
