import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_kpi_section.dart';

void main() {
  Widget buildTestWidget({
    required double width,
    double? height,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: const ExecutiveKpiSection(
              todaySales: 15420.50,
              todayOrdersCount: 42,
              averageOrderValue: 367.15,
              unreadInboxCount: 3,
            ),
          ),
        ),
      ),
    );
  }

  group('ExecutiveKpiSection Layout and Overflow Regression Tests', () {
    testWidgets('Renders properly on standard desktop viewport (800px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 800));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(find.text("TODAY'S ORDERS"), findsOneWidget);
      expect(find.text('AVG ORDER VALUE'), findsOneWidget);
      expect(find.text('UNREAD MESSAGES'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders properly on mobile viewport (390px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 390));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Does not overflow even on narrow constraints (118px width)', (tester) async {
      // 118px previously triggered BoxConstraints(w=90, h=29.6) with childAspectRatio: 2.2
      await tester.pumpWidget(buildTestWidget(width: 118));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Does not overflow under extreme height constraint (54px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 118, height: 54));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Does not overflow under exact error condition (w=90, h=29.6)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 90, height: 29.6));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
