import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Modal Bottom Sheet for Editing Customer Profile Information
class EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileSheet({
    super.key,
    required this.user,
  });

  static Future<UserModel?> show(BuildContext context, UserModel user) {
    return AppBottomSheet.show<UserModel>(
      context,
      title: 'Edit Member Profile',
      child: EditProfileSheet(user: user),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await ref.read(authNotifierProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        );
    if (mounted) setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (updatedUser) {
        AppToast.success(context, 'Profile updated successfully.');
        Navigator.of(context).pop(updatedUser);
      },
      failure: (failure) {
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
            label: 'Full Name',
            controller: _fullNameController,
            validator: (v) => Validators.required(v, 'Please enter your name'),
            prefix: const Icon(Icons.person_outline_rounded, size: 20),
          ),
          AppSpacing.vSpaceLg,
          AppTextField(
            label: 'Mobile Number',
            hint: '09123456789',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return Validators.phone(v);
            },
            prefix: const Icon(Icons.phone_outlined, size: 20),
          ),
          AppSpacing.vSpaceXxl,
          AppButton.primary(
            text: 'Save Changes',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleSave,
          ),
          AppSpacing.vSpaceMd,
        ],
      ),
    );
  }
}
