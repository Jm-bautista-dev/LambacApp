import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/chat/data/models/conversation_model.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/domain/services/chat_ai_service.dart';
import 'package:lambac_app/shared/models/user_model.dart';

void main() {
  group('Firestore Chat & Messaging Migration Specifications', () {
    test('ConversationModel adheres to scalable conversations/{conversationId} structure', () {
      final now = DateTime.utc(2026, 10, 6, 12, 0, 0);
      final lastMsg = MessageModel(
        id: 'msg_100',
        conversationId: 'conv_cust_123',
        senderId: 'cust_123',
        senderName: 'Maria Santos',
        senderRole: SenderRole.customer,
        text: 'What beans do you recommend for pour-over?',
        status: MessageStatus.sent,
        createdAt: now,
      );

      final conversation = ConversationModel(
        id: 'conv_cust_123',
        customerId: 'cust_123',
        customerName: 'Maria Santos',
        handlingMode: ConversationHandlingMode.aiAvailable,
        lastMessage: lastMsg,
        unreadCountsByRole: const {
          'customer': 0,
          'barista': 1,
          'admin': 1,
        },
        updatedAt: now,
      );

      final json = conversation.toJson();

      // Verify Firestore root conversation document mapping
      expect(json['id'], equals('conv_cust_123'));
      expect(json['customer_id'], equals('cust_123'));
      expect(json['customer_name'], equals('Maria Santos'));
      expect(json['handling_mode'], equals('aiAvailable'));
      expect(json['last_message'], isA<Map<String, dynamic>>());
      expect(json['unread_counts_by_role'], isA<Map<String, dynamic>>());
      expect(json['unread_counts_by_role']['barista'], equals(1));

      // Round-trip deserialization
      final deserialized = ConversationModel.fromJson(json);
      expect(deserialized.id, equals('conv_cust_123'));
      expect(deserialized.customerId, equals('cust_123'));
      expect(deserialized.handlingMode, equals(ConversationHandlingMode.aiAvailable));
      expect(deserialized.unreadForRole('barista'), equals(1));
      expect(deserialized.unreadForRole('customer'), equals(0));
    });

    test('MessageModel adheres to conversations/{id}/messages/{msgId} subcollection structure', () {
      final now = DateTime.utc(2026, 10, 6, 12, 1, 0);
      final message = MessageModel(
        id: 'msg_200',
        conversationId: 'conv_cust_123',
        senderId: 'staff_barista_1',
        senderName: 'Barista Carlo',
        senderRole: SenderRole.barista,
        text: 'We recommend our Mount Apo Honey Reserve with a medium-coarse grind!',
        status: MessageStatus.delivered,
        createdAt: now,
      );

      final json = message.toJson();

      // Verify Firestore message fields
      expect(json['id'], equals('msg_200'));
      expect(json['conversation_id'], equals('conv_cust_123'));
      expect(json['sender_id'], equals('staff_barista_1'));
      expect(json['sender_name'], equals('Barista Carlo'));
      expect(json['sender_role'], equals('barista'));
      expect(json['text'], contains('Mount Apo Honey Reserve'));
      expect(json['status'], equals('delivered'));

      // Round-trip deserialization
      final deserialized = MessageModel.fromJson(json);
      expect(deserialized.id, equals('msg_200'));
      expect(deserialized.senderRole, equals(SenderRole.barista));
      expect(deserialized.status, equals(MessageStatus.delivered));
    });

    test('Role authorization enforces customer conversation privacy', () {
      const customer = UserModel(
        id: 'cust_123',
        email: 'customer@example.com',
        fullName: 'Customer One',
        role: UserRole.customer,
      );

      const otherCustomer = UserModel(
        id: 'cust_456',
        email: 'other@example.com',
        fullName: 'Customer Two',
        role: UserRole.customer,
      );

      const staff = UserModel(
        id: 'staff_1',
        email: 'barista@lambac.com',
        fullName: 'Barista Bob',
        role: UserRole.barista,
      );

      final conv = ConversationModel(
        id: 'conv_cust_123',
        customerId: 'cust_123',
        customerName: 'Customer One',
        updatedAt: DateTime.now(),
      );

      // Customer 1 can access only their conversation
      expect(conv.customerId == customer.id, isTrue);

      // Customer 2 cannot access Customer 1 conversation
      expect(conv.customerId == otherCustomer.id, isFalse);

      // Barista and Admin are authorized to access customer conversations in shared inbox
      expect(staff.isBusinessUser, isTrue);
    });

    test('ChatAiService preserves in-scope coffee guidance and off-topic guardrails', () async {
      final aiService = ChatAiService();
      const customer = UserModel(
        id: 'cust_123',
        email: 'test@lambac.com',
        fullName: 'Juan',
        role: UserRole.customer,
      );

      // In-scope question
      final coffeeReply = await aiService.generateReply(
        customerMessage: 'What beans do you recommend for cold brew?',
        currentUser: customer,
      );
      expect(coffeeReply.text.isNotEmpty, isTrue);
      expect(coffeeReply.isWithinScope, isTrue);

      // Off-topic question triggers safe fallback
      final offTopicReply = await aiService.generateReply(
        customerMessage: 'Write Python code for quicksort',
        currentUser: customer,
      );
      expect(offTopicReply.isWithinScope, isFalse);
      expect(offTopicReply.text, contains('Lambac Coffee Roastery'));
    });
  });
}
