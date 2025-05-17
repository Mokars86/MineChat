import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'chat_info_screen.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<ChatMessage> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    // Select the conversation in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.selectConversation(widget.conversationId);
      
      // Scroll to bottom after messages load
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view this chat'),
        ),
      );
    }
    
    final conversation = chatProvider.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
    
    final messages = _isSearching && _searchResults.isNotEmpty
        ? _searchResults
        : chatProvider.selectedConversationMessages;
    
    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search in conversation...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchResults = chatProvider.searchMessages(value);
                  });
                },
                autofocus: true,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
              ),
            )
          : AppBar(
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatInfoScreen(conversation: conversation),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      backgroundImage: conversation.avatar != null
                          ? NetworkImage(conversation.avatar!)
                          : null,
                      child: conversation.avatar == null
                          ? Text(
                              conversation.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.name,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (conversation.isGroup)
                            Text(
                              '${conversation.participantIds.length} participants',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showChatOptions(context, conversation);
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser.id;
                      
                      // Check if we need to show date header
                      final showDateHeader = index == 0 || 
                          !_isSameDay(messages[index - 1].timestamp, message.timestamp);
                      
                      return Column(
                        children: [
                          if (showDateHeader)
                            _buildDateHeader(message.timestamp),
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            showSender: conversation.isGroup && !isMe,
                            onLongPress: () => _showMessageOptions(context, message),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          
          // Message input
          MessageInput(
            onSendMessage: (content, type) {
              chatProvider.sendMessage(content, type: type);
              _scrollToBottom();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  void _showChatOptions(BuildContext context, ChatConversation conversation) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('View Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatInfoScreen(conversation: conversation),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(conversation.isMuted ? Icons.volume_up : Icons.volume_off),
                title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.muteConversation(
                    conversation.id, 
                    !conversation.isMuted,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) return;
    
    final isMyMessage = message.senderId == currentUser.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy message to clipboard
                },
              ),
              if (isMyMessage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    chatProvider.deleteMessage(message.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  // Reply to message functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(context);
                  // Forward message functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearChatConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Clear chat functionality would be implemented here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clear chat functionality not implemented yet')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
