import 'dart:async';
import 'dart:convert';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../auth/data/datasources/mock_user_database.dart';
import '../../../orders/data/datasources/mock_order_remote_datasource.dart';
import '../../../products/data/datasources/mock_product_remote_datasource.dart';
import '../../domain/services/chat_ai_service.dart';
import '../../domain/services/chat_realtime_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/send_message_request.dart';
import 'chat_remote_datasource.dart';

/// Secure, Multi-Tenant Mock Data Source for Concierge Chat
/// Enforces Server-Side Ownership, RBAC, Persistent Storage, and Shared Staff/Admin Access
class MockChatRemoteDataSource implements ChatRemoteDataSource {
  static final MockChatRemoteDataSource _instance = MockChatRemoteDataSource._internal();
  factory MockChatRemoteDataSource({StorageService? storageService}) {
    if (storageService != null) {
      _instance._storageService = storageService;
    }
    return _instance;
  }

  StorageService? _storageService;
  final ChatRealtimeService _realtimeService = ChatRealtimeService();
  ChatAiService _aiService = ChatAiService(
    productDataSource: MockProductRemoteDataSource(),
    orderDataSource: MockOrderRemoteDataSource(),
  );

  ChatAiService get aiService => _aiService;
  set aiService(ChatAiService service) => _aiService = service;

  final Map<String, ConversationModel> _conversations = {};
  final Map<String, String> _customerConversations = {}; // customerId -> conversationId
  final Map<String, List<MessageModel>> _messages = {}; // conversationId -> messages

  static const String _convPrefix = 'lambac_chat_conv_';
  static const String _msgsPrefix = 'lambac_chat_msgs_';

  Duration latency = const Duration(milliseconds: 30);

  Future<void> _simulateLatency() async {
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
  }

  MockChatRemoteDataSource._internal({StorageService? storageService})
      : _storageService = storageService {
    _seedDefaultChatData();
  }

  void setStorageService(StorageService storageService) {
    _storageService = storageService;
  }

