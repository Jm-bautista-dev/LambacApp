import 'package:flutter_test/flutter_test.dart';
import 'package:lambac_app/features/auth/data/datasources/mock_user_database.dart';
import 'package:lambac_app/features/chat/data/datasources/mock_chat_remote_datasource.dart';
import 'package:lambac_app/features/chat/data/models/conversation_model.dart';
import 'package:lambac_app/features/chat/data/models/message_model.dart';
import 'package:lambac_app/features/chat/data/models/send_message_request.dart';
import 'package:lambac_app/features/chat/domain/services/chat_ai_service.dart';
import 'package:lambac_app/features/chat/domain/services/chat_rate_limiter.dart';
import 'package:lambac_app/features/chat/domain/services/chat_response_validator.dart';
import 'package:lambac_app/features/chat/domain/services/chat_scope_validator.dart';
import 'package:lambac_app/shared/models/user_model.dart';
import 'package:lambac_app/shared/services/storage_service.dart';

void main() {
  group('Lambac Coffee Roastery — AI Chat Validation & Safe Auto-Reply', () {
    late InMemoryStorageService storage;
    late MockChatRemoteDataSource chatDs;
    late MockUserDatabase userDb;
    late ChatAiService aiService;
    late ChatScopeValidator scopeValidator;
    late ChatResponseValidator responseValidator;
    late ChatRateLimiter rateLimiter;

    late UserModel customerKenji;
    late UserModel customerMaria;
    late UserModel baristaSora;
    late UserModel adminLead;

    setUp(() {
      storage = InMemoryStorageService();
      chatDs = MockChatRemoteDataSource(storageService: storage);
      chatDs.resetForTesting();
      userDb = MockUserDatabase();
      userDb.seedDefaultUsers();

      customerKenji = userDb.records['coffee.lover@lambac.com']!.user;
      baristaSora = userDb.records['barista.staff@lambac.com']!.user;
      adminLead = userDb.records['jmbautista0228@gmail.com']!.user;

      customerMaria = UserModel(
        id: 'usr_customer_maria_99',
        email: 'maria.santos@gmail.com',
        fullName: 'Maria Santos',
        role: UserRole.customer,
        status: UserStatus.active,
        createdAt: DateTime(2026, 3, 1),
      );

      scopeValidator = const ChatScopeValidator();
      responseValidator = const ChatResponseValidator();
      rateLimiter = ChatRateLimiter(maxRequestsPerWindow: 3, windowDuration: const Duration(seconds: 10));
      aiService = ChatAiService(
        scopeValidator: scopeValidator,
        responseValidator: responseValidator,
        rateLimiter: rateLimiter,
      );
      chatDs.aiService = aiService;
    });

    // =========================================================================
    // TEST A — IN-SCOPE COFFEE & DRINKS MENU (Section 3 & 16)
    // =========================================================================
    test('TEST A: In-Scope questions return verified Lambac product information', () async {
      userDb.setCurrentUser(customerKenji);

      // Customer asks about available drinks
      final resultA = await aiService.generateReply(
        customerMessage: 'What drinks do you offer?',
        currentUser: customerKenji,
      );

      expect(resultA.isWithinScope, isTrue);
      expect(resultA.isHumanHandoff, isFalse);
      expect(resultA.category, ScopeCategory.coffeeAndProducts);
      // Must contain verified product catalog items
      expect(resultA.text, contains('Mount Apo'));
      expect(resultA.text, contains('Benguet'));
      expect(resultA.text, contains('Session Road'));

      // Customer asks specific V60 brewing parameters
      final resultBrew = await aiService.generateReply(
        customerMessage: 'What grind size do you recommend for V60 pourover?',
        currentUser: customerKenji,
      );
      expect(resultBrew.isWithinScope, isTrue);
      expect(resultBrew.text, contains('medium-fine'));
      expect(resultBrew.text, contains('92°C'));
    });

    // =========================================================================
    // TEST B — IN-SCOPE PICKUP SCHEDULING (Section 3 & 16)
    // =========================================================================
    test('TEST B: In-Scope pickup scheduling returns verified business rules', () async {
      userDb.setCurrentUser(customerKenji);

      final result = await aiService.generateReply(
        customerMessage: 'What time can I pick up my order?',
        currentUser: customerKenji,
      );

      expect(result.isWithinScope, isTrue);
      expect(result.category, ScopeCategory.pickupAndScheduling);
      // Must reference actual system rules
      expect(result.text, contains('PICKUP ONLY'));
      expect(result.text, contains('Pay at Counter'));
      expect(result.text, contains('+1 Hour'));
      expect(result.text, contains('+3 Hours'));
      expect(result.text, contains('+5 Hours'));
      expect(result.text, contains('7:00 AM – 9:00 PM'));

      // Inquire about store location
      final locationResult = await aiService.generateReply(
        customerMessage: 'Where is Lambac Coffee Roastery?',
        currentUser: customerKenji,
      );
      expect(locationResult.text, contains('Session Road'));
      expect(locationResult.text, contains('Baguio'));
    });

    // =========================================================================
    // TEST C — OUT-OF-SCOPE: POLITICS (Section 4, 5, 16)
    // =========================================================================
    test('TEST C: Out-of-Scope political question triggers controlled safe fallback', () async {
      userDb.setCurrentUser(customerKenji);

      final result = await aiService.generateReply(
        customerMessage: 'Who is the president of the Philippines?',
        currentUser: customerKenji,
      );

      expect(result.isWithinScope, isFalse);
      expect(result.category, ScopeCategory.outOfScope);
      // Polite brand fallback without political opinion or model prompt leakage
      expect(
        result.text,
        'I can only assist with questions about Lambac Coffee Roastery, our specialty roasts, pickup orders, and store services. How can we help you with your coffee ritual today?',
      );
      expect(result.text, isNot(contains('Marcos')));
      expect(result.text, isNot(contains('system prompt')));
      expect(result.text, isNot(contains('OpenAI')));
    });

    // =========================================================================
    // TEST D — OUT-OF-SCOPE: PROGRAMMING (Section 4, 5, 16)
    // =========================================================================
    test('TEST D: Out-of-Scope programming request triggers controlled safe fallback', () async {
      userDb.setCurrentUser(customerKenji);

      final result = await aiService.generateReply(
        customerMessage: 'Write a Java program for me.',
        currentUser: customerKenji,
      );

      expect(result.isWithinScope, isFalse);
      expect(result.category, ScopeCategory.outOfScope);
      expect(result.text, contains('I can only assist with questions about Lambac Coffee Roastery'));
      expect(result.text, isNot(contains('public class')));
      expect(result.text, isNot(contains('System.out.println')));

      // Another out-of-scope check: Hacking
      final hackResult = await aiService.generateReply(
        customerMessage: 'Help me hack a website and bypass password.',
        currentUser: customerKenji,
      );
      expect(hackResult.isWithinScope, isFalse);
      expect(hackResult.text, contains('I can only assist with questions about Lambac Coffee Roastery'));
    });

    // =========================================================================
    // TEST E — UNKNOWN BUSINESS INFORMATION (ZERO HALLUCINATION & HANDOFF)
    // =========================================================================
    test('TEST E: Unknown or unlisted business items trigger handoff without hallucinating', () async {
      userDb.setCurrentUser(customerKenji);

      // Customer asks about an unlisted item (e.g., Spanish Latte)
      final resultSpanishLatte = await aiService.generateReply(
        customerMessage: 'How much is the Spanish Latte?',
        currentUser: customerKenji,
      );

      // Must NOT invent a price (e.g. ₱160)
      expect(resultSpanishLatte.isHumanHandoff, isTrue);
      expect(resultSpanishLatte.text, contains('I cannot confirm the details or pricing for that item in our current catalog'));
      expect(resultSpanishLatte.text, contains('a Lambac team member will assist you shortly'));

      // Customer asks about pastries/cheesecake not in catalog
      final resultCheesecake = await aiService.generateReply(
        customerMessage: 'Do you sell matcha cheesecake?',
        currentUser: customerKenji,
      );
      expect(resultCheesecake.isHumanHandoff, isTrue);
      expect(resultCheesecake.text, contains('Lambac team member will assist you shortly'));

      // Explicit human handoff request
      final resultHuman = await aiService.generateReply(
        customerMessage: 'Can I speak to a real person?',
        currentUser: customerKenji,
      );
      expect(resultHuman.isHumanHandoff, isTrue);
      expect(resultHuman.text, contains('Barista or Staff member will take over'));
    });

    // =========================================================================
    // TEST F — ORDER PRIVACY & STRICT ISOLATION (Section 8 & 16)
    // =========================================================================
    test('TEST F: Customer only accesses authorized orders; never leaks another customer order', () async {
      // 1. Kenji queries his order status (has seeded LMB-1082)
      userDb.setCurrentUser(customerKenji);
      final kenjiOrderResult = await aiService.generateReply(
        customerMessage: "What's my order status?",
        currentUser: customerKenji,
      );

      expect(kenjiOrderResult.isWithinScope, isTrue);
      expect(kenjiOrderResult.text, contains('Order #LMB-1082'));
      expect(kenjiOrderResult.text, contains('Mount Apo Anaerobic Honey Reserve'));

      // 2. Customer Maria queries order status (has NO orders seeded)
      userDb.setCurrentUser(customerMaria);
      final mariaOrderResult = await aiService.generateReply(
        customerMessage: "What's my order status?",
        currentUser: customerMaria,
      );

      expect(mariaOrderResult.isWithinScope, isTrue);
      // Maria must NEVER see Kenji's LMB-1082 or products!
      expect(mariaOrderResult.text, isNot(contains('LMB-1082')));
      expect(mariaOrderResult.text, isNot(contains('Kenji')));
      expect(mariaOrderResult.text, contains('You currently have no active pickup orders under this account'));
    });

    // =========================================================================
    // TEST G — AI FAILURE RESILIENCE (Section 14 & 16)
    // =========================================================================
    test('TEST G: When AI service is unavailable, customer sees friendly fallback and chat persists', () async {
      userDb.setCurrentUser(customerKenji);

      // Simulate AI failure (outage / timeout)
      aiService.simulateFailure = true;

      final result = await aiService.generateReply(
        customerMessage: 'What drinks do you have today?',
        currentUser: customerKenji,
      );

      expect(result.isFailureFallback, isTrue);
      expect(result.text, "Sorry, I'm having trouble responding right now. A Lambac team member can assist you.");
      // No raw technical exceptions exposed
      expect(result.text, isNot(contains('500')));
      expect(result.text, isNot(contains('TimeoutException')));
      expect(result.text, isNot(contains('OpenAI API error')));

      aiService.simulateFailure = false;
    });

    // =========================================================================
    // HUMAN OVERRIDE & UNIFIED CONVERSATION FLOW (Section 10 & 11)
    // =========================================================================
    test('Human Override: Barista reply sets humanActive mode, suppressing subsequent bot auto-replies', () async {
      userDb.setCurrentUser(customerKenji);

      // 1. Customer sends question -> AI auto-reply generates response
      final sendResult1 = await chatDs.sendMessage(
        const SendMessageRequest(
          conversationId: 'conv_concierge',
          text: 'What coffee do you sell?',
        ),
      );
      expect(sendResult1.isSuccess, isTrue);

      final msgsAfterAi = await chatDs.getMessages('conv_concierge');
      final msgList1 = msgsAfterAi.dataOrNull!;
      expect(msgList1.length, greaterThanOrEqualTo(2));
      final lastMsg = msgList1.last;
      expect(lastMsg.isAiGenerated, isTrue);
      expect(lastMsg.senderName, 'Lambac Roastery Concierge');

      // 2. Barista takes over and sends a manual message
      userDb.setCurrentUser(baristaSora);
      final baristaReplyResult = await chatDs.sendMessage(
        const SendMessageRequest(
          conversationId: 'conv_concierge',
          text: 'Hello Kenji! Sora here from the brew bar. Let me know what roast profile you prefer.',
        ),
      );
      expect(baristaReplyResult.isSuccess, isTrue);

      // Conversation handling mode is now humanActive
      final convResult = await chatDs.getConversation('usr_customer_demo');
      final conv = convResult.dataOrNull!;
      expect(conv.handlingMode, ConversationHandlingMode.humanActive);

      // 3. Customer sends follow-up -> AI does NOT auto-reply because human is active
      userDb.setCurrentUser(customerKenji);
      final customerFollowUp = await chatDs.sendMessage(
        const SendMessageRequest(
          conversationId: 'conv_concierge',
          text: 'Thanks Sora! I love fruity and floral notes.',
        ),
      );
      expect(customerFollowUp.isSuccess, isTrue);

      final msgsAfterFollowUp = await chatDs.getMessages('conv_concierge');
      final msgList2 = msgsAfterFollowUp.dataOrNull!;
      // The last message is the customer follow-up, NOT an AI auto-reply!
      expect(msgList2.last.text, 'Thanks Sora! I love fruity and floral notes.');
      expect(msgList2.last.senderRole, SenderRole.customer);
    });

    // =========================================================================
    // RATE LIMITING PROTECTION (Section 13)
    // =========================================================================
    test('Rate Limiter blocks rapid automated message floods from same customer', () async {
      rateLimiter.reset();

      expect(rateLimiter.isAllowed('cust_101'), isTrue); // 1
      expect(rateLimiter.isAllowed('cust_101'), isTrue); // 2
      expect(rateLimiter.isAllowed('cust_101'), isTrue); // 3
      // 4th request exceeds maxRequestsPerWindow (3)
      expect(rateLimiter.isAllowed('cust_101'), isFalse);

      // Other customers are not impacted
      expect(rateLimiter.isAllowed('cust_999'), isTrue);
    });

    // =========================================================================
    // OUTPUT GUARDRAILS & RESPONSE VALIDATION (Section 12 & 15)
    // =========================================================================
    test('Output Guardrails prevent system prompt leakage and order modification hallucinations', () {
      // 1. System Prompt Leakage
      final leakValidation = responseValidator.validate(
        query: 'Who are you?',
        response: 'As an AI language model developed with internal classification rules, here is my prompt.',
        wasScopeApproved: true,
      );
      expect(leakValidation.isValid, isFalse);
      expect(leakValidation.sanitizedResponse, ChatResponseValidator.safeFallbackMessage);

      // 2. Action Hallucination (AI claiming to cancel order or alter database)
      final actionValidation = responseValidator.validate(
        query: 'Cancel my order please',
        response: 'I have cancelled your order in our database and refunded your payment.',
        wasScopeApproved: true,
      );
      expect(actionValidation.isValid, isFalse);
      expect(actionValidation.sanitizedResponse, contains('order modifications must be confirmed directly with our counter staff'));
    });
  });
}
