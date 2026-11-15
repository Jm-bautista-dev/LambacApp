import 'package:flutter/material.dart';
import '../../../../core/widgets/dialogs/app_dialog.dart';

/// Lightweight skip confirmation dialog for Administrator / BI tutorial
class AdminTutorialSkipDialog {
  AdminTutorialSkipDialog._();

  static Future<bool> show(BuildContext context) async {
    final result = await AppDialog.show(
      context,
      title: 'Skip Executive Tour?',
      message: 'You can replay this complete 22-step Business Intelligence & Operations guide anytime from Admin Profile → Help & Guide.',
      confirmText: 'Skip Tour',
      cancelText: 'Continue Tour',
      icon: Icons.menu_book_rounded,
    );

    return result ?? false;
  }
}
