import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'providers/chat_provider.dart';
import 'models/chat_models.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat/chat_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final authService = AuthService();
  await authService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'MineChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const ChatTab(),
    const StatusTab(),
    const MiningTab(),
    const WalletTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.memory),
            label: 'Mining',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}

// Simplified Tab Screens
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authService = AuthService();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  chatProvider.searchConversations(value);
                },
                autofocus: true,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    chatProvider.searchConversations('');
                  });
                },
              ),
            )
          : AppBar(
              title: const Text('MineChat'),
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
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: chatProvider.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = chatProvider.conversations[index];
                    final isCurrentUserLastSender =
                        conversation.lastMessageSenderId == currentUser?.id;

                    // Format the timestamp
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final yesterday = DateTime(now.year, now.month, now.day - 1);
                    final messageDate = DateTime(
                      conversation.lastMessageTime.year,
                      conversation.lastMessageTime.month,
                      conversation.lastMessageTime.day,
                    );

                    String timeString;
                    if (messageDate == today) {
                      // Today, show time
                      timeString = '${conversation.lastMessageTime.hour}:${conversation.lastMessageTime.minute.toString().padLeft(2, '0')}';
                    } else if (messageDate == yesterday) {
                      // Yesterday
                      timeString = 'Yesterday';
                    } else {
                      // Other days, show date
                      timeString = '${conversation.lastMessageTime.day}/${conversation.lastMessageTime.month}/${conversation.lastMessageTime.year}';
                    }

                    return ListTile(
                      leading: CircleAvatar(
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.isPinned)
                            const Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (isCurrentUserLastSender)
                            const Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.blue,
                            ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              conversation.lastMessageContent ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          if (conversation.isMuted)
                            const Icon(
                              Icons.volume_off,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Here we would add unread count badge
                        ],
                      ),
                      onTap: () {
                        chatProvider.selectConversation(conversation.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              conversationId: conversation.id,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showConversationOptions(context, conversation);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat by tapping the button below',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(BuildContext context, ChatConversation conversation) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.archive),
                title: Text(conversation.isArchived ? 'Unarchive' : 'Archive'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.archiveConversation(
                    conversation.id,
                    !conversation.isArchived,
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
                leading: Icon(conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  Navigator.pop(context);
                  chatProvider.pinConversation(
                    conversation.id,
                    !conversation.isPinned,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, conversation.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String conversationId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
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
                // Delete conversation functionality would be implemented here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete functionality not implemented yet')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'Enter contact name',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                Navigator.pop(context);

                try {
                  // Create a new conversation
                  final String contactId = DateTime.now().millisecondsSinceEpoch.toString();
                  final conversation = await chatProvider.createConversation(
                    name: nameController.text.trim(),
                    avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameController.text.trim())}',
                    participantIds: [currentUser.id, contactId],
                    participantNames: {
                      currentUser.id: currentUser.name,
                      contactId: nameController.text.trim(),
                    },
                    participantAvatars: {
                      currentUser.id: currentUser.photoUrl,
                      contactId: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(nameController.text.trim())}',
                    },
                  );

                  // Navigate to the chat screen
                  if (context.mounted) {
                    chatProvider.selectConversation(conversation.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          conversationId: conversation.id,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final isMyStatus = index == 0;
          return ListTile(
            leading: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMyStatus ? Colors.grey : AppTheme.secondaryColor,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  isMyStatus ? 'Me' : 'U${index}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            title: Text(isMyStatus ? 'My Status' : 'User $index'),
            subtitle: Text(
              isMyStatus ? 'Tap to add status update' : '${index} hours ago',
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status feature not implemented yet')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add status not implemented yet')),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}

class MiningTab extends StatelessWidget {
  const MiningTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mining'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mining Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mining is currently inactive. Start mining to earn cryptocurrency while chatting!',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mining feature not implemented in this demo')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Start Mining',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppTheme.walletColor,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$2,430.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Your Assets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              itemBuilder: (context, index) {
                final currencies = ['Bitcoin', 'Ethereum', 'Litecoin', 'Dogecoin'];
                final amounts = ['0.025', '0.5', '2.0', '1000.0'];
                final values = ['\$1,250.00', '\$900.00', '\$200.00', '\$80.00'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      currencies[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(values[index]),
                    trailing: Text(
                      amounts[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Send crypto not implemented in this demo')),
          );
        },
        backgroundColor: AppTheme.walletColor,
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
}
