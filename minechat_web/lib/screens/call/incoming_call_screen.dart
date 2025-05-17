import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_models.dart';
import '../../providers/call_provider.dart';
import '../../theme.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final call = callProvider.currentCall;
    
    if (call == null) {
      // No active call, close the screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Call info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Call type indicator
                  Text(
                    call.type == CallType.audio ? 'Audio Call' : 'Video Call',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Contact avatar
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: call.callerAvatar != null
                        ? NetworkImage(call.callerAvatar!)
                        : null,
                    child: call.callerAvatar == null
                        ? Text(
                            call.callerName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 60,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Contact name
                  Text(
                    call.callerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Call status
                  Text(
                    'Incoming call...',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Call controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  // Swipe instruction
                  const Text(
                    'Swipe up to answer',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Call buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCallButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'Decline',
                        onPressed: () async {
                          await callProvider.rejectCall();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      _buildCallButton(
                        icon: call.type == CallType.audio ? Icons.call : Icons.videocam,
                        color: Colors.green,
                        label: 'Accept',
                        onPressed: () async {
                          await callProvider.answerCall();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => call.type == CallType.audio
                                    ? AudioCallScreen(call: call)
                                    : VideoCallScreen(call: call),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 36,
            padding: const EdgeInsets.all(12),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
