import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/chat/presentation/widgets/order_context_chat_header.dart';

void main() {
  group('Order Context Chat Unit & Widget Tests', () {
    testWidgets('OrderContextChatHeader renders order number, status, and total amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderContextChatHeader(
              orderId: 'ord_lmb_1082',
              orderStatusLabel: 'Ready for Pickup',
              orderTotal: 960.0,
            ),
          ),
        ),
      );

      expect(find.text('ORDER CONTEXT:'), findsOneWidget);
      expect(find.text('#ord_lmb_1082'), findsOneWidget);
      expect(find.textContaining('Status: Ready for Pickup'), findsOneWidget);
      expect(find.textContaining('₱960.00'), findsOneWidget);
    });
  });
}
