import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/onboarding/data/models/admin_tutorial_step_model.dart';
import 'package:lambac_app/features/onboarding/data/models/spotlight_step_model.dart';
import 'package:lambac_app/features/onboarding/data/models/staff_tutorial_step_model.dart';
import 'package:lambac_app/features/onboarding/data/models/tutorial_category.dart';
import 'package:lambac_app/features/onboarding/data/models/tutorial_step_model.dart';
import 'package:lambac_app/features/onboarding/presentation/spotlight/spotlight_instructional_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/admin_tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/staff_tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/tutorial_card.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/admin_tutorial_progress_bar.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/staff_tutorial_progress_bar.dart';
import 'package:lambac_app/features/onboarding/presentation/widgets/tutorial_progress_bar.dart';

void main() {
  group('Live Access Guide Typography & Underline Removal Verification', () {
    testWidgets('1. SpotlightInstructionalCard: Text widgets have no underline decoration', (tester) async {
      final step = SpotlightStepModel(
        id: 'test_step',
        stepNumber: 1,
        categoryTitle: 'COMMAND CENTER',
        title: 'Executive Command Center',
        description: 'Comprehensive operational overview of daily revenue and active orders.',
        targetKey: GlobalKey(),
        icon: Icons.dashboard_rounded,
        keyPoints: const [
          'Live revenue tracking and order count metrics',
          'Fast navigation to kitchen and fulfillment queues',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpotlightInstructionalCard(
              step: step,
              totalSteps: 5,
              isFirstStep: false,
              isLastStep: false,
              onNext: () {},
              onPrevious: () {},
              onSkip: () {},
            ),
          ),
        ),
      );

      // Inspect every Text widget
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.isNotEmpty, isTrue);

      for (final text in textWidgets) {
        final style = text.style;
        if (style != null && style.decoration != null) {
          expect(
            style.decoration,
            isNot(equals(TextDecoration.underline)),
            reason: 'Text "${text.data}" should NOT have underline decoration',
          );
        }
      }
    });

    testWidgets('2. AdminTutorialCard: Typography has no underline decoration', (tester) async {
      const step = AdminTutorialStepModel(
        id: 'admin_1',
        stepNumber: 1,
        chapter: AdminTutorialChapter.dashboard,
        title: 'Admin Management Overview',
        subtitle: 'Manage employees, view reports, and configure store settings.',
        highlightArea: 'Executive Header',
        icon: Icons.admin_panel_settings_rounded,
        visualType: AdminTutorialVisualType.adminDashboardKpis,
        keyPoints: [
          'Review executive dashboard indicators',
          'Verify staff shift schedules',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminTutorialCard(
              step: step,
              isDark: true,
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.isNotEmpty, isTrue);

      for (final text in textWidgets) {
        final style = text.style;
        if (style != null && style.decoration != null) {
          expect(
            style.decoration,
            isNot(equals(TextDecoration.underline)),
            reason: 'Admin tutorial text "${text.data}" should not have underline',
          );
        }
      }
    });

    testWidgets('3. StaffTutorialCard: Typography has no underline decoration', (tester) async {
      const step = StaffTutorialStepModel(
        id: 'staff_1',
        stepNumber: 1,
        category: StaffTutorialCategory.queue,
        title: 'Barista Queue Operations',
        subtitle: 'Process incoming espresso orders and track drink preparation milestones.',
        highlightArea: 'Order Queue',
        icon: Icons.coffee_rounded,
        visualType: StaffTutorialVisualType.orderCardInspection,
        keyPoints: [
          'Accept new orders into active prep queue',
          'Notify customer when drinks are ready',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaffTutorialCard(
              step: step,
              isDark: true,
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.isNotEmpty, isTrue);

      for (final text in textWidgets) {
        final style = text.style;
        if (style != null && style.decoration != null) {
          expect(
            style.decoration,
            isNot(equals(TextDecoration.underline)),
            reason: 'Staff tutorial text "${text.data}" should not have underline',
          );
        }
      }
    });

    testWidgets('4. Customer TutorialCard: Typography has no underline decoration', (tester) async {
      const step = TutorialStepModel(
        id: 'cust_1',
        stepNumber: 1,
        category: TutorialCategory.menu,
        title: 'Welcome to Lambac Roastery',
        subtitle: 'Explore artisan specialty beans and place handcrafted brew orders.',
        highlightArea: 'Artisan Catalog',
        icon: Icons.local_cafe_rounded,
        visualType: TutorialVisualType.productCatalogCard,
        keyPoints: [
          'Browse seasonal roasts and flavor profiles',
          'Customize your cup and bean grind level',
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TutorialCard(
              step: step,
              isDark: true,
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.isNotEmpty, isTrue);

      for (final text in textWidgets) {
        final style = text.style;
        if (style != null && style.decoration != null) {
          expect(
            style.decoration,
            isNot(equals(TextDecoration.underline)),
            reason: 'Customer tutorial text "${text.data}" should not have underline',
          );
        }
      }
    });

    testWidgets('5. Progress Bars: Admin, Staff, and Customer step labels have no underline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AdminTutorialProgressBar(
                  currentStep: 2,
                  totalSteps: 5,
                  chapter: AdminTutorialChapter.dashboard,
                  onBack: () {},
                  onSkip: () {},
                  isDark: true,
                ),
                StaffTutorialProgressBar(
                  currentStep: 1,
                  totalSteps: 4,
                  category: StaffTutorialCategory.queue,
                  onBack: () {},
                  onSkip: () {},
                  isDark: true,
                ),
                TutorialProgressBar(
                  currentStep: 3,
                  totalSteps: 6,
                  category: TutorialCategory.menu,
                  onBack: () {},
                  onSkip: () {},
                  isDark: true,
                ),
              ],
            ),
          ),
        ),
      );

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.isNotEmpty, isTrue);

      for (final text in textWidgets) {
        final style = text.style;
        if (style != null && style.decoration != null) {
          expect(
            style.decoration,
            isNot(equals(TextDecoration.underline)),
            reason: 'Progress bar text "${text.data}" should not have underline',
          );
        }
      }
    });
  });
}
