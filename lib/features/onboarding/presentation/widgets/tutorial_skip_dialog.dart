import 'package:flutter/material.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';

/// Lightweight skip confirmation dialog
class TutorialSkipDialog {
  TutorialSkipDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await AppDialog.show(
      context,
      title: 'Skip the tutorial?',
      message: 'You can always replay this guide anytime from Profile → Help & Guide.',
      confirmText: 'Skip',
      cancelText: 'Continue Tutorial',
      icon: Icons.help_outline_rounded,
    );

    return result ?? false;
  }
}
