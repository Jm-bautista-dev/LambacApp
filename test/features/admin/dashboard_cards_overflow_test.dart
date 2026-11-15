import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/analytics/data/models/customer_activity_summary.dart';
import 'package:lambac_app/features/analytics/data/models/product_performance_model.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_customer_feedback_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_customer_insights_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_header.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_messages_summary_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_order_pipeline_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_product_performance_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/executive_team_performance_card.dart';
import 'package:lambac_app/features/admin/presentation/widgets/dashboard/operational_alerts_section.dart';

void main() {
  Widget wrapWithScaffold(Widget child, {required double width}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  const viewports = [118.0, 150.0, 220.0, 320.0, 360.0, 384.0, 390.0, 412.0, 800.0];

  group('ExecutiveHeader overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveHeader(unreadInboxCount: 3),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lambac Coffee Roastery'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('OperationalAlertsSection overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const OperationalAlertsSection(
              unreadInboxCount: 3,
              pendingOrdersCount: 2,
              preparingOrdersCount: 4,
              products: [],
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Needs Your Attention'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveProductPerformanceCard overflow regression tests', () {
    const mockProducts = [
      ProductPerformanceModel(
        productId: 'prod-1',
        productName: 'Signature Benguet Arabica Roast',
        categoryName: 'Whole Bean',
        quantitySold: 42,
        revenueGenerated: 16800.0,
        percentageOfTotalRevenue: 34.5,
      ),
      ProductPerformanceModel(
        productId: 'prod-2',
        productName: 'Sagada Dark Roast Reserve',
        categoryName: 'Whole Bean',
        quantitySold: 28,
        revenueGenerated: 11200.0,
        percentageOfTotalRevenue: 23.0,
      ),
    ];

    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveProductPerformanceCard(
              topProducts: mockProducts,
              catalogProducts: [],
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Product & Roast Performance'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveCustomerFeedbackCard overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveCustomerFeedbackCard(),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Customer Satisfaction & Feedback'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveCustomerInsightsCard overflow regression tests', () {
    const mockActivity = CustomerActivitySummary(
      uniqueCustomersCount: 380,
      repeatCustomersCount: 260,
      averageOrderFrequency: 2.7,
    );

    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveCustomerInsightsCard(
              customerActivity: mockActivity,
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Customer Activity & Retention'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveTeamPerformanceCard overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveTeamPerformanceCard(
              totalOrdersToday: 65,
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Team & Barista Performance'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveMessagesSummaryCard overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveMessagesSummaryCard(
              unreadCount: 4,
              conversations: [],
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Messages Requiring Attention'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ExecutiveOrderPipelineCard overflow regression tests', () {
    for (final width in viewports) {
      testWidgets('Renders without overflow at width ${width}px', (tester) async {
        await tester.pumpWidget(
          wrapWithScaffold(
            const ExecutiveOrderPipelineCard(
              pendingCount: 3,
              preparingCount: 5,
              readyCount: 2,
              completedCount: 28,
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Live Order Fulfillment Pipeline'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
