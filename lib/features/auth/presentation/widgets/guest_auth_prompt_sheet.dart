import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../cart/domain/models/pending_add_to_cart_action.dart';
import '../../../cart/presentation/providers/pending_action_provider.dart';

/// Shows an Apple/Dribbble-inspired guest authentication prompt bottom sheet
Future<void> showGuestAuthPrompt({
  required BuildContext context,
  required WidgetRef ref,
  String title = 'Sign In to Continue',
  String message = 'Sign in to add items to your cart and place an order.',
  PendingAddToCartAction? pendingAction,
  String? redirectPath,
}) {
  if (pendingAction != null) {
    ref.read(pendingActionProvider.notifier).setPendingAction(pendingAction);
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (modalContext) => GuestAuthPromptSheet(
      title: title,
      message: message,
      pendingAction: pendingAction,
      redirectPath: redirectPath,
    ),
  );
}

/// Modal Bottom Sheet prompting guest users to authenticate while explaining value and preserving intent
class GuestAuthPromptSheet extends ConsumerWidget {
  final String title;
  final String message;
  final PendingAddToCartAction? pendingAction;
  final String? redirectPath;

  const GuestAuthPromptSheet({
    super.key,
    required this.title,
    required this.message,
    this.pendingAction,
    this.redirectPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 540,
        ),
        child: Material(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle Indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AppSpacing.vSpaceMd,

                  // Coffee Icon Header
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.brandAmber.withOpacity(0.2)
                            : AppColors.brandAmber.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.lock_open_rounded,
                        size: 26,
                        color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                      ),
                    ),
                  ),
                  AppSpacing.vSpaceMd,

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  AppSpacing.vSpaceSm,

                  // Explanation Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Pending Item Summary Preview (if applicable)
                  if (pendingAction != null) ...[
                    AppSpacing.vSpaceMd,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                            color: isDark ? AppColors.cremaGold : AppColors.brandAmber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${pendingAction!.quantity}x ${pendingAction!.product.name}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pendingAction!.sizeVariant?.name ?? "250g"} • ${pendingAction!.grindVariant?.name ?? "Whole Bean"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                              borderRadius: AppRadius.radiusPill,
                            ),
                            child: Text(
                              'Will be saved',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.brandAmberLight : AppColors.brandAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  AppSpacing.vSpaceLg,

                  // Primary Action: Log In
                  AppButton.primary(
                    text: 'Log In',
                    leadingIcon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final path = redirectPath != null
                          ? '${AppRoutes.login}?redirect=${Uri.encodeComponent(redirectPath!)}'
                          : AppRoutes.login;
                      context.push(path);
                    },
                  ),
                  AppSpacing.vSpaceSm,

                  // Secondary Action: Create Account
                  AppButton.secondary(
                    text: 'Create Account',
                    leadingIcon: Icon(Icons.person_add_outlined, size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.register);
                    },
                  ),
                  AppSpacing.vSpaceXs,

                  // Tertiary Action: Continue Browsing
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                    child: const Text(
                      'Continue Browsing',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
}
