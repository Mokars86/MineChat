import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  List<ChatConversation> _conversations = [];
  Map<String, List<ChatMessage>> _messagesCache = {};
  String? _selectedConversationId;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  List<ChatConversation> _searchResults = [];

  StreamSubscription? _conversationsSubscription;
  Map<String, StreamSubscription> _messagesSubscriptions = {};

  List<ChatConversation> get conversations => _searchQuery.isEmpty
      ? _conversations
      : _searchResults;

  List<ChatMessage> get selectedConversationMessages =>
      _selectedConversationId != null
          ? _messagesCache[_selectedConversationId] ?? []
          : [];

  ChatConversation? get selectedConversation => _selectedConversationId != null
      ? _conversations.firstWhere(
          (c) => c.id == _selectedConversationId,
          orElse: () => null as ChatConversation,
        )
      : null;

  String? get selectedConversationId => _selectedConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _chatService.init();

      // Listen for conversations updates
      _conversationsSubscription = _chatService.conversationsStream.listen((conversations) {
        _conversations = conversations;

        // Apply search filter if there's an active search
        if (_searchQuery.isNotEmpty) {
          _searchResults = _chatService.searchConversations(_searchQuery);
        }

        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectConversation(String conversationId) {
    _selectedConversationId = conversationId;

    // Cancel previous subscription if exists
    _messagesSubscriptions[conversationId]?.cancel();

    // Subscribe to messages for this conversation
    _messagesSubscriptions[conversationId] = _chatService
        .getMessagesStream(conversationId)
        .listen((messages) {
      _messagesCache[conversationId] = messages;
      notifyListeners();
    });

    // Mark messages as read
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _chatService.markMessagesAsRead(conversationId, currentUser.id);
    }

    notifyListeners();
  }

  void clearSelectedConversation() {
    _selectedConversationId = null;
    notifyListeners();
  }

  Future<void> sendMessage(String content, {MessageType type = MessageType.text, Map<String, dynamic>? metadata}) async {
    if (_selectedConversationId == null) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _chatService.sendMessage(
        conversationId: _selectedConversationId!,
        content: content,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.photoUrl,
        type: type,
        metadata: metadata,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendCryptoTransaction({
    required double amount,
    String? note,
  }) async {
    if (_selectedConversationId == null) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final conversation = _conversations.firstWhere(
      (c) => c.id == _selectedConversationId,
      orElse: () => throw Exception('Conversation not found'),
    );

    // For group chats, we don't support sending crypto
    if (conversation.isGroup) {
      _error = 'Sending crypto in group chats is not supported';
      notifyListeners();
      return;
    }

    // Get the recipient ID (the other participant in the conversation)
    final recipientId = conversation.participantIds.firstWhere(
      (id) => id != currentUser.id,
      orElse: () => throw Exception('Recipient not found'),
    );

    final recipientName = conversation.participantNames[recipientId] ?? 'Unknown';

    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.sendTransactionMessage(
        conversationId: _selectedConversationId!,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.photoUrl,
        receiverId: recipientId,
        receiverName: recipientName,
        amount: amount,
        note: note,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatConversation> createConversation({
    required String name,
    String? avatar,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantAvatars,
    bool isGroup = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final conversation = await _chatService.createConversation(
        name: name,
        avatar: avatar,
        participantIds: participantIds,
        participantNames: participantNames,
        participantAvatars: participantAvatars,
        isGroup: isGroup,
      );

      _isLoading = false;
      notifyListeners();

      return conversation;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_selectedConversationId == null) return;

    try {
      await _chatService.deleteMessage(_selectedConversationId!, messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> archiveConversation(String conversationId, bool archive) async {
    try {
      await _chatService.archiveConversation(conversationId, archive);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> muteConversation(String conversationId, bool mute) async {
    try {
      await _chatService.muteConversation(conversationId, mute);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pinConversation(String conversationId, bool pin) async {
    try {
      await _chatService.pinConversation(conversationId, pin);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void searchConversations(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _chatService.searchConversations(query);
    }

    notifyListeners();
  }

  List<ChatMessage> searchMessages(String query) {
    if (_selectedConversationId == null) return [];

    return _chatService.searchMessages(_selectedConversationId!, query);
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    for (final subscription in _messagesSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
