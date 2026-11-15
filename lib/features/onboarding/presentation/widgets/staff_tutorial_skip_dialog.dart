import 'package:flutter/material.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';

/// Lightweight skip confirmation dialog for Barista / Staff operations tutorial
class StaffTutorialSkipDialog {
  StaffTutorialSkipDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await AppDialog.show(
      context,
      title: 'Skip Operations Tour?',
      message: 'You can replay this 20-step Barista & Staff walkthrough anytime from My Shift → Help & Operations Guide.',
      confirmText: 'Skip Tour',
      cancelText: 'Continue Tour',
      icon: Icons.menu_book_rounded,
    );

    return result ?? false;
  }
}
