import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_models.dart';
import '../../providers/call_provider.dart';
import '../../theme.dart';

class AudioCallScreen extends StatefulWidget {
  final Call call;

  const AudioCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late Timer _callTimer;
  Duration _callDuration = Duration.zero;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.call.status == CallStatus.ongoing) {
      _startCallTimer();
    }
  }

  @override
  void didUpdateWidget(AudioCallScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start timer when call is answered
    if (oldWidget.call.status != CallStatus.ongoing && 
        widget.call.status == CallStatus.ongoing) {
      _startCallTimer();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration = Duration(seconds: timer.tick);
      });
    });
  }

  @override
  void dispose() {
    if (_callTimer.isActive) {
      _callTimer.cancel();
    }
    super.dispose();
  }

  String get _durationText {
    final minutes = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    if (_callDuration.inHours > 0) {
      final hours = _callDuration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final call = callProvider.currentCall ?? widget.call;
    
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
                  // Contact avatar
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: call.isOutgoing
                        ? call.receiverAvatar != null
                            ? NetworkImage(call.receiverAvatar!)
                            : null
                        : call.callerAvatar != null
                            ? NetworkImage(call.callerAvatar!)
                            : null,
                    child: (call.isOutgoing
                            ? call.receiverAvatar == null
                            : call.callerAvatar == null)
                        ? Text(
                            call.isOutgoing
                                ? call.receiverName[0].toUpperCase()
                                : call.callerName[0].toUpperCase(),
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
                    call.isOutgoing ? call.receiverName : call.callerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Call status
                  Text(
                    call.status == CallStatus.ongoing
                        ? _durationText
                        : call.statusText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  // Audio wave animation (simplified)
                  if (call.status == CallStatus.ongoing)
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          7,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 6,
                            height: 10.0 + (index % 3 + 1) * 10.0,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Call controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: call.status == CallStatus.ringing
                  ? _buildRingingControls(context, call, callProvider)
                  : _buildOngoingControls(context, callProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingingControls(
    BuildContext context,
    Call call,
    CallProvider callProvider,
  ) {
    // Different controls for incoming vs outgoing calls
    if (call.isOutgoing) {
      // Outgoing call controls
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCallButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              callProvider.endCall();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    } else {
      // Incoming call controls
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCallButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              callProvider.rejectCall();
              Navigator.of(context).pop();
            },
          ),
          _buildCallButton(
            icon: Icons.call,
            color: Colors.green,
            onPressed: () {
              callProvider.answerCall();
            },
          ),
        ],
      );
    }
  }

  Widget _buildOngoingControls(
    BuildContext context,
    CallProvider callProvider,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              label: _isMuted ? 'Unmute' : 'Mute',
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
              },
            ),
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              label: _isSpeakerOn ? 'Speaker Off' : 'Speaker On',
              onPressed: () {
                setState(() {
                  _isSpeakerOn = !_isSpeakerOn;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildCallButton(
          icon: Icons.call_end,
          color: Colors.red,
          onPressed: () {
            callProvider.endCall();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
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
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
