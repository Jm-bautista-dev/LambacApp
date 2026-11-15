import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Apple-Style Bottom Modal Sheet Container with Universal Scroll & Overflow Protection
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailingAction;
  final EdgeInsetsGeometry padding;
  final bool showDragHandle;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.trailingAction,
    this.padding = AppSpacing.cardPadding,
    this.showDragHandle = true,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    Widget? trailingAction,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        trailingAction: trailingAction,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    // Reserve fixed header height (~100px) and insets; scrollable area gets the rest
    final maxScrollableHeight =
        MediaQuery.sizeOf(context).height * 0.88 - 100 - bottomInset;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
        ),
        child: Material(
          color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.topSheetRadius,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // shrink when content is small
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDragHandle) ...[
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: AppRadius.radiusPill,
                      ),
                    ),
                  ),
                ],
                if (title != null || trailingAction != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        if (trailingAction != null) trailingAction!,
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ],
                // ConstrainedBox caps max height while allowing short sheets to stay compact
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxScrollableHeight > 200 ? maxScrollableHeight : 400,
                  ),
                  child: SingleChildScrollView(
                    padding: padding,
                    physics: const BouncingScrollPhysics(),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
}
