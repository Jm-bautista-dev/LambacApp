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
import '../../../../shared/models/user_model.dart';
import '../../data/models/create_user_request.dart';
import '../providers/account_management_provider.dart';

/// Modal Bottom Sheet for Provisioning or Editing an Employee
class CreateEmployeeSheet extends ConsumerStatefulWidget {
  final UserModel? existingEmployee;

  const CreateEmployeeSheet({
    super.key,
    this.existingEmployee,
  });

  static Future<void> show(BuildContext context, {UserModel? employee}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateEmployeeSheet(existingEmployee: employee),
    );
  }

  @override
  ConsumerState<CreateEmployeeSheet> createState() => _CreateEmployeeSheetState();
}

class _CreateEmployeeSheetState extends ConsumerState<CreateEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  late Set<EmployeePermission> _selectedPermissions;
  bool _mustChangePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isEditMode => widget.existingEmployee != null;

  @override
  void initState() {
    super.initState();
    final emp = widget.existingEmployee;
    _nameController = TextEditingController(text: emp?.fullName ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _phoneController = TextEditingController(text: emp?.phoneNumber ?? '');
    _passwordController = TextEditingController(
      text: isEditMode ? '' : PasswordHasher.generateTemporaryPassword(),
    );

    _selectedPermissions = (emp?.permissions ?? [
      EmployeePermission.manageOrders,
      EmployeePermission.manageInbox,
    ]).toSet();
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

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermissions.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one permission for this employee.');
      return;
    }

    setState(() => _isSubmitting = true);

    if (isEditMode) {
      final updateReq = UpdateUserRequest(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        permissions: _selectedPermissions.toList(),
      );

      final result = await ref
          .read(accountManagementNotifierProvider.notifier)
          .updateUser(widget.existingEmployee!.id, updateReq);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      result.when(
        success: (user) {
          Navigator.pop(context);
          AppToast.success(context, 'Employee details updated successfully.');
        },
        failure: (failure) => setState(() => _errorMessage = failure.message),
      );
    } else {
      final createReq = CreateEmployeeRequest(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        permissions: _selectedPermissions.toList(),
        initialPassword: _passwordController.text.trim(),
        mustChangePassword: _mustChangePassword,
      );

      final result = await ref
          .read(accountManagementNotifierProvider.notifier)
          .createEmployee(createReq);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final initialPassword = _passwordController.text.trim();
      result.when(
        success: (user) {
          Navigator.pop(context);
          AppToast.success(context, 'Employee ${user.fullName} created. Initial Password: $initialPassword');
        },
        failure: (failure) => setState(() => _errorMessage = failure.message),
      );
    }
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
                      color: AppColors.matchaSage.withOpacity(0.18),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: const Icon(Icons.badge_rounded, color: AppColors.matchaSage, size: 22),
                  ),
                  AppSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditMode ? 'Edit Employee Account' : 'Provision Employee Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Configure operational duties & permissions',
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
                hint: 'e.g. Sora Tanaka',
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter employee name' : null,
                prefix: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              AppSpacing.vSpaceMd,

              AppTextField(
                label: 'Email Address',
                hint: 'staff@lambaccoffee.com',
                controller: _emailController,
                isReadOnly: isEditMode, // Email is immutable once created
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                prefix: const Icon(Icons.email_outlined, size: 20),
              ),
              AppSpacing.vSpaceMd,

              AppTextField(
                label: 'Phone Number (Optional)',
                hint: '0918xxxxxxx',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefix: const Icon(Icons.phone_outlined, size: 20),
              ),
              AppSpacing.vSpaceLg,

              // Assigned Operational Permissions
              Text(
                'Assigned Operational Permissions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AppSpacing.vSpaceSm,

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: EmployeePermission.values.map((permission) {
                      final isChecked = _selectedPermissions.contains(permission);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          permission.toFormattedString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedPermissions.add(permission);
                            } else {
                              _selectedPermissions.remove(permission);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              AppSpacing.vSpaceLg,

              if (!isEditMode) ...[
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

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _mustChangePassword,
                  activeColor: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                  title: const Text('Force password change on first login', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Employee must set their permanent password before accessing roastery tools.', style: TextStyle(fontSize: 11)),
                  onChanged: (val) => setState(() => _mustChangePassword = val),
                ),
                AppSpacing.vSpaceLg,
              ],

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
                      text: isEditMode ? 'Save Changes' : 'Create Employee',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _handleSubmit,
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
