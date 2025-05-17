import 'package:flutter/material.dart';
import '../../../models/chat_models.dart';
import '../../../theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String, MessageType, {Map<String, dynamic>? metadata}) onSendMessage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposing = false;
  bool _showAttachments = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    widget.onSendMessage(text.trim(), MessageType.text);
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Attachment options
        if (_showAttachments)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  color: Colors.purple,
                  label: 'Photos',
                  onTap: () => _handleAttachment(MessageType.image),
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  color: Colors.red,
                  label: 'Camera',
                  onTap: () => _handleAttachment(MessageType.image),
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  color: Colors.blue,
                  label: 'Document',
                  onTap: () => _handleAttachment(MessageType.document),
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  color: Colors.green,
                  label: 'Location',
                  onTap: () => _handleAttachment(MessageType.location),
                ),
                _buildAttachmentOption(
                  icon: Icons.person,
                  color: Colors.orange,
                  label: 'Contact',
                  onTap: () => _handleAttachment(MessageType.contact),
                ),
              ],
            ),
          ),
        
        // Message input bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: Icon(
                  _showAttachments ? Icons.close : Icons.attach_file,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showAttachments = !_showAttachments;
                  });
                },
              ),
              
              // Text field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: _isComposing ? _handleSubmitted : null,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              
              // Emoji button
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                color: AppTheme.primaryColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emoji picker not implemented yet')),
                  );
                },
              ),
              
              // Camera button
              IconButton(
                icon: const Icon(Icons.camera_alt),
                color: AppTheme.primaryColor,
                onPressed: () {
                  _handleAttachment(MessageType.image);
                },
              ),
              
              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                color: AppTheme.primaryColor,
                onPressed: _isComposing
                    ? () => _handleSubmitted(_messageController.text)
                    : () {
                        // If not composing text, show voice recording UI
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voice recording not implemented yet')),
                        );
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleAttachment(MessageType type) {
    // Close the attachment panel
    setState(() {
      _showAttachments = false;
    });
    
    // Show a demo message for each attachment type
    switch (type) {
      case MessageType.image:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image attachment not implemented yet')),
        );
        break;
      
      case MessageType.video:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video attachment not implemented yet')),
        );
        break;
      
      case MessageType.audio:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio attachment not implemented yet')),
        );
        break;
      
      case MessageType.document:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document attachment not implemented yet')),
        );
        break;
      
      case MessageType.location:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location attachment not implemented yet')),
        );
        break;
      
      case MessageType.contact:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact attachment not implemented yet')),
        );
        break;
      
      default:
        break;
    }
  }
}
