import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../models/transaction_message.dart';
import 'auth_service.dart';
import 'wallet_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  final _conversationsController = StreamController<List<ChatConversation>>.broadcast();
  final _messagesControllers = <String, StreamController<List<ChatMessage>>>{};

  Stream<List<ChatConversation>> get conversationsStream => _conversationsController.stream;

  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    if (!_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId] = StreamController<List<ChatMessage>>.broadcast();
    }
    return _messagesControllers[conversationId]!.stream;
  }

  List<ChatConversation> get conversations => _conversations;

  List<ChatMessage> getMessages(String conversationId) {
    return _messages[conversationId] ?? [];
  }

  // Initialize the chat service
  Future<void> init() async {
    await _loadData();

    if (_conversations.isEmpty) {
      await _loadDemoData();
    }

    _notifyConversationsListeners();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load conversations
    final conversationsJson = prefs.getString('conversations');
    if (conversationsJson != null) {
      final List<dynamic> conversationsData = jsonDecode(conversationsJson);
      _conversations.clear();
      _conversations.addAll(
        conversationsData.map((data) => ChatConversation.fromJson(data)).toList()
      );

      // Sort conversations by last message time
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }

    // Load messages for each conversation
    for (final conversation in _conversations) {
      final messagesJson = prefs.getString('messages_${conversation.id}');
      if (messagesJson != null) {
        final List<dynamic> messagesData = jsonDecode(messagesJson);
        _messages[conversation.id] = messagesData
            .map((data) => ChatMessage.fromJson(data))
            .toList();

        // Sort messages by timestamp
        _messages[conversation.id]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save conversations
    final conversationsJson = jsonEncode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString('conversations', conversationsJson);

    // Save messages for each conversation
    for (final entry in _messages.entries) {
      final messagesJson = jsonEncode(entry.value.map((m) => m.toJson()).toList());
      await prefs.setString('messages_${entry.key}', messagesJson);
    }
  }

  // Load demo data
  Future<void> _loadDemoData() async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    // Create demo conversations
    final List<ChatConversation> demoConversations = [
      ChatConversation(
        name: 'John Doe',
        avatar: 'https://ui-avatars.com/api/?name=John+Doe',
        participantIds: [currentUser.id, '2'],
        participantNames: {
          currentUser.id: currentUser.name,
          '2': 'John Doe',
        },
        participantAvatars: {
          currentUser.id: currentUser.photoUrl,
          '2': 'https://ui-avatars.com/api/?name=John+Doe',
        },
        lastMessageContent: 'Hey, how are you?',
        lastMessageSenderId: '2',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatConversation(
        name: 'Crypto Miners Group',
        avatar: 'https://ui-avatars.com/api/?name=Crypto+Miners',
        participantIds: [currentUser.id, '3', '4', '5'],
        participantNames: {
          currentUser.id: currentUser.name,
          '3': 'Alice',
          '4': 'Bob',
          '5': 'Charlie',
        },
        participantAvatars: {
          currentUser.id: currentUser.photoUrl,
          '3': 'https://ui-avatars.com/api/?name=Alice',
          '4': 'https://ui-avatars.com/api/?name=Bob',
          '5': 'https://ui-avatars.com/api/?name=Charlie',
        },
        isGroup: true,
        lastMessageContent: 'Has anyone tried the new mining algorithm?',
        lastMessageSenderId: '3',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatConversation(
        name: 'Sarah Johnson',
        avatar: 'https://ui-avatars.com/api/?name=Sarah+Johnson',
        participantIds: [currentUser.id, '6'],
        participantNames: {
          currentUser.id: currentUser.name,
          '6': 'Sarah Johnson',
        },
        participantAvatars: {
          currentUser.id: currentUser.photoUrl,
          '6': 'https://ui-avatars.com/api/?name=Sarah+Johnson',
        },
        lastMessageContent: 'Can you send me your wallet address?',
        lastMessageSenderId: currentUser.id,
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _conversations.addAll(demoConversations);

    // Create demo messages
    for (final conversation in demoConversations) {
      final List<ChatMessage> demoMessages = [];

      if (conversation.id == _conversations[0].id) {
        // Messages for John Doe
        demoMessages.addAll([
          ChatMessage(
            senderId: '2',
            senderName: 'John Doe',
            senderAvatar: 'https://ui-avatars.com/api/?name=John+Doe',
            conversationId: conversation.id,
            content: 'Hey, how are you?',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: currentUser.id,
            senderName: currentUser.name,
            senderAvatar: currentUser.photoUrl,
            conversationId: conversation.id,
            content: 'I\'m good, thanks! How about you?',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: '2',
            senderName: 'John Doe',
            senderAvatar: 'https://ui-avatars.com/api/?name=John+Doe',
            conversationId: conversation.id,
            content: 'Doing well! Have you started mining yet?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            status: MessageStatus.delivered,
          ),
        ]);
      } else if (conversation.id == _conversations[1].id) {
        // Messages for Crypto Miners Group
        demoMessages.addAll([
          ChatMessage(
            senderId: '3',
            senderName: 'Alice',
            senderAvatar: 'https://ui-avatars.com/api/?name=Alice',
            conversationId: conversation.id,
            content: 'Has anyone tried the new mining algorithm?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: '4',
            senderName: 'Bob',
            senderAvatar: 'https://ui-avatars.com/api/?name=Bob',
            conversationId: conversation.id,
            content: 'Yes, it\'s much more efficient!',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: '5',
            senderName: 'Charlie',
            senderAvatar: 'https://ui-avatars.com/api/?name=Charlie',
            conversationId: conversation.id,
            content: 'I\'ve been using it for a week now. My earnings are up by 15%.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            status: MessageStatus.read,
          ),
        ]);
      } else if (conversation.id == _conversations[2].id) {
        // Messages for Sarah Johnson
        demoMessages.addAll([
          ChatMessage(
            senderId: '6',
            senderName: 'Sarah Johnson',
            senderAvatar: 'https://ui-avatars.com/api/?name=Sarah+Johnson',
            conversationId: conversation.id,
            content: 'Hi there! I heard you\'re into crypto mining?',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: currentUser.id,
            senderName: currentUser.name,
            senderAvatar: currentUser.photoUrl,
            conversationId: conversation.id,
            content: 'Yes, I\'ve been mining for a few months now.',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 23)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: '6',
            senderName: 'Sarah Johnson',
            senderAvatar: 'https://ui-avatars.com/api/?name=Sarah+Johnson',
            conversationId: conversation.id,
            content: 'That\'s great! Could you give me some tips on getting started?',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 22)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: currentUser.id,
            senderName: currentUser.name,
            senderAvatar: currentUser.photoUrl,
            conversationId: conversation.id,
            content: 'Sure! Let\'s start with the basics. What hardware do you have?',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
            status: MessageStatus.read,
          ),
          ChatMessage(
            senderId: currentUser.id,
            senderName: currentUser.name,
            senderAvatar: currentUser.photoUrl,
            conversationId: conversation.id,
            content: 'Can you send me your wallet address?',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            status: MessageStatus.delivered,
          ),
        ]);
      }

      _messages[conversation.id] = demoMessages;
    }

    await _saveData();
  }

  // Create a new conversation
  Future<ChatConversation> createConversation({
    required String name,
    String? avatar,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    Map<String, String?>? participantAvatars,
    bool isGroup = false,
  }) async {
    final conversation = ChatConversation(
      name: name,
      avatar: avatar,
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: participantAvatars ?? {},
      isGroup: isGroup,
    );

    _conversations.add(conversation);
    _messages[conversation.id] = [];

    await _saveData();
    _notifyConversationsListeners();

    return conversation;
  }

  // Send a message
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    // Find the conversation
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) {
      throw Exception('Conversation not found');
    }

    // Create the message
    final message = ChatMessage(
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      conversationId: conversationId,
      content: content,
      type: type,
      metadata: metadata,
      status: MessageStatus.sending,
    );

    // Add the message to the conversation
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);

    // Update the conversation's last message info
    final updatedConversation = _conversations[conversationIndex].copyWith(
      lastMessageContent: content,
      lastMessageSenderId: senderId,
      lastMessageTime: message.timestamp,
    );
    _conversations[conversationIndex] = updatedConversation;

    // Sort conversations by last message time
    _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Update message status to sent
    final messageIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
    if (messageIndex != -1) {
      _messages[conversationId]![messageIndex] = message.copyWith(status: MessageStatus.sent);
    }

    // Simulate delivery delay
    await Future.delayed(const Duration(seconds: 1));

    // Update message status to delivered
    final messageIndex2 = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
    if (messageIndex2 != -1) {
      _messages[conversationId]![messageIndex2] = _messages[conversationId]![messageIndex2].copyWith(
        status: MessageStatus.delivered
      );
    }

    await _saveData();
    _notifyConversationsListeners();
    _notifyMessagesListeners(conversationId);

    return message;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    if (!_messages.containsKey(conversationId)) return;

    bool hasChanges = false;

    for (int i = 0; i < _messages[conversationId]!.length; i++) {
      final message = _messages[conversationId]![i];
      if (message.senderId != userId && message.status != MessageStatus.read) {
        _messages[conversationId]![i] = message.copyWith(status: MessageStatus.read);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveData();
      _notifyMessagesListeners(conversationId);
    }
  }

  // Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    if (!_messages.containsKey(conversationId)) return;

    final messageIndex = _messages[conversationId]!.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      // Mark the message as deleted
      _messages[conversationId]![messageIndex] = _messages[conversationId]![messageIndex].copyWith(
        isDeleted: true,
        content: 'This message was deleted'
      );

      await _saveData();
      _notifyMessagesListeners(conversationId);
    }
  }

  // Archive a conversation
  Future<void> archiveConversation(String conversationId, bool archive) async {
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        isArchived: archive
      );

      await _saveData();
      _notifyConversationsListeners();
    }
  }

  // Mute a conversation
  Future<void> muteConversation(String conversationId, bool mute) async {
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        isMuted: mute
      );

      await _saveData();
      _notifyConversationsListeners();
    }
  }

  // Pin a conversation
  Future<void> pinConversation(String conversationId, bool pin) async {
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        isPinned: pin
      );

      // Sort conversations by pinned status and last message time
      _conversations.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.lastMessageTime.compareTo(a.lastMessageTime);
      });

      await _saveData();
      _notifyConversationsListeners();
    }
  }

  // Search conversations
  List<ChatConversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;

    final lowercaseQuery = query.toLowerCase();
    return _conversations.where((conversation) {
      return conversation.name.toLowerCase().contains(lowercaseQuery) ||
             conversation.participantNames.values.any((name) =>
                name.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Search messages in a conversation
  List<ChatMessage> searchMessages(String conversationId, String query) {
    if (query.isEmpty || !_messages.containsKey(conversationId)) return [];

    final lowercaseQuery = query.toLowerCase();
    return _messages[conversationId]!.where((message) {
      return message.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Send a crypto transaction message
  Future<ChatMessage> sendTransactionMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String receiverId,
    required String receiverName,
    required double amount,
    String? note,
  }) async {
    // Find the conversation
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex == -1) {
      throw Exception('Conversation not found');
    }

    // Create the transaction
    final transaction = TransactionMessage(
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      note: note,
      status: TransactionStatus.pending,
    );

    // Create the transaction message content
    final content = jsonEncode({
      'transactionId': transaction.id,
      'amount': amount,
      'currency': transaction.currency,
      'note': note,
      'status': TransactionStatus.pending.index,
    });

    // Create the message
    final message = ChatMessage(
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      conversationId: conversationId,
      content: content,
      type: MessageType.transaction,
      status: MessageStatus.sending,
    );

    // Add the message to the conversation
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(message);

    // Update the conversation's last message info
    final updatedConversation = _conversations[conversationIndex].copyWith(
      lastMessageContent: 'Sent ${amount.toStringAsFixed(2)} ${transaction.currency}',
      lastMessageSenderId: senderId,
      lastMessageTime: message.timestamp,
    );
    _conversations[conversationIndex] = updatedConversation;

    // Sort conversations by last message time
    _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    // Process the transaction
    final walletService = WalletService();
    try {
      // Deduct from sender's wallet
      await walletService.addTransaction(
        amount: amount,
        description: 'Sent to $receiverName',
        isDeposit: false,
      );

      // Add to receiver's wallet
      await walletService.addTransactionForUser(
        userId: receiverId,
        amount: amount,
        description: 'Received from $senderName',
        isDeposit: true,
      );

      // Update transaction status to completed
      final transactionData = jsonDecode(message.content) as Map<String, dynamic>;
      transactionData['status'] = TransactionStatus.completed.index;

      // Update message content with completed transaction
      final messageIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
      if (messageIndex != -1) {
        _messages[conversationId]![messageIndex] = _messages[conversationId]![messageIndex].copyWith(
          content: jsonEncode(transactionData),
          status: MessageStatus.delivered,
        );
      }
    } catch (e) {
      // Update transaction status to failed
      final transactionData = jsonDecode(message.content) as Map<String, dynamic>;
      transactionData['status'] = TransactionStatus.failed.index;

      // Update message content with failed transaction
      final messageIndex = _messages[conversationId]!.indexWhere((m) => m.id == message.id);
      if (messageIndex != -1) {
        _messages[conversationId]![messageIndex] = _messages[conversationId]![messageIndex].copyWith(
          content: jsonEncode(transactionData),
          status: MessageStatus.delivered,
        );
      }

      throw Exception('Failed to process transaction: ${e.toString()}');
    }

    await _saveData();
    _notifyConversationsListeners();
    _notifyMessagesListeners(conversationId);

    return message;
  }

  void _notifyConversationsListeners() {
    _conversationsController.add(_conversations);
  }

  void _notifyMessagesListeners(String conversationId) {
    if (_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId]!.add(_messages[conversationId] ?? []);
    }
  }

  void dispose() {
    _conversationsController.close();
    for (final controller in _messagesControllers.values) {
      controller.close();
    }
  }
}
