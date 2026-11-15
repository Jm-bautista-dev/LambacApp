import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Modal Bottom Sheet for Changing Password
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return AppBottomSheet.show<bool>(
      context,
      title: 'Change Password',
      child: const ChangePasswordSheet(),
    );
  }

  @override
  ConsumerState<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await ref.read(authNotifierProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (mounted) setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (_) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        AppToast.success(context, 'Password changed successfully.');
        Navigator.of(context).pop(true);
      },
      failure: (failure) {
        _currentPasswordController.clear();
        AppToast.error(context, failure.userFriendlyMessage);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Current Password',
            hint: '••••••••',
            controller: _currentPasswordController,
            isPassword: true,
            validator: (v) => Validators.required(v, 'Please enter your current password'),
            prefix: const Icon(Icons.lock_outline_rounded, size: 20),
          ),
          AppSpacing.vSpaceLg,
          AppTextField(
            label: 'New Password',
            hint: '•••••••• (min. 8 characters)',
            controller: _newPasswordController,
            isPassword: true,
            validator: Validators.password,
            prefix: const Icon(Icons.lock_reset_rounded, size: 20),
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
            text: 'Update Password',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleChangePassword,
          ),
          AppSpacing.vSpaceMd,
        ],
      ),
    );
  }
}
