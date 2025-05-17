import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_models.dart';
import '../../providers/call_provider.dart';
import '../../theme.dart';
import '../call/audio_call_screen.dart';
import '../call/video_call_screen.dart';
import 'package:intl/intl.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not implemented yet')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearCallHistoryDialog(context, callProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear call history'),
              ),
            ],
          ),
        ],
      ),
      body: callProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : callProvider.callHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: callProvider.callHistory.length,
                  itemBuilder: (context, index) {
                    final call = callProvider.callHistory[index];
                    return _buildCallHistoryItem(context, call, callProvider);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewCallDialog(context);
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No call history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call history will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(
    BuildContext context,
    Call call,
    CallProvider callProvider,
  ) {
    final isOutgoing = call.isOutgoing;
    final contactName = isOutgoing ? call.receiverName : call.callerName;
    final contactAvatar = isOutgoing ? call.receiverAvatar : call.callerAvatar;
    
    // Format the timestamp
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final callDate = DateTime(
      call.startTime.year,
      call.startTime.month,
      call.startTime.day,
    );
    
    String timeString;
    if (callDate == today) {
      // Today, show time
      timeString = DateFormat.jm().format(call.startTime);
    } else if (callDate == yesterday) {
      // Yesterday
      timeString = 'Yesterday';
    } else {
      // Other days, show date
      timeString = DateFormat.yMMMd().format(call.startTime);
    }
    
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
    
    return Dismissible(
      key: Key(call.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        callProvider.deleteCallFromHistory(call.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call removed from history')),
        );
      },
      child: ListTile(
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
                  ? '${call.durationText} • $timeString'
                  : timeString,
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            call.type == CallType.video ? Icons.videocam : Icons.call,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            _startCall(
              context,
              callProvider,
              isOutgoing ? call.receiverId : call.callerId,
              isOutgoing ? call.receiverName : call.callerName,
              isOutgoing ? call.receiverAvatar : call.callerAvatar,
              call.type,
            );
          },
        ),
        onTap: () {
          _showCallDetails(context, call);
        },
      ),
    );
  }

  void _showCallDetails(BuildContext context, Call call) {
    final isOutgoing = call.isOutgoing;
    final contactName = isOutgoing ? call.receiverName : call.callerName;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Call Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Contact', contactName),
              _buildDetailRow(
                'Type',
                call.type == CallType.video ? 'Video Call' : 'Audio Call',
              ),
              _buildDetailRow(
                'Direction',
                isOutgoing ? 'Outgoing' : 'Incoming',
              ),
              _buildDetailRow('Status', call.statusText),
              _buildDetailRow(
                'Time',
                DateFormat.yMMMd().add_jm().format(call.startTime),
              ),
              if (call.duration != null)
                _buildDetailRow('Duration', call.durationText),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showClearCallHistoryDialog(
    BuildContext context,
    CallProvider callProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Call History'),
          content: const Text(
            'Are you sure you want to clear your call history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                callProvider.clearCallHistory();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('New Call'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _showContactSelectionDialog(context, CallType.audio);
              },
              child: const Row(
                children: [
                  Icon(Icons.call),
                  SizedBox(width: 16),
                  Text('Audio Call'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                _showContactSelectionDialog(context, CallType.video);
              },
              child: const Row(
                children: [
                  Icon(Icons.videocam),
                  SizedBox(width: 16),
                  Text('Video Call'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showContactSelectionDialog(BuildContext context, CallType callType) {
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
                  Provider.of<CallProvider>(context, listen: false),
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
    CallProvider callProvider,
    String contactId,
    String contactName,
    String? contactAvatar,
    CallType callType,
  ) async {
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
