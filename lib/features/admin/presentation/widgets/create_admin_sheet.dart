import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/password_hasher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../data/models/create_user_request.dart';
import '../providers/account_management_provider.dart';

/// Modal Bottom Sheet for Provisioning New Administrator
class CreateAdminSheet extends ConsumerStatefulWidget {
  const CreateAdminSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAdminSheet(),
    );
  }

  @override
  ConsumerState<CreateAdminSheet> createState() => _CreateAdminSheetState();
}

class _CreateAdminSheetState extends ConsumerState<CreateAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _mustChangePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.text = PasswordHasher.generateTemporaryPassword();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generateNewPassword() {
    setState(() {
      _passwordController.text = PasswordHasher.generateTemporaryPassword();
    });
  }

  Future<void> _handleCreate() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = CreateAdminRequest(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      initialPassword: _passwordController.text.trim(),
      mustChangePassword: _mustChangePassword,
    );

    final result = await ref.read(accountManagementNotifierProvider.notifier).createAdmin(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final initialPassword = _passwordController.text.trim();
    result.when(
      success: (admin) {
        Navigator.pop(context);
        AppToast.success(context, 'Administrator account for ${admin.fullName} created. Initial Password: $initialPassword');
      },
      failure: (failure) {
        setState(() => _errorMessage = failure.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = screenHeight * 0.9;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxSheetHeight,
        ),
        child: Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
              ),
              AppSpacing.vSpaceLg,

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandAmber.withOpacity(0.15),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandAmber, size: 22),
                  ),
                  AppSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Business Administrator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Grants full roastery management privileges',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceLg,

              // Security Warning Alert
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.brandAmber.withOpacity(0.1) : AppColors.brandAmberLight.withOpacity(0.15),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.brandAmber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brandAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Administrators possess full authority over analytics, forecasting, orders, and staff account management.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vSpaceLg,

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.error.withOpacity(0.15) : AppColors.errorBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                  ),
                ),
                AppSpacing.vSpaceMd,
              ],

              AppTextField(
                label: 'Full Name',
                hint: 'e.g. Maria Santos',
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter administrator full name' : null,
                prefix: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              AppSpacing.vSpaceMd,

              AppTextField(
                label: 'Email Address',
                hint: 'admin@lambaccoffee.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                prefix: const Icon(Icons.email_outlined, size: 20),
              ),
              AppSpacing.vSpaceMd,

              AppTextField(
                label: 'Phone Number (Optional)',
                hint: '0917xxxxxxx',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefix: const Icon(Icons.phone_outlined, size: 20),
              ),
              AppSpacing.vSpaceMd,

              // Initial Temporary Password
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Temporary Initial Password',
                      controller: _passwordController,
                      prefix: const Icon(Icons.key_rounded, size: 20),
                      validator: (val) => val == null || val.length < 8 ? 'Min 8 characters' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: IconButton.outlined(
                      tooltip: 'Copy Temporary Password',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _passwordController.text.trim()));
                        AppToast.info(context, 'Password copied to clipboard.');
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: IconButton.outlined(
                      tooltip: 'Generate New Secure Password',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _generateNewPassword,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceMd,

              // Must Change Password Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _mustChangePassword,
                activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                title: const Text('Force password change on first login', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Admin will be required to set permanent password upon signing in.', style: TextStyle(fontSize: 11)),
                onChanged: (val) => setState(() => _mustChangePassword = val),
              ),
              AppSpacing.vSpaceLg,

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      text: 'Create Admin',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleCreate,
                    ),
                  ),
                ],
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
