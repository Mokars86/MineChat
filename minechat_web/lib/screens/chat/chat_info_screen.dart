import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import '../../theme.dart';

class ChatInfoScreen extends StatelessWidget {
  final ChatConversation conversation;

  const ChatInfoScreen({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Info'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Chat avatar and name
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: conversation.avatar != null
                        ? NetworkImage(conversation.avatar!)
                        : null,
                    child: conversation.avatar == null
                        ? Text(
                            conversation.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    conversation.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    conversation.isGroup
                        ? '${conversation.participantIds.length} participants'
                        : 'Last seen recently',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Chat options
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.volume_off : Icons.volume_up,
                color: AppTheme.primaryColor,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                chatProvider.muteConversation(
                  conversation.id,
                  !conversation.isMuted,
                );
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.wallpaper,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Chat Wallpaper'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat wallpaper not implemented yet')),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.block,
                color: Colors.red,
              ),
              title: const Text('Block'),
              onTap: () {
                _showBlockConfirmation(context);
              },
            ),
            
            ListTile(
              leading: const Icon(
                Icons.report,
                color: Colors.orange,
              ),
              title: const Text('Report'),
              onTap: () {
                _showReportDialog(context);
              },
            ),
            
            const Divider(),
            
            // Media, links, and docs
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Media, Links, and Docs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMediaCategory(
                          context,
                          Icons.photo,
                          'Photos',
                          '0',
                        ),
                      ),
                      Expanded(
                        child: _buildMediaCategory(
                          context,
                          Icons.link,
                          'Links',
                          '0',
                        ),
                      ),
                      Expanded(
                        child: _buildMediaCategory(
                          context,
                          Icons.insert_drive_file,
                          'Docs',
                          '0',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Participants (for group chats)
            if (conversation.isGroup) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Participants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${conversation.participantIds.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...conversation.participantIds.map((id) {
                      final name = conversation.participantNames[id] ?? 'Unknown';
                      final avatar = conversation.participantAvatars[id];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          backgroundImage: avatar != null
                              ? NetworkImage(avatar)
                              : null,
                          child: avatar == null
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(name),
                        subtitle: const Text('Last seen recently'),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add participant not implemented yet')),
                          );
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Participant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
            ],
            
            // Exit and delete options
            ListTile(
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.red,
              ),
              title: Text(conversation.isGroup ? 'Exit Group' : 'Delete Chat'),
              onTap: () {
                _showExitOrDeleteConfirmation(context);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCategory(
    BuildContext context,
    IconData icon,
    String title,
    String count,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title not implemented yet')),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block Contact'),
          content: Text('Are you sure you want to block ${conversation.name}?'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block functionality not implemented yet')),
                );
              },
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Contact'),
          content: Text('Are you sure you want to report ${conversation.name}?'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report functionality not implemented yet')),
                );
              },
              child: const Text('Report', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  void _showExitOrDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(conversation.isGroup ? 'Exit Group' : 'Delete Chat'),
          content: Text(
            conversation.isGroup
                ? 'Are you sure you want to exit ${conversation.name}?'
                : 'Are you sure you want to delete this chat with ${conversation.name}?',
          ),
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
                Navigator.pop(context); // Go back to chat list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      conversation.isGroup
                          ? 'Exit group functionality not implemented yet'
                          : 'Delete chat functionality not implemented yet',
                    ),
                  ),
                );
              },
              child: Text(
                conversation.isGroup ? 'Exit' : 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