  void _seedDefaultChatData() {
    const demoCustomerId = 'usr_customer_demo';
    const demoConvId = 'conv_concierge';

    final demoConv = ConversationModel(
      id: demoConvId,
      customerId: demoCustomerId,
      customerName: 'Kenji Takahashi',
      participantName: 'Hiro (Head Roaster)',
      orderReference: 'ORDER #LMB-1082 • Preparing',
      isOnline: true,
      isTyping: false,
      unreadCountsByRole: const {'barista': 0, 'admin': 0, 'customer': 0},
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    );

    _conversations[demoConvId] = demoConv;
    _customerConversations[demoCustomerId] = demoConvId;
    _customerConversations['usr_lambac_1001'] = demoConvId;

    final defaultMsgs = [
      MessageModel(
        id: 'msg_101',
        conversationId: demoConvId,
        senderId: 'barista_hiro',
        senderName: 'Hiro (Head Roaster)',
        senderRole: SenderRole.barista,
        text: 'Konnichiwa! Welcome to Lambac Roastery Concierge. I am Hiro, your head roaster today. How can we elevate your coffee ritual?',
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      MessageModel(
        id: 'msg_102',
        conversationId: demoConvId,
        senderId: demoCustomerId,
        senderName: 'Kenji Takahashi',
        senderRole: SenderRole.customer,
        text: 'Hi Hiro! Could you recommend a grind size for the Mount Apo Honey Anaerobic on a standard V60 02 dripper?',
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      MessageModel(
        id: 'msg_103',
        conversationId: demoConvId,
        senderId: 'barista_hiro',
        senderName: 'Hiro (Head Roaster)',
        senderRole: SenderRole.barista,
        text: 'For Mount Apo Anaerobic, we recommend a medium-fine grind (around 18 clicks on Comandante C40 or 500-600 microns). Brew with 92°C water at 1:15 ratio to highlight wild raspberry & blossom honey notes!',
        status: MessageStatus.read,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];

    _messages[demoConvId] = defaultMsgs;
  }

  /// Helper to get current authenticated user
  UserModel? get _currentUser => MockUserDatabase().currentUser;

  Future<void> _loadFromStorageIfAvailable(String customerId) async {
    if (_storageService == null) return;
    try {
      final convJson = await _storageService!.getString('$_convPrefix$customerId');
      if (convJson != null && convJson.isNotEmpty) {
        final convMap = jsonDecode(convJson) as Map<String, dynamic>;
        final conv = ConversationModel.fromJson(convMap);
        _conversations[conv.id] = conv;
        _customerConversations[customerId] = conv.id;

        final msgsJson = await _storageService!.getString('$_msgsPrefix${conv.id}');
        if (msgsJson != null && msgsJson.isNotEmpty) {
          final msgsList = jsonDecode(msgsJson) as List;
          _messages[conv.id] = msgsList
              .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
  }

  Future<void> _persistConversationAndMessages(String conversationId, String customerId) async {
    if (_storageService == null) return;
    try {
      final conv = _conversations[conversationId];
      if (conv != null) {
        await _storageService!.setString(
          '$_convPrefix$customerId',
          jsonEncode(conv.toJson()),
        );
      }
      final msgs = _messages[conversationId];
      if (msgs != null) {
        await _storageService!.setString(
          '$_msgsPrefix$conversationId',
          jsonEncode(msgs.map((m) => m.toJson()).toList()),
        );
      }
    } catch (_) {}
  }

  @override
  Future<Result<List<ConversationModel>, AppFailure>> getConversations() async {
    await _simulateLatency();

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access inbox.'),
      );
    }

    // Customer or unprivileged staff without manageInbox can only view their own conversation
    if (user.isCustomer || (user.isEmployee && !user.hasPermission(EmployeePermission.manageInbox))) {
      final ownConv = await getConversation(user.id);
      return ownConv.when(
        success: (conv) => Result.success([conv]),
        failure: (fail) => Result.failure(fail),
      );
    }

    // Staff (Barista) & Admin: Shared customer conversation inbox
    await getConversation('usr_customer_demo');

    final map = <String, ConversationModel>{};
    for (final c in _conversations.values) {
      if (c.customerId != 'usr_admin_default' && c.customerId != 'usr_employee_demo') {
        map[c.id] = c;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Result.success(List.unmodifiable(list));
  }

  @override
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]) async {
    await _simulateLatency();

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access chat.'),
      );
    }

    // RBAC: Customer can never query another customer's conversation
    if (user.isCustomer && customerId != null && customerId.isNotEmpty && customerId != user.id) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You can only access your own conversations.'),
      );
    }

    // RBAC: Staff without manageInbox permission cannot access other customers' conversations
    if (user.isEmployee && customerId != null && customerId.isNotEmpty && customerId != user.id && !user.hasPermission(EmployeePermission.manageInbox)) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You do not have permission to access other customer conversations.'),
      );
    }

    // Determine target customer ID:
    final targetCustomerId = (customerId == null || customerId.isEmpty || user.isCustomer)
        ? (user.isCustomer ? user.id : 'usr_customer_demo')
        : customerId;

    // Attempt restoring from persistent storage
    await _loadFromStorageIfAvailable(targetCustomerId);

    // Look up existing conversation or create new isolated conversation for this customer
    var convId = _customerConversations[targetCustomerId];
    if (convId == null || !_conversations.containsKey(convId)) {
      convId = 'conv_cust_$targetCustomerId';
      final newConv = ConversationModel(
        id: convId,
        customerId: targetCustomerId,
        customerName: targetCustomerId == 'usr_customer_demo'
            ? 'Kenji Takahashi'
            : (user.id == targetCustomerId ? user.fullName : 'Customer #$targetCustomerId'),
        participantName: 'Hiro (Head Roaster)',
        orderReference: targetCustomerId == 'usr_customer_demo' ? 'ORDER #LMB-1082 • Preparing' : null,
        isOnline: true,
        isTyping: false,
        unreadCount: 0,
        unreadCountsByRole: const {'barista': 0, 'admin': 0, 'customer': 0},
        updatedAt: DateTime.now(),
      );
      _conversations[convId] = newConv;
      _customerConversations[targetCustomerId] = convId;

      // Seed initial welcoming barista greeting for brand new customer conversation
      _messages[convId] = [
        MessageModel(
          id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: convId,
          senderId: 'barista_hiro',
          senderName: 'Hiro (Head Roaster)',
          senderRole: SenderRole.barista,
          text: 'Konnichiwa, ${user.fullName}! Welcome to Lambac Roastery Concierge. How can we elevate your coffee ritual today?',
          status: MessageStatus.read,
          createdAt: DateTime.now(),
        ),
      ];

      await _persistConversationAndMessages(convId, targetCustomerId);
    }

    final conv = _conversations[convId]!;
    final convMessages = _messages[convId] ?? [];
    final updatedConv = conv.copyWith(
      lastMessage: convMessages.isNotEmpty ? convMessages.last : null,
      updatedAt: convMessages.isNotEmpty ? convMessages.last.createdAt : conv.updatedAt,
    );

    _conversations[convId] = updatedConv;
    return Result.success(updatedConv);
  }

  String _resolveConversationId(String id) {
    if (_conversations.containsKey(id)) return id;
    if (id.startsWith('conv_cust_')) {
      final custId = id.substring('conv_cust_'.length);
      final mappedId = _customerConversations[custId];
      if (mappedId != null && _conversations.containsKey(mappedId)) {
        return mappedId;
      }
    }
    return id;
  }

  @override
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  }) async {
    await _simulateLatency();

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to view messages.'),
      );
    }

    final convId = _resolveConversationId(conversationId);

    // Try restoring from storage if not in memory
    if (!_messages.containsKey(convId) && _storageService != null) {
      final msgsJson = await _storageService!.getString('$_msgsPrefix$convId');
      if (msgsJson != null && msgsJson.isNotEmpty) {
        final msgsList = jsonDecode(msgsJson) as List;
        _messages[convId] = msgsList
            .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    final conversation = _conversations[convId];
    if (conversation == null) {
      return const Result.failure(
        NotFoundFailure(message: 'Conversation not found.'),
      );
    }

    // SERVER-SIDE RBAC & IDOR PROTECTION:
    // If caller is a customer, verify conversation ownership
    final isDemoAlias = (user.id == 'usr_customer_demo' || user.id == 'usr_lambac_1001') &&
        (conversation.customerId == 'usr_customer_demo' || conversation.customerId == 'usr_lambac_1001');
    if (user.isCustomer && conversation.customerId != user.id && !isDemoAlias) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: Access denied to this conversation.'),
      );
    }

    // Employee must have manageInbox permission to access customer conversations
    if (user.isEmployee && conversation.customerId != user.id && !user.hasPermission(EmployeePermission.manageInbox)) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You do not have permission to access this customer conversation.'),
      );
    }

    final allMsgs = List<MessageModel>.from(_messages[convId] ?? []);
    allMsgs.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    if (allMsgs.isEmpty || limit <= 0) {
      return Result.success(List.unmodifiable(allMsgs));
    }

    // Pagination: Slice newest first, preserving chronological order
    final total = allMsgs.length;
    final end = total - (page - 1) * limit;
    final start = (end - limit).clamp(0, total);
    if (end <= 0) {
      return const Result.success([]);
    }
    final paged = allMsgs.sublist(start, end.clamp(0, total));

    return Result.success(List.unmodifiable(paged));
  }

  @override
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request) async {
    await _simulateLatency();

    final user = _currentUser;
    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to send messages.'),
      );
    }

    // Simulate failure if query explicitly requests fail_test
    if (request.text.contains('fail_test')) {
      return const Result.failure(
        NetworkFailure(message: 'Failed to send message. Please check connection.'),
      );
    }

    final convId = _resolveConversationId(request.conversationId);
    final conversation = _conversations[convId];
    if (conversation == null) {
      return const Result.failure(
        NotFoundFailure(message: 'Conversation not found.'),
      );
    }

    // SERVER-SIDE RBAC & IDOR PROTECTION:
    // Customer cannot inject messages into another customer's conversation
    if (user.isCustomer && conversation.customerId != user.id) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You cannot send messages to another customer\'s conversation.'),
      );
    }

    // Employee must have manageInbox permission to reply to customer conversations
    if (user.isEmployee && conversation.customerId != user.id && !user.hasPermission(EmployeePermission.manageInbox)) {
      return const Result.failure(
        ForbiddenFailure(message: 'Forbidden: You do not have permission to send messages in this customer conversation.'),
      );
    }

    // Derive sender identity: Customer, Admin, or Barista
    final SenderRole senderRole;
    if (user.isCustomer) {
      senderRole = SenderRole.customer;
    } else if (user.isAdmin) {
      senderRole = SenderRole.admin;
    } else {
      senderRole = SenderRole.barista;
    }

    final sentMsg = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      senderId: user.id,
      senderName: user.fullName,
      senderRole: senderRole,
      text: request.text,
      status: MessageStatus.sent,
      attachmentUrl: request.attachmentUrl,
      createdAt: DateTime.now(),
    );

    _messages.putIfAbsent(convId, () => []).add(sentMsg);

    // Update unread counts per role
    final unreads = Map<String, int>.from(conversation.unreadCountsByRole);
    if (senderRole == SenderRole.customer) {
      unreads['barista'] = (unreads['barista'] ?? 0) + 1;
      unreads['employee'] = (unreads['employee'] ?? 0) + 1;
      unreads['admin'] = (unreads['admin'] ?? 0) + 1;
    } else {
      unreads['customer'] = (unreads['customer'] ?? 0) + 1;
    }

    // Human Override (Section 11):
    // When a human staff member (Barista/Admin) replies, mark handlingMode as humanActive
    final newHandlingMode = (senderRole == SenderRole.barista || senderRole == SenderRole.admin)
        ? ConversationHandlingMode.humanActive
        : conversation.handlingMode;

    // Update conversation metadata
    _conversations[convId] = conversation.copyWith(
      lastMessage: sentMsg,
      updatedAt: sentMsg.createdAt,
      unreadCount: senderRole == SenderRole.customer ? conversation.unreadCount + 1 : conversation.unreadCount,
      unreadCountsByRole: unreads,
      handlingMode: newHandlingMode,
    );

    // 1. Persist to storage
    await _persistConversationAndMessages(convId, conversation.customerId);

    // 2. Broadcast real-time message event (all active screens receive it)
    _realtimeService.notifyMessageSent(sentMsg);

    // 3. AI Assistant Auto-Reply (Section 1, 2, 10, 11)
    // Only triggers if customer sent message, auto-reply is enabled, and human is not actively handling
    if (senderRole == SenderRole.customer &&
        autoReplyEnabled &&
        conversation.handlingMode != ConversationHandlingMode.humanActive) {
      if (latency > Duration.zero) {
        _triggerAiResponseAsync(convId, conversation.customerId, request.text, user);
      } else {
        await _generateAndDispatchAiReply(convId, conversation.customerId, request.text, user);
      }
    }

    return Result.success(sentMsg);
  }

  bool autoReplyEnabled = true;

  void setConversationHandlingMode(String conversationId, ConversationHandlingMode mode) {
    final convId = _resolveConversationId(conversationId);
    final conv = _conversations[convId];
    if (conv != null) {
      _conversations[convId] = conv.copyWith(handlingMode: mode);
    }
  }

  void _triggerAiResponseAsync(
    String convId,
    String customerId,
    String userQuery,
    UserModel currentUser,
  ) {
    _realtimeService.notifyTyping(
      conversationId: convId,
      isTyping: true,
      participantName: 'Lambac Concierge AI',
    );

    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      await _generateAndDispatchAiReply(convId, customerId, userQuery, currentUser);
    });
  }

  Future<MessageModel> _generateAndDispatchAiReply(
    String convId,
    String customerId,
    String userQuery,
    UserModel currentUser,
  ) async {
    _realtimeService.notifyTyping(
      conversationId: convId,
      isTyping: true,
      participantName: 'Lambac Concierge AI',
    );

    final aiResult = await _aiService.generateReply(
      customerMessage: userQuery,
      currentUser: currentUser,
    );

    _realtimeService.notifyTyping(
      conversationId: convId,
      isTyping: false,
      participantName: 'Lambac Concierge AI',
    );

    final aiMsg = MessageModel(
      id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      senderId: 'lambac_concierge_ai',
      senderName: 'Lambac Roastery Concierge',
      senderRole: SenderRole.barista,
      text: aiResult.text,
      status: MessageStatus.read,
      isAiGenerated: true,
      createdAt: DateTime.now(),
    );

    _messages.putIfAbsent(convId, () => []).add(aiMsg);

    final conv = _conversations[convId];
    if (conv != null) {
      final updatedMode = aiResult.isHumanHandoff
          ? ConversationHandlingMode.humanHandoffRequested
          : conv.handlingMode;

      final unreads = Map<String, int>.from(conv.unreadCountsByRole);
      // If AI handed off to human or requested staff help, increment unread for staff
      if (aiResult.isHumanHandoff) {
        unreads['barista'] = (unreads['barista'] ?? 0) + 1;
        unreads['employee'] = (unreads['employee'] ?? 0) + 1;
        unreads['admin'] = (unreads['admin'] ?? 0) + 1;
      }

      _conversations[convId] = conv.copyWith(
        lastMessage: aiMsg,
        updatedAt: aiMsg.createdAt,
        handlingMode: updatedMode,
        unreadCountsByRole: unreads,
      );
    }

    await _persistConversationAndMessages(convId, customerId);
    _realtimeService.notifyMessageSent(aiMsg);

    return aiMsg;
  }

  @override
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId) async {
    await _simulateLatency();

    final user = _currentUser;
    if (user == null) return const Result.success(null);

    final convId = _resolveConversationId(conversationId);
    final conversation = _conversations[convId];
    if (conversation != null) {
      if (user.isCustomer && conversation.customerId != user.id) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: Cannot access this conversation.'),
        );
      }

      final unreads = Map<String, int>.from(conversation.unreadCountsByRole);
      final roleKey = user.role.name;
      unreads[roleKey] = 0;
      if (roleKey == 'employee') {
        unreads['barista'] = 0;
      }
      unreads[user.id] = 0;

      _conversations[convId] = conversation.copyWith(
        unreadCount: user.isCustomer ? 0 : conversation.unreadCount,
        unreadCountsByRole: unreads,
      );
      await _persistConversationAndMessages(convId, conversation.customerId);
    }

    return const Result.success(null);
  }

  @override
  void clearSession() {
    _realtimeService.clearSession();
  }

  /// Reset all chat data for test isolation
  void resetForTesting({bool zeroLatency = true}) {
    if (zeroLatency) {
      latency = Duration.zero;
    }
    autoReplyEnabled = true;
    _aiService = ChatAiService(
      productDataSource: MockProductRemoteDataSource(),
      orderDataSource: MockOrderRemoteDataSource(),
    );
    if (_storageService != null) {
      for (final conv in _conversations.values) {
        _storageService?.remove('$_convPrefix${conv.customerId}');
        _storageService?.remove('$_msgsPrefix${conv.id}');
      }
    }
    _conversations.clear();
    _customerConversations.clear();
    _messages.clear();
    _seedDefaultChatData();
  }
}
