import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/firebase_chat_remote_datasource.dart';
import '../../data/datasources/mock_chat_remote_datasource.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/send_message_request.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_realtime_service.dart';

/// Provider for Chat Remote Data Source (Cloud Firestore Production Data Source)
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isEmpty) {
      return MockChatRemoteDataSource();
    }
  } catch (_) {
    return MockChatRemoteDataSource();
  }
  return FirebaseChatRemoteDataSource();
});

/// Provider for Domain ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final realtimeService = ref.watch(chatRealtimeServiceProvider);

  return ChatRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
    realtimeService: realtimeService,
  );
});

/// Chat State Container with Pagination & Real-Time Sync support
class ChatState extends Equatable {
  final bool isLoading;
  final bool isLoadingOlder;
  final ConversationModel? conversation;
  final List<MessageModel> messages;
  final bool isBaristaTyping;
  final AppFailure? failure;
  final bool hasMoreOlder;
  final int currentPage;

  const ChatState({
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.conversation,
    this.messages = const [],
    this.isBaristaTyping = false,
    this.failure,
    this.hasMoreOlder = true,
    this.currentPage = 1,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isLoadingOlder,
    ConversationModel? conversation,
    List<MessageModel>? messages,
    bool? isBaristaTyping,
    AppFailure? failure,
    bool clearFailure = false,
    bool? hasMoreOlder,
    int? currentPage,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isBaristaTyping: isBaristaTyping ?? this.isBaristaTyping,
      failure: clearFailure ? null : (failure ?? this.failure),
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingOlder,
        conversation,
        messages,
        isBaristaTyping,
        failure,
        hasMoreOlder,
        currentPage,
      ];
}

/// Inbox State Container for Staff & Admin Shared Inboxes
class InboxState extends Equatable {
  final bool isLoading;
  final List<ConversationModel> conversations;
  final AppFailure? failure;

  const InboxState({
    this.isLoading = false,
    this.conversations = const [],
    this.failure,
  });

  InboxState copyWith({
    bool? isLoading,
    List<ConversationModel>? conversations,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [isLoading, conversations, failure];
}

/// Inbox StateNotifier Provider for Staff & Admin
final inboxNotifierProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return InboxNotifier(repository: repository, currentUser: currentUser);
});

class InboxNotifier extends StateNotifier<InboxState> {
  final ChatRepository _repository;
  StreamSubscription<MessageModel>? _realtimeSub;

  InboxNotifier({
    required ChatRepository repository,
    UserModel? currentUser,
  })  : _repository = repository,
        super(const InboxState()) {
    loadInbox();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> loadInbox() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getConversations();
    if (!mounted) return;

    result.when(
      success: (list) {
        state = state.copyWith(
          isLoading: false,
          conversations: list,
          clearFailure: true,
        );
      },
      failure: (fail) {
        state = state.copyWith(
          isLoading: false,
          failure: fail,
        );
      },
    );
  }

  void _subscribeToRealtime() {
    _realtimeSub = _repository.watchConversation('*').listen((_) {
      if (mounted) {
        loadInbox();
      }
    });
  }

