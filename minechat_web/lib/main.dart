import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/call_service.dart';
import 'providers/chat_provider.dart';
import 'providers/call_provider.dart';
import 'providers/mining_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/community_provider.dart';
import 'models/chat_models.dart';
import 'models/call_models.dart';
import 'models/mining_models.dart';
import 'models/wallet_address.dart';
import 'models/community_models.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/call/incoming_call_screen.dart';
import 'screens/call/audio_call_screen.dart';
import 'screens/call/video_call_screen.dart';
import 'screens/community/community_tab.dart';
import 'screens/community/create_community_screen.dart';
import 'screens/qr/qr_scanner_screen.dart';
import 'screens/qr/my_qr_code_screen.dart';

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
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => MiningProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MineChat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            builder: (context, child) {
              return CallOverlayWidget(child: child);
            },
          );
        },
      ),
    );
  }
}

class CallOverlayWidget extends StatelessWidget {
  final Widget? child;

  const CallOverlayWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final currentCall = callProvider.currentCall;

    // If there's an incoming call, show the incoming call screen
    if (currentCall != null &&
        currentCall.status == CallStatus.ringing &&
        !currentCall.isOutgoing) {
      return IncomingCallScreen();
    }

    // Otherwise, show the normal app
    return child ?? const SizedBox.shrink();
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
                // Search button first
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                // Call button second
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    _showCallHistoryDialog(context);
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                    );
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
                      leading: conversation.isGroup
                        ? Stack(
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
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.group,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : CircleAvatar(
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

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('New Chat'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showNewContactDialog(context);
              },
              child: const Row(
                children: [
                  Icon(Icons.person_add, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('New Contact'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showNewGroupDialog(context);
              },
              child: const Row(
                children: [
                  Icon(Icons.group_add, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('New Group'),
                ],
              ),
            ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('Scan QR Code'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyQRCodeScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.qr_code, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('My QR Code'),
                ],
              ),
            ),
            const Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityTab(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.people, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('Browse Communities'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateCommunityScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Text('Create Community'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewContactDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'Enter contact name',
                  prefixIcon: Icon(Icons.person),
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

  void _showNewGroupDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final TextEditingController groupNameController = TextEditingController();

    // Demo contacts for selection
    final List<Map<String, dynamic>> contacts = [
      {'id': '2', 'name': 'John Doe', 'avatar': 'https://ui-avatars.com/api/?name=John+Doe', 'selected': false},
      {'id': '3', 'name': 'Alice', 'avatar': 'https://ui-avatars.com/api/?name=Alice', 'selected': false},
      {'id': '4', 'name': 'Bob', 'avatar': 'https://ui-avatars.com/api/?name=Bob', 'selected': false},
      {'id': '5', 'name': 'Charlie', 'avatar': 'https://ui-avatars.com/api/?name=Charlie', 'selected': false},
      {'id': '6', 'name': 'Sarah Johnson', 'avatar': 'https://ui-avatars.com/api/?name=Sarah+Johnson', 'selected': false},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Group'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'Enter group name',
                        prefixIcon: Icon(Icons.group),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Participants:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return CheckboxListTile(
                            value: contact['selected'] as bool,
                            onChanged: (value) {
                              setState(() {
                                contact['selected'] = value;
                              });
                            },
                            title: Text(contact['name'] as String),
                            secondary: CircleAvatar(
                              backgroundImage: NetworkImage(contact['avatar'] as String),
                            ),
                            activeColor: AppTheme.primaryColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
                    if (groupNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a group name')),
                      );
                      return;
                    }

                    // Get selected contacts
                    final selectedContacts = contacts.where((c) => c['selected'] == true).toList();

                    if (selectedContacts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one participant')),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      // Prepare participant data
                      final List<String> participantIds = [currentUser.id];
                      final Map<String, String> participantNames = {
                        currentUser.id: currentUser.name,
                      };
                      final Map<String, String?> participantAvatars = {
                        currentUser.id: currentUser.photoUrl,
                      };

                      // Add selected contacts
                      for (final contact in selectedContacts) {
                        participantIds.add(contact['id'] as String);
                        participantNames[contact['id'] as String] = contact['name'] as String;
                        participantAvatars[contact['id'] as String] = contact['avatar'] as String;
                      }

                      // Create the group conversation
                      final conversation = await chatProvider.createConversation(
                        name: groupNameController.text.trim(),
                        avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(groupNameController.text.trim())}&background=FF9800&color=fff',
                        participantIds: participantIds,
                        participantNames: participantNames,
                        participantAvatars: participantAvatars,
                        isGroup: true,
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
                  child: const Text('Create Group'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showCallHistoryDialog(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final callHistory = callProvider.callHistory;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Call History'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: callHistory.isEmpty
                      ? const Center(
                          child: Text('No call history'),
                        )
                      : ListView.builder(
                          itemCount: callHistory.length,
                          itemBuilder: (context, index) {
                            final call = callHistory[index];
                            final isOutgoing = call.isOutgoing;
                            final contactName = isOutgoing ? call.receiverName : call.callerName;
                            final contactAvatar = isOutgoing ? call.receiverAvatar : call.callerAvatar;

                            // Call status icon
                            IconData statusIcon;
                            Color statusColor;

                            if (call.status == CallStatus.missed || call.status == CallStatus.rejected) {
                              statusIcon = Icons.call_missed;
                              statusColor = Colors.red;
                            } else if (isOutgoing) {
                              statusIcon = Icons.call_made;
                              statusColor = Colors.green;
                            } else {
                              statusIcon = Icons.call_received;
                              statusColor = Colors.blue;
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                backgroundImage: contactAvatar != null
                                    ? NetworkImage(contactAvatar)
                                    : null,
                                child: contactAvatar == null
                                    ? Text(
                                        contactName[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 16,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(contactName),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    call.type == CallType.video ? Icons.videocam : Icons.call,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    call.duration != null
                                        ? '${call.durationText}'
                                        : call.statusText,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      call.type == CallType.video ? Icons.videocam : Icons.call,
                                      color: AppTheme.primaryColor,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _startCall(
                                        context,
                                        isOutgoing ? call.receiverId : call.callerId,
                                        isOutgoing ? call.receiverName : call.callerName,
                                        isOutgoing ? call.receiverAvatar : call.callerAvatar,
                                        call.type,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNewCallDialog(context, CallType.audio);
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('New Audio Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNewCallDialog(context, CallType.video);
                        },
                        icon: const Icon(Icons.videocam),
                        label: const Text('New Video Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewCallDialog(BuildContext context, CallType callType) {
    // Demo contacts
    final contacts = [
      {'id': '2', 'name': 'John Doe', 'avatar': 'https://ui-avatars.com/api/?name=John+Doe'},
      {'id': '3', 'name': 'Alice', 'avatar': 'https://ui-avatars.com/api/?name=Alice'},
      {'id': '4', 'name': 'Bob', 'avatar': 'https://ui-avatars.com/api/?name=Bob'},
      {'id': '5', 'name': 'Charlie', 'avatar': 'https://ui-avatars.com/api/?name=Charlie'},
      {'id': '6', 'name': 'Sarah Johnson', 'avatar': 'https://ui-avatars.com/api/?name=Sarah+Johnson'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(callType == CallType.audio ? 'Audio Call' : 'Video Call'),
          children: [
            ...contacts.map((contact) => SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _startCall(
                  context,
                  contact['id']!,
                  contact['name']!,
                  contact['avatar'],
                  callType,
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: NetworkImage(contact['avatar']!),
                  ),
                  const SizedBox(width: 16),
                  Text(contact['name']!),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  void _startCall(
    BuildContext context,
    String contactId,
    String contactName,
    String? contactAvatar,
    CallType callType,
  ) async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);

    try {
      await callProvider.startCall(
        receiverId: contactId,
        receiverName: contactName,
        receiverAvatar: contactAvatar,
        type: callType,
      );

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => callType == CallType.audio
                ? AudioCallScreen(call: callProvider.currentCall!)
                : VideoCallScreen(call: callProvider.currentCall!),
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
    final miningProvider = Provider.of<MiningProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mining'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showMiningHistory(context);
            },
          ),
        ],
      ),
      body: miningProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mining Status Card
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
                                  color: _getMiningStatusColor(miningProvider),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getMiningStatusText(miningProvider),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mining Status Description
                          Text(
                            _getMiningDescription(miningProvider),
                            style: const TextStyle(fontSize: 16),
                          ),

                          // Mining Progress
                          if (miningProvider.isMining)
                            _buildMiningProgress(context, miningProvider),

                          // Reward Ready to Claim
                          if (miningProvider.canClaimReward)
                            _buildClaimReward(context, miningProvider),

                          const SizedBox(height: 16),

                          // Mining Action Button
                          Center(
                            child: miningProvider.isLoading
                                ? const CircularProgressIndicator()
                                : _buildMiningActionButton(context, miningProvider),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mining Rate Card
                  if (!miningProvider.isMining)
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
                                  'Mining Rate',
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
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    miningProvider.selectedMiningRate.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Current Hash Rate: ${miningProvider.selectedMiningRate.hashRate.toStringAsFixed(1)} MH/s',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Upgrade your mining rate to earn more rewards:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),

                            // Mining Rate Options
                            ...MiningRate.rates.map((rate) => _buildMiningRateOption(
                              context,
                              rate,
                              miningProvider,
                            )).toList(),
                          ],
                        ),
                      ),
                    ),

                  // Mining Stats Card
                  if (miningProvider.activeMiningSession != null)
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
                            const Text(
                              'Mining Stats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                              'Mining Rate',
                              miningProvider.activeMiningSession!.miningRate.name,
                            ),
                            _buildStatRow(
                              'Hash Rate',
                              '${miningProvider.activeMiningSession!.hashRate.toStringAsFixed(2)} MH/s',
                            ),
                            _buildStatRow(
                              'Started',
                              _formatDateTime(miningProvider.activeMiningSession!.startTime),
                            ),
                            if (miningProvider.activeMiningSession!.status == MiningStatus.mining)
                              _buildStatRow(
                                'Estimated Reward',
                                '${miningProvider.activeMiningSession!.estimatedReward.toStringAsFixed(4)} MC',
                              ),
                            if (miningProvider.activeMiningSession!.status == MiningStatus.completed)
                              _buildStatRow(
                                'Reward',
                                '${miningProvider.activeMiningSession!.actualReward!.toStringAsFixed(4)} MC',
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

  Widget _buildMiningProgress(BuildContext context, MiningProvider miningProvider) {
    final session = miningProvider.activeMiningSession!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mining Progress'),
            Text('${session.progressPercentage.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: session.progressPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Time Remaining'),
            Text(session.remainingTimeFormatted),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimReward(BuildContext context, MiningProvider miningProvider) {
    final session = miningProvider.activeMiningSession!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.celebration,
                color: AppTheme.primaryColor,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mining Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You earned ${session.actualReward!.toStringAsFixed(4)} MC. Claim your reward now!',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMiningStatusColor(MiningProvider miningProvider) {
    if (miningProvider.isMining) {
      return Colors.green;
    } else if (miningProvider.canClaimReward) {
      return AppTheme.primaryColor;
    } else {
      return Colors.red;
    }
  }

  String _getMiningStatusText(MiningProvider miningProvider) {
    if (miningProvider.isMining) {
      return 'Mining';
    } else if (miningProvider.canClaimReward) {
      return 'Completed';
    } else {
      return 'Inactive';
    }
  }

  String _getMiningDescription(MiningProvider miningProvider) {
    if (miningProvider.isMining) {
      return 'Mining is in progress. Your device is currently mining cryptocurrency.';
    } else if (miningProvider.canClaimReward) {
      return 'Mining is complete! Claim your rewards now.';
    } else {
      return 'Mining is currently inactive. Start mining to earn cryptocurrency while chatting!';
    }
  }

  String _getActionButtonText(MiningProvider miningProvider) {
    if (miningProvider.isMining) {
      return 'Stop Mining';
    } else if (miningProvider.canClaimReward) {
      return 'Claim Reward';
    } else {
      return 'Start Mining';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dateStr at $timeStr';
  }

  void _showMiningHistory(BuildContext context) {
    final miningProvider = Provider.of<MiningProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Mining History'),
                automaticallyImplyLeading: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: miningProvider.miningSessions.isEmpty
                    ? const Center(
                        child: Text('No mining history yet'),
                      )
                    : ListView.builder(
                        itemCount: miningProvider.miningSessions.length,
                        itemBuilder: (context, index) {
                          final session = miningProvider.miningSessions[index];
                          return ListTile(
                            leading: Icon(
                              _getMiningHistoryIcon(session.status),
                              color: _getMiningHistoryColor(session.status),
                            ),
                            title: Text(
                              _getMiningHistoryTitle(session.status),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(_formatDateTime(session.startTime)),
                            trailing: session.status == MiningStatus.claimed || session.status == MiningStatus.completed
                                ? Text(
                                    '${session.actualReward?.toStringAsFixed(4) ?? session.estimatedReward.toStringAsFixed(4)} MC',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMiningHistoryIcon(MiningStatus status) {
    switch (status) {
      case MiningStatus.mining:
        return Icons.memory;
      case MiningStatus.completed:
        return Icons.check_circle;
      case MiningStatus.claimed:
        return Icons.monetization_on;
      case MiningStatus.idle:
        return Icons.cancel;
    }
  }

  Color _getMiningHistoryColor(MiningStatus status) {
    switch (status) {
      case MiningStatus.mining:
        return Colors.blue;
      case MiningStatus.completed:
        return Colors.green;
      case MiningStatus.claimed:
        return AppTheme.primaryColor;
      case MiningStatus.idle:
        return Colors.red;
    }
  }

  String _getMiningHistoryTitle(MiningStatus status) {
    switch (status) {
      case MiningStatus.mining:
        return 'Mining in Progress';
      case MiningStatus.completed:
        return 'Mining Completed';
      case MiningStatus.claimed:
        return 'Reward Claimed';
      case MiningStatus.idle:
        return 'Mining Stopped';
    }
  }

  Widget _buildMiningRateOption(
    BuildContext context,
    MiningRate rate,
    MiningProvider miningProvider,
  ) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final isSelected = miningProvider.selectedMiningRateLevel == rate.level;
    final isLocked = rate.level > miningProvider.selectedMiningRateLevel;
    final canAfford = walletProvider.balance >= rate.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? AppTheme.primaryColor
              : isLocked
                  ? Colors.grey
                  : Colors.green,
          child: Icon(
            isLocked ? Icons.lock : Icons.memory,
            color: Colors.white,
          ),
        ),
        title: Text(
          rate.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${rate.hashRate.toStringAsFixed(1)} MH/s'),
        trailing: isLocked
            ? ElevatedButton(
                onPressed: canAfford
                    ? () => _showPurchaseConfirmation(context, rate, miningProvider, walletProvider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey,
                ),
                child: Text('${rate.price.toStringAsFixed(1)} MC'),
              )
            : isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : TextButton(
                    onPressed: () => miningProvider.setMiningRateLevel(rate.level),
                    child: const Text('Select'),
                  ),
      ),
    );
  }

  void _showPurchaseConfirmation(
    BuildContext context,
    MiningRate rate,
    MiningProvider miningProvider,
    WalletProvider walletProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${rate.name} Mining Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to purchase the ${rate.name} mining rate?'),
            const SizedBox(height: 16),
            Text(
              'Price: ${rate.price.toStringAsFixed(1)} MC',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Your balance: ${walletProvider.balance.toStringAsFixed(1)} MC'),
            const SizedBox(height: 16),
            Text(rate.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await miningProvider.purchaseMiningRate(rate.level);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Successfully purchased ${rate.name} mining rate!'
                          : miningProvider.error ?? 'Failed to purchase mining rate',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiningActionButton(BuildContext context, MiningProvider miningProvider) {
    if (miningProvider.canClaimReward) {
      // Claim reward button
      return ElevatedButton.icon(
        onPressed: () => miningProvider.claimReward(),
        icon: const Icon(Icons.celebration),
        label: const Text('Claim Reward'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (miningProvider.isMining) {
      // Stop mining button
      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: miningProvider.activeMiningSession!.progressPercentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => miningProvider.stopMining(),
                    borderRadius: BorderRadius.circular(50),
                    child: const Center(
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Stop Mining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // Start mining button
      return Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('Mining button tapped');
                  // Check if user is logged in
                  final authService = AuthService();
                  if (authService.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please sign in to start mining')),
                    );
                    return;
                  }

                  // Start mining
                  miningProvider.startMining().then((_) {
                    if (miningProvider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(miningProvider.error!)),
                      );
                    }
                  });
                },
                borderRadius: BorderRadius.circular(60),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start Mining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }
}

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showTransactionHistory(context);
            },
          ),
        ],
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: AppTheme.primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${walletProvider.balance.toStringAsFixed(4)} MC',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          if (walletProvider.defaultWalletAddress != null) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                const Text(
                                  'Wallet Address:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _showReceiveDialog(context, walletProvider);
                                  },
                                  child: Text(
                                    walletProvider.defaultWalletAddress!.shortAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    _showReceiveDialog(context, walletProvider);
                                  },
                                  child: const Icon(
                                    Icons.qr_code,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showTransactionHistory(context);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  walletProvider.transactions.isEmpty
                      ? _buildEmptyTransactions()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: walletProvider.transactions.length > 5
                              ? 5
                              : walletProvider.transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = walletProvider.transactions[index];
                            return _buildTransactionItem(transaction);
                          },
                        ),

                  const SizedBox(height: 24),

                  // External Transactions
                  if (walletProvider.externalTransactions.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'External Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showExternalTransactionHistory(context);
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: walletProvider.externalTransactions.length > 3
                          ? 3
                          : walletProvider.externalTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = walletProvider.externalTransactions[index];
                        return _buildExternalTransactionItem(transaction);
                      },
                    ),

                    const SizedBox(height: 24),
                  ],

                  // Your Assets
                  const Text(
                    'Your Assets',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.memory,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: const Text(
                        'MineChat Coin (MC)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${walletProvider.balance.toStringAsFixed(4)} MC'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showAssetDetails(context, walletProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              onPressed: () {
                _showReceiveDialog(context, walletProvider);
              },
              heroTag: 'receive',
              backgroundColor: Colors.green,
              icon: const Icon(Icons.call_received, color: Colors.white),
              label: const Text('Receive', style: TextStyle(color: Colors.white)),
            ),
            FloatingActionButton.extended(
              onPressed: () {
                _showSendDialog(context, walletProvider);
              },
              heroTag: 'send',
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isDeposit = transaction.isDeposit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDeposit
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          child: Icon(
            isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatDateTime(transaction.timestamp)),
        trailing: Text(
          '${isDeposit ? '+' : '-'}${transaction.amount.toStringAsFixed(4)} MC',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDeposit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dateStr at $timeStr';
  }

  void _showTransactionHistory(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Transaction History'),
                automaticallyImplyLeading: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: walletProvider.transactions.isEmpty
                    ? _buildEmptyTransactions()
                    : ListView.builder(
                        itemCount: walletProvider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = walletProvider.transactions[index];
                          return _buildTransactionItem(transaction);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssetDetails(BuildContext context, WalletProvider walletProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Icon(
                  Icons.memory,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MineChat Coin (MC)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${walletProvider.balance.toStringAsFixed(4)} MC',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MineChat Coin is the native cryptocurrency of the MineChat app. You can earn MC by mining or receive it from other users.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSendDialog(context, walletProvider);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendDialog(BuildContext context, WalletProvider walletProvider) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send MC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Recipient Address',
                hintText: 'Enter recipient address',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount to send',
                prefixIcon: const Icon(Icons.monetization_on),
                suffixText: 'MC',
                helperText: 'Available: ${walletProvider.balance.toStringAsFixed(4)} MC',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'Add a note',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
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
          ElevatedButton(
            onPressed: () async {
              // Validate amount
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an amount')),
                );
                return;
              }

              double? amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              // Check if user has enough balance
              if (amount > walletProvider.balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient balance')),
                );
                return;
              }

              // Validate address
              if (addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a recipient address')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await walletProvider.sendToExternalAddress(
                  externalAddress: addressController.text,
                  amount: amount,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully sent ${amount.toStringAsFixed(2)} MC'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalTransactionItem(ExternalTransaction transaction) {
    final isOutgoing = transaction.isOutgoing;

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;

    switch (transaction.status) {
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case TransactionStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case TransactionStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOutgoing
              ? Colors.red.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
            color: isOutgoing ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          isOutgoing
              ? 'Sent to External Wallet'
              : 'Received from External Wallet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateTime(transaction.timestamp)),
            if (transaction.externalAddress != null)
              Text(
                'Address: ${transaction.externalAddress!.substring(0, 8)}...',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isOutgoing ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isOutgoing ? Colors.red : Colors.green,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  transaction.status.toString().split('.').last,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: transaction.externalAddress != null,
      ),
    );
  }

  void _showExternalTransactionHistory(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('External Transactions'),
                automaticallyImplyLeading: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: walletProvider.externalTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No external transactions yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: walletProvider.externalTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = walletProvider.externalTransactions[index];
                          return _buildExternalTransactionItem(transaction);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, WalletProvider walletProvider) {
    final walletAddress = walletProvider.defaultWalletAddress;

    if (walletAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No wallet address found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive MC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR Code (placeholder)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code,
                  size: 150,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Wallet address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Wallet Address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          walletAddress.formattedAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Simulate receive button (for demo purposes)
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await walletProvider.simulateReceiveFromExternal();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Received crypto from external wallet'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Simulate Receive (Demo)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
