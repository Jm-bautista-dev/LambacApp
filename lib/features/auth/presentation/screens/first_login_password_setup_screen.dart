import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bars/lambac_app_bar.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Mandatory First-Login Password Setup Screen
class FirstLoginPasswordSetupScreen extends ConsumerStatefulWidget {
  const FirstLoginPasswordSetupScreen({super.key});

  @override
  ConsumerState<FirstLoginPasswordSetupScreen> createState() => _FirstLoginPasswordSetupScreenState();
}

class _FirstLoginPasswordSetupScreenState extends ConsumerState<FirstLoginPasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(authNotifierProvider.notifier).completeFirstLoginPassword(newPassword);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (user) {
        AppToast.success(context, 'Password set successfully! Welcome, ${user.fullName}.');
        if (!user.hasAcceptedTerms(AppConstants.currentTermsVersion)) {
          context.go(AppRoutes.termsAndConditions);
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
          _errorMessage = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

    return PopScope(
      canPop: false, // Prevent bypassing first login password change
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
        appBar: LambacAppBar(
          title: 'Account Security Setup',
          subtitle: 'Mandatory Initial Password',
          showBackButton: false,
          actions: [
            TextButton(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: const Text('Sign Out', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lock Shield Icon & Security Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.brandAmber.withOpacity(0.12)
                              : AppColors.brandAmber.withOpacity(0.08),
                          borderRadius: AppRadius.radiusLg,
                          border: Border.all(
                            color: isDark ? AppColors.brandAmberDark : AppColors.brandAmberLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: AppColors.brandAmber,
                                size: 24,
                              ),
                            ),
                            AppSpacing.hSpaceMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mandatory Password Setup',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Welcome, ${user?.fullName ?? "Colleague"}. Please create your permanent password to activate your account.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vSpaceXl,

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
                        AppSpacing.vSpaceLg,
                      ],

                      // Form Fields
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'New Permanent Password',
                              hint: 'At least 8 characters',
                              controller: _newPasswordController,
                              isPassword: true,
                              prefix: const Icon(Icons.lock_outline_rounded, size: 20),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please enter a password';
                                if (val.length < 8) return 'Password must be at least 8 characters';
                                return null;
                              },
                            ),
                            AppSpacing.vSpaceLg,
                            AppTextField(
                              label: 'Confirm Permanent Password',
                              hint: 'Repeat your new password',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              prefix: const Icon(Icons.check_circle_outline_rounded, size: 20),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please confirm your password';
                                if (val != _newPasswordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vSpaceXl,

                      AppButton.primary(
                        text: 'Save Password & Enter Lambac',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleSubmit,
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
