import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/monitoring/operational_monitoring_service.dart';
import '../../../../core/network/result.dart';
import '../../../../shared/models/user_model.dart';
import '../../domain/services/chat_ai_service.dart';
import '../../domain/services/chat_realtime_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/send_message_request.dart';
import 'chat_remote_datasource.dart';

/// Production Cloud Firestore Data Source for Customer Concierge Chat & Real-time Messaging
class FirebaseChatRemoteDataSource implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ChatRealtimeService _realtimeService;
  ChatAiService aiService;

  bool autoReplyEnabled = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inboxSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _messageSubscriptions = {};

  FirebaseChatRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChatRealtimeService? realtimeService,
    ChatAiService? aiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _realtimeService = realtimeService ?? ChatRealtimeService(),
        aiService = aiService ?? ChatAiService();

  /// Starts real-time synchronization of inbox conversations ONLY for authorized staff/admin.
  /// Customer accounts are strictly prohibited from collection-wide listening.
  Future<void> startStaffInboxSyncIfAuthorized() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final isStaff = await _isStaffOrAdminUser(user.uid);
    if (!isStaff) return;

    _inboxSubscription?.cancel();
    try {
      _inboxSubscription = _firestore.collection('conversations').snapshots().listen((snapshot) {
        final current = _auth.currentUser;
        if (current == null) {
          _inboxSubscription?.cancel();
          _inboxSubscription = null;
          return;
        }
        for (final docChange in snapshot.docChanges) {
          final conv = _mapDocToConversation(docChange.doc);
          if (conv.lastMessage != null) {
            _realtimeService.notifyMessageSent(conv.lastMessage!);
          }
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  void _subscribeToMessagesRealtime(String convId, {required String authorizedUserId, required bool isStaff}) {
    if (_messageSubscriptions.containsKey(convId)) return; // Prevent duplicate listeners

    try {
      _messageSubscriptions[convId] = _firestore
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .orderBy('created_at', descending: true)
          .limit(30)
          .snapshots()
          .listen((snapshot) {
        // Enforce that current authenticated session has not changed or logged out
        final current = _auth.currentUser;
        if (current == null || (!isStaff && current.uid != authorizedUserId)) {
          _messageSubscriptions[convId]?.cancel();
          _messageSubscriptions.remove(convId);
          return;
        }

        for (final docChange in snapshot.docChanges) {
          if (docChange.type == DocumentChangeType.added || docChange.type == DocumentChangeType.modified) {
            final msg = _mapDocToMessage(docChange.doc);
            _realtimeService.notifyMessageSent(msg);
          }
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void clearSession() {
    _inboxSubscription?.cancel();
    _inboxSubscription = null;
    for (final sub in _messageSubscriptions.values) {
      sub.cancel();
    }
    _messageSubscriptions.clear();
  }

  void dispose() {
    clearSession();
  }

  // ===========================================================================
  // CONVERSATIONS
  // ===========================================================================

  @override
  Future<Result<ConversationModel, AppFailure>> getConversation([String? customerId]) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access concierge chat.'),
      );
    }

    final isStaffOrAdmin = await _isStaffOrAdminUser(user.uid);
    final targetCustomerId = (isStaffOrAdmin && customerId != null && customerId.isNotEmpty)
        ? customerId
        : user.uid;
    final effectiveUserName = (user.uid == targetCustomerId && user.displayName?.isNotEmpty == true)
        ? user.displayName!
        : 'Coffee Enthusiast';

    final convId = 'conv_$targetCustomerId';

    try {
      final docRef = _firestore.collection('conversations').doc(convId);
      var docSnap = await docRef.get();

      if (!docSnap.exists) {
        // Fallback check for legacy ID 'conv_cust_$targetCustomerId'
        final legacyDocRef = _firestore.collection('conversations').doc('conv_cust_$targetCustomerId');
        final legacySnap = await legacyDocRef.get();
        if (legacySnap.exists) {
          docSnap = legacySnap;
        }
      }

      if (docSnap.exists) {
        final conv = _mapDocToConversation(docSnap);
        _subscribeToMessagesRealtime(
          docSnap.id,
          authorizedUserId: user.uid,
          isStaff: isStaffOrAdmin,
        );
        return Result.success(conv);
      }

      // Initialize brand-new conversation with Hiro's welcome message
      final now = DateTime.now();
      final welcomeMsg = MessageModel(
        id: 'msg_welcome_${now.millisecondsSinceEpoch}',
        conversationId: convId,
        senderId: 'barista_hiro',
        senderName: 'Hiro (Head Roaster)',
        senderRole: SenderRole.barista,
        text: 'Konnichiwa, $effectiveUserName! Welcome to Lambac Roastery Concierge. I am Hiro, your head roaster today. How can we elevate your coffee ritual?',
        status: MessageStatus.read,
        createdAt: now,
      );

      final newConv = ConversationModel(
        id: convId,
        customerId: targetCustomerId,
        customerName: effectiveUserName,
        participantName: 'Hiro (Head Roaster)',
        orderReference: 'Concierge Inquiry',
        isOnline: true,
        isTyping: false,
        lastMessage: welcomeMsg,
        unreadCount: 0,
        unreadCountsByRole: const {'barista': 0, 'admin': 0, 'customer': 0},
        handlingMode: ConversationHandlingMode.aiAvailable,
        updatedAt: now,
      );

      // Persist the parent conversation first so subcollection security rules can verify parent ownership
      await docRef.set(newConv.toJson());

      try {
        final msgDocRef = docRef.collection('messages').doc(welcomeMsg.id);
        await msgDocRef.set(welcomeMsg.toJson());
      } catch (_) {
        // Welcome message seed non-fatal; conversation is initialized and accessible
      }

      _subscribeToMessagesRealtime(
        convId,
        authorizedUserId: user.uid,
        isStaff: isStaffOrAdmin,
      );

      return Result.success(newConv);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to access conversation: $e'));
    }
  }

  @override
  Future<Result<List<ConversationModel>, AppFailure>> getConversations() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to access inbox.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('conversations');

      if (!isStaffOrAdmin) {
        // Customers only access their own conversation (single-field index on customer_id)
        query = query.where('customer_id', isEqualTo: effectiveUserId).limit(30);
      } else {
        // Staff syncs real-time inbox
        unawaited(startStaffInboxSyncIfAuthorized());
        query = query.orderBy('updated_at', descending: true).limit(30);
      }

      final snapshot = await query.get();
      List<ConversationModel> list = snapshot.docs
          .map((doc) => _mapDocToConversation(doc))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      // If customer has no conversation yet, auto-create one
      if (list.isEmpty && !isStaffOrAdmin) {
        final single = await getConversation();
        if (single.isSuccess && single.dataOrNull != null) {
          list = [single.dataOrNull!];
        }
      }

      return Result.success(list);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve conversations: $e'));
    }
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  @override
  Future<Result<List<MessageModel>, AppFailure>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
    dynamic lastDocument,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to read messages.'),
      );
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    final convId = _resolveConversationId(conversationId);

    try {
      final convDoc = await _firestore.collection('conversations').doc(convId).get();
      if (!convDoc.exists) {
        return const Result.failure(NotFoundFailure(message: 'Conversation not found.'));
      }

      final conv = _mapDocToConversation(convDoc);
      // Ownership check for customer
      final isOwner = conv.customerId.trim() == effectiveUserId.trim() ||
          convDoc.id == 'conv_$effectiveUserId' ||
          convDoc.id == 'conv_cust_$effectiveUserId' ||
          convDoc.id == convId;
      if (!isStaffOrAdmin && !isOwner) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: Access denied to this conversation.'),
        );
      }

      // Attach bounded realtime Firestore listener for instant live message updates
      _subscribeToMessagesRealtime(
        convId,
        authorizedUserId: effectiveUserId,
        isStaff: isStaffOrAdmin,
      );

      Query<Map<String, dynamic>> query = _firestore
          .collection('conversations')
          .doc(convId)
          .collection('messages')
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDocument is DocumentSnapshot<Map<String, dynamic>>) {
        query = query.startAfterDocument(lastDocument);
      } else if (lastDocument is String && lastDocument.isNotEmpty) {
        try {
          final doc = await _firestore
              .collection('conversations')
              .doc(convId)
              .collection('messages')
              .doc(lastDocument)
              .get();
          if (doc.exists) query = query.startAfterDocument(doc);
        } catch (_) {}
      }

      final messagesSnapshot = await query.get();
      // Reverse to chronological order (oldest to newest)
      final paged = messagesSnapshot.docs
          .map((doc) => _mapDocToMessage(doc))
          .toList()
          .reversed
          .toList();

      return Result.success(List.unmodifiable(paged));
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to retrieve messages: $e'));
    }
  }

  @override
  Future<Result<MessageModel, AppFailure>> sendMessage(SendMessageRequest request) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.failure(
        UnauthorizedFailure(message: 'Authentication required to send messages.'),
      );
    }

    final cleanText = request.text.trim();
    if (cleanText.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Cannot send an empty message.'),
      );
    }

    if (cleanText.length > 2000) {
      return const Result.failure(
        ValidationFailure(message: 'Message cannot exceed 2000 characters.'),
      );
    }

    final effectiveUserId = user.uid;
    final effectiveUserName = user.displayName?.isNotEmpty == true ? user.displayName! : 'User';
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    final convId = _resolveConversationId(request.conversationId);

    try {
      final convDocRef = _firestore.collection('conversations').doc(convId);
      final convDoc = await convDocRef.get();

      if (!convDoc.exists) {
        return const Result.failure(NotFoundFailure(message: 'Conversation not found.'));
      }

      final conversation = _mapDocToConversation(convDoc);

      // Customer cannot write to another customer's conversation
      final isOwner = conversation.customerId.trim() == effectiveUserId.trim() ||
          convDoc.id == 'conv_$effectiveUserId' ||
          convDoc.id == 'conv_cust_$effectiveUserId' ||
          convDoc.id == convId;
      if (!isStaffOrAdmin && !isOwner) {
        return const Result.failure(
          ForbiddenFailure(message: 'Forbidden: You cannot send messages to this conversation.'),
        );
      }

      // Determine sender role
      final SenderRole senderRole;
      if (!isStaffOrAdmin) {
        senderRole = SenderRole.customer;
      } else {
        final isAdmin = await _isAdminUser(effectiveUserId);
        senderRole = isAdmin ? SenderRole.admin : SenderRole.barista;
      }

      final now = DateTime.now();
      final msgId = 'msg_${now.millisecondsSinceEpoch}';
      final sentMsg = MessageModel(
        id: msgId,
        conversationId: convId,
        senderId: effectiveUserId,
        senderName: effectiveUserName,
        senderRole: senderRole,
        text: request.text.trim(),
        status: MessageStatus.sent,
        attachmentUrl: request.attachmentUrl,
        createdAt: now,
      );

      // Human override: when human staff replies, mark handlingMode as humanActive
      final newHandlingMode = (senderRole == SenderRole.barista || senderRole == SenderRole.admin)
          ? ConversationHandlingMode.humanActive
          : conversation.handlingMode;

      // Update unread counts
      final unreads = Map<String, int>.from(conversation.unreadCountsByRole);
      if (senderRole == SenderRole.customer) {
        unreads['barista'] = (unreads['barista'] ?? 0) + 1;
        unreads['employee'] = (unreads['employee'] ?? 0) + 1;
        unreads['admin'] = (unreads['admin'] ?? 0) + 1;
      } else {
        unreads['customer'] = (unreads['customer'] ?? 0) + 1;
      }

      // 1. Commit message to subcollection
      final batch = _firestore.batch();
      final msgRef = convDocRef.collection('messages').doc(msgId);
      batch.set(msgRef, sentMsg.toJson(), SetOptions(merge: true));

      // 2. Commit conversation metadata update
      batch.set(convDocRef, {
        'last_message': sentMsg.toJson(),
        'updated_at': now.toIso8601String(),
        'unread_count': senderRole == SenderRole.customer ? conversation.unreadCount + 1 : conversation.unreadCount,
        'unread_counts_by_role': unreads,
        'handling_mode': newHandlingMode.name,
      }, SetOptions(merge: true));

      await batch.commit();

      // 3. Broadcast real-time message event
      _realtimeService.notifyMessageSent(sentMsg);

      // 4. AI Assistant auto-reply if enabled and human is not actively handling
      if (senderRole == SenderRole.customer &&
          autoReplyEnabled &&
          conversation.handlingMode != ConversationHandlingMode.humanActive) {
        unawaited(_generateAndDispatchAiReply(
          convId: convId,
          customerId: conversation.customerId,
          userQuery: request.text.trim(),
          currentUser: UserModel(
            id: effectiveUserId,
            email: user?.email ?? '',
            fullName: effectiveUserName,
            role: UserRole.customer,
          ),
        ));
      }

      return Result.success(sentMsg);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to send message: $e'));
    }
  }

  @override
  Future<Result<void, AppFailure>> markConversationAsRead(String conversationId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return const Result.success(null);
    }

    final effectiveUserId = user.uid;
    final isStaffOrAdmin = await _isStaffOrAdminUser(effectiveUserId);
    final convId = _resolveConversationId(conversationId);

    try {
      final docRef = _firestore.collection('conversations').doc(convId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) return const Result.success(null);

      final conversation = _mapDocToConversation(docSnap);
      final unreads = Map<String, int>.from(conversation.unreadCountsByRole);

      if (isStaffOrAdmin) {
        unreads['barista'] = 0;
        unreads['employee'] = 0;
        unreads['admin'] = 0;
      } else {
        unreads['customer'] = 0;
      }

      await docRef.set({
        'unread_count': isStaffOrAdmin ? conversation.unreadCount : 0,
        'unread_counts_by_role': unreads,
      }, SetOptions(merge: true));

      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapFirebaseException(e));
    } catch (e) {
      return Result.failure(ServerFailure(message: 'Failed to mark conversation read: $e'));
    }
  }

  // ===========================================================================
  // AI ASSISTANT DISPATCH
  // ===========================================================================

  Future<void> _generateAndDispatchAiReply({
    required String convId,
    required String customerId,
    required String userQuery,
    required UserModel currentUser,
  }) async {
    _realtimeService.notifyTyping(
      conversationId: convId,
      isTyping: true,
      participantName: 'Lambac Concierge AI',
    );

    try {
      final aiResult = await aiService.generateReply(
        customerMessage: userQuery,
        currentUser: currentUser,
      );

      _realtimeService.notifyTyping(
        conversationId: convId,
        isTyping: false,
        participantName: 'Lambac Concierge AI',
      );

      final now = DateTime.now();
      final aiMsgId = 'msg_ai_${now.millisecondsSinceEpoch}';
      final aiMsg = MessageModel(
        id: aiMsgId,
        conversationId: convId,
        senderId: 'lambac_concierge_ai',
        senderName: 'Lambac Roastery Concierge',
        senderRole: SenderRole.barista,
        text: aiResult.text,
        status: MessageStatus.read,
        isAiGenerated: true,
        createdAt: now,
      );

      final convDocRef = _firestore.collection('conversations').doc(convId);
      final convDoc = await convDocRef.get();

      final batch = _firestore.batch();
      final msgRef = convDocRef.collection('messages').doc(aiMsgId);
      batch.set(msgRef, aiMsg.toJson(), SetOptions(merge: true));

      if (convDoc.exists) {
        final conv = _mapDocToConversation(convDoc);
        final updatedMode = aiResult.isHumanHandoff
            ? ConversationHandlingMode.humanHandoffRequested
            : conv.handlingMode;

        final unreads = Map<String, int>.from(conv.unreadCountsByRole);
        if (aiResult.isHumanHandoff) {
          unreads['barista'] = (unreads['barista'] ?? 0) + 1;
          unreads['employee'] = (unreads['employee'] ?? 0) + 1;
          unreads['admin'] = (unreads['admin'] ?? 0) + 1;
        }

        batch.set(convDocRef, {
          'last_message': aiMsg.toJson(),
          'updated_at': now.toIso8601String(),
          'handling_mode': updatedMode.name,
          'unread_counts_by_role': unreads,
        }, SetOptions(merge: true));
      }

      await batch.commit();
      _realtimeService.notifyMessageSent(aiMsg);
    } catch (_) {
      _realtimeService.notifyTyping(
        conversationId: convId,
        isTyping: false,
        participantName: 'Lambac Concierge AI',
      );
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _resolveConversationId(String id) {
    if (id.startsWith('conv_')) return id;
    return 'conv_$id';
  }

  Future<bool> _isStaffOrAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final role = UserRole.fromString(data['role']?.toString());
        if (role == UserRole.admin) return true;
        if (role == UserRole.employee) {
          final perms = (data['permissions'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
          return perms.isEmpty || perms.contains('manageinbox') || perms.contains('manage_inbox');
        }
      }
    } catch (_) {}

    return false;
  }

  Future<bool> _isAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final role = UserRole.fromString(doc.data()?['role']?.toString());
        return role == UserRole.admin;
      }
    } catch (_) {}

    return false;
  }

  ConversationModel _mapDocToConversation(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['updated_at'] is Timestamp) {
      map['updated_at'] = (map['updated_at'] as Timestamp).toDate().toIso8601String();
    }
    if (map['last_message'] is Map) {
      final lastMsgMap = Map<String, dynamic>.from(map['last_message'] as Map);
      if (lastMsgMap['created_at'] is Timestamp) {
        lastMsgMap['created_at'] = (lastMsgMap['created_at'] as Timestamp).toDate().toIso8601String();
      }
      map['last_message'] = lastMsgMap;
    }
    return ConversationModel.fromJson(map);
  }

  MessageModel _mapDocToMessage(DocumentSnapshot doc) {
    final rawData = doc.data() as Map<String, dynamic>? ?? {};
    final map = Map<String, dynamic>.from(rawData);
    map['id'] = doc.id;

    if (map['created_at'] is Timestamp) {
      map['created_at'] = (map['created_at'] as Timestamp).toDate().toIso8601String();
    }
    return MessageModel.fromJson(map);
  }

  AppFailure _mapFirebaseException(FirebaseException e, [StackTrace? stackTrace]) {
    return ErrorHandler.handle(
      e,
      stackTrace: stackTrace,
      domain: FailureDomain.chat,
      operation: 'chat_messaging',
    );
  }
}
