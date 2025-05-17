import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../theme.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSender = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Card(
            color: isMe 
                ? AppTheme.primaryColor 
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (showSender)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isMe ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  
                  // Message content
                  _buildMessageContent(context),
                  
                  // Timestamp and status
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.isDeleted) {
      return Text(
        'This message was deleted',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: isMe ? Colors.white70 : Colors.grey[600],
        ),
      );
    }

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : null,
          ),
        );
      
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.content,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
            if (message.metadata != null && message.metadata!['caption'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.metadata!['caption'],
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                  ),
                ),
              ),
          ],
        );
      
      case MessageType.video:
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          height: 200,
          width: double.infinity,
          child: const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 48,
            ),
          ),
        );
      
      case MessageType.audio:
        return Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: isMe ? Colors.white : AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:30',
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white : null,
                ),
              ),
            ],
          ),
        );
      
      case MessageType.document:
        return Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.metadata?['fileName'] ?? 'Document',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : null,
                      ),
                    ),
                    Text(
                      message.metadata?['fileSize'] ?? '0 KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      
      case MessageType.location:
        return Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.location_on,
              size: 48,
              color: Colors.red,
            ),
          ),
        );
      
      case MessageType.contact:
        return Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.metadata?['contactName'] ?? 'Contact',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : null,
                      ),
                    ),
                    Text(
                      message.metadata?['contactPhone'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : null,
          ),
        );
    }
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (message.status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        iconColor = Colors.white70;
        break;
      case MessageStatus.sent:
        iconData = Icons.check;
        iconColor = Colors.white70;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        iconColor = Colors.white70;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = Colors.blue;
        break;
    }
    
    return Icon(
      iconData,
      size: 12,
      color: iconColor,
    );
  }
}