  Future<void> markAsRead(String conversationId) async {
    await _repository.markConversationAsRead(conversationId);
    if (mounted) {
      await loadInbox();
    }
  }
}

/// User-Scoped Chat StateNotifier Provider
/// Persists across screen navigations; resets cleanly upon account switching or logout
final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);

  return ChatNotifier(
    repository: repository,
    currentUser: currentUser,
  );
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final UserModel? _currentUser;
  final String? _sessionUserId;
  String? _activeCustomerId;

  StreamSubscription<MessageModel>? _messageSub;
  StreamSubscription<dynamic>? _typingSub;

  int _loadSequence = 0;

  ChatNotifier({
    required ChatRepository repository,
    UserModel? currentUser,
  })  : _repository = repository,
        _currentUser = currentUser,
        _sessionUserId = currentUser?.id,
        super(const ChatState()) {
    if (_currentUser != null && _currentUser.isCustomer) {
      loadChat();
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }

  /// Reset state to empty
  void clearState() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _activeCustomerId = null;
    state = const ChatState();
  }

  /// Load persisted conversation history from backend
  Future<void> loadChat([String? targetCustomerId]) async {
    if (_currentUser == null) {
      state = const ChatState();
      return;
    }

    if (_currentUser.isGuest) {
      state = state.copyWith(
        isLoading: false,
        failure: const UnauthorizedFailure(message: 'Sign in to access Roastery Concierge chat.'),
      );
      return;
    }

    final seq = ++_loadSequence;

    // Strict identity enforcement: customers can ONLY EVER access their own conversation.
    _activeCustomerId = _currentUser.isCustomer ? _currentUser.id : targetCustomerId;
    state = state.copyWith(isLoading: true, clearFailure: true);

    final lookupUserId = _currentUser.isCustomer ? _currentUser.id : (targetCustomerId ?? _currentUser.id);
    final convResult = await _repository.getConversation(lookupUserId);
    if (!mounted || _currentUser.id != _sessionUserId || seq != _loadSequence) return;

    if (convResult.isSuccess) {
      final conv = convResult.dataOrNull!;
      // Mark as read immediately when viewed by this authorized user
      await _repository.markConversationAsRead(conv.id);

      final msgResult = await _repository.getMessages(conv.id, page: 1, limit: 30);
      if (!mounted || _currentUser.id != _sessionUserId || seq != _loadSequence) return;

      if (msgResult.isSuccess) {
        final initialMessages = _deduplicateAndSort(msgResult.dataOrNull ?? []);

        state = state.copyWith(
          isLoading: false,
          conversation: conv,
          messages: initialMessages,
          currentPage: 1,
          hasMoreOlder: (msgResult.dataOrNull?.length ?? 0) >= 30,
          clearFailure: true,
        );

        _subscribeToRealtime(conv.id);
      } else {
        state = state.copyWith(isLoading: false, failure: msgResult.failureOrNull);
      }
    } else {
      state = state.copyWith(isLoading: false, failure: convResult.failureOrNull);
    }
  }

  /// Load older messages when scrolling upwards
  Future<void> loadOlderMessages() async {
    final conv = state.conversation;
    if (conv == null || !state.hasMoreOlder || state.isLoadingOlder || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingOlder: true);
    final nextPage = state.currentPage + 1;
    final oldestMsgId = state.messages.isNotEmpty ? state.messages.first.id : null;

    final result = await _repository.getMessages(
      conv.id,
      page: nextPage,
      limit: 30,
      lastDocument: oldestMsgId,
    );
    if (!mounted || _currentUser?.id != _sessionUserId) return;

    if (result.isSuccess) {
      final olderMessages = result.dataOrNull ?? [];
      final combined = _deduplicateAndSort([...olderMessages, ...state.messages]);

      state = state.copyWith(
        isLoadingOlder: false,
        messages: combined,
        currentPage: nextPage,
        hasMoreOlder: olderMessages.length >= 30,
      );
    } else {
      state = state.copyWith(isLoadingOlder: false);
    }
  }

  void _subscribeToRealtime(String conversationId) {
    _messageSub?.cancel();
    _typingSub?.cancel();

    _messageSub = _repository.watchConversation(conversationId).listen((incomingMsg) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      _handleIncomingRealtimeMessage(incomingMsg);
    });

    _typingSub = _repository.watchTyping(conversationId).listen((event) {
      if (!mounted || _currentUser?.id != _sessionUserId) return;
      state = state.copyWith(isBaristaTyping: event.isTyping as bool);
    });
  }

  void _handleIncomingRealtimeMessage(MessageModel incoming) {
    if (state.conversation == null || incoming.conversationId != state.conversation!.id) {
      return;
    }
    final existing = List<MessageModel>.from(state.messages);

    // 1. Check if matching message ID already present (deduplication)
    final existingIndex = existing.indexWhere((m) => m.id == incoming.id);
    if (existingIndex != -1) {
      existing[existingIndex] = incoming;
    } else {
      // 2. Check if this resolves an in-flight optimistic message
      final optimisticIndex = existing.indexWhere(
        (m) => m.isSending && m.text == incoming.text && m.senderId == incoming.senderId,
      );
      if (optimisticIndex != -1) {
        existing[optimisticIndex] = incoming;
      } else {
        existing.add(incoming);
      }
    }

    final sorted = _deduplicateAndSort(existing);
    state = state.copyWith(
      messages: sorted,
      conversation: state.conversation?.copyWith(
        lastMessage: incoming,
        updatedAt: incoming.createdAt,
      ),
    );

    // If conversation is open and active, mark incoming as read for current user
    if (state.conversation != null) {
      _repository.markConversationAsRead(state.conversation!.id);
    }
  }

  /// Send message with optimistic UI update, server persistence, and error handling
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _currentUser == null) return;

    // If the conversation has not loaded yet, attempt a reload before proceeding.
    // This guards against the race where the user taps send before loadChat() completes.
    if (state.conversation == null && !state.isLoading) {
      await loadChat(_activeCustomerId);
      if (state.conversation == null) {
        // Conversation still unavailable; surface failure via loadChat's error path.
        return;
      }
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    // Always derive the conversation ID from the loaded conversation document.
    // Fall back to the canonical 'conv_<uid>' format — never the legacy 'conv_cust_' prefix
    // which no longer matches newly-created conversation documents.
    final convId = state.conversation?.id ??
        (_currentUser.isCustomer
            ? 'conv_${_currentUser.id}'
            : (_activeCustomerId != null ? 'conv_$_activeCustomerId' : 'conv_${_currentUser.id}'));
    final senderRole = _currentUser.isCustomer
        ? SenderRole.customer
        : (_currentUser.isAdmin ? SenderRole.admin : SenderRole.barista);

    // 1. Optimistic Message
    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: convId,
      senderId: _currentUser.id,
      senderName: _currentUser.fullName,
      senderRole: senderRole,
      text: trimmed,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
    );

    // 2. Perform Remote Send Call (persists to backend database)
    final result = await _repository.sendMessage(
      SendMessageRequest(
        conversationId: convId,
        text: trimmed,
      ),
    );

    if (!mounted || _currentUser.id != _sessionUserId) return;

    result.when(
      success: (serverMsg) {
        final updatedList = state.messages.map((m) {
          return m.id == tempId ? serverMsg : m;
        }).toList();

        state = state.copyWith(
          messages: _deduplicateAndSort(updatedList),
          conversation: state.conversation?.copyWith(
            lastMessage: serverMsg,
            updatedAt: serverMsg.createdAt,
          ),
          clearFailure: true,
        );
      },
      failure: (failure) {
        final updatedList = state.messages.map((m) {
          return m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m;
        }).toList();

        state = state.copyWith(
          messages: updatedList,
          failure: failure,
        );
      },
    );
  }

  /// Retry sending a failed message
  Future<void> retryMessage(MessageModel failedMessage) async {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != failedMessage.id).toList(),
    );
    await sendMessage(failedMessage.text);
  }

  /// Deterministically sort messages by server timestamp and ID
  List<MessageModel> _deduplicateAndSort(List<MessageModel> raw) {
    final Map<String, MessageModel> map = {};
    for (final m in raw) {
      map[m.id] = m;
    }
    final list = map.values.toList();
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }
}
