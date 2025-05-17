import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/call_models.dart';
import '../../providers/call_provider.dart';
import '../../theme.dart';

class VideoCallScreen extends StatefulWidget {
  final Call call;

  const VideoCallScreen({
    super.key,
    required this.call,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late Timer _callTimer;
  Duration _callDuration = Duration.zero;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isRearCamera = false;
  bool _areControlsVisible = true;

  @override
  void initState() {
    super.initState();
    
    if (widget.call.status == CallStatus.ongoing) {
      _startCallTimer();
    }
    
    // Auto-hide controls after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && widget.call.status == CallStatus.ongoing) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(VideoCallScreen oldWidget) {
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

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    
    if (_areControlsVisible) {
      // Auto-hide controls after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && widget.call.status == CallStatus.ongoing) {
          setState(() {
            _areControlsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final call = callProvider.currentCall ?? widget.call;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: call.status == CallStatus.ongoing ? _toggleControls : null,
        child: Stack(
          children: [
            // Remote video (full screen)
            if (call.status == CallStatus.ongoing && !_isCameraOff)
              Container(
                color: Colors.black,
                child: Center(
                  child: Image.network(
                    'https://picsum.photos/800/1600',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                color: Colors.black,
                child: Center(
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
                            ? 'Camera is off'
                            : call.statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Local video (picture-in-picture)
            if (call.status == CallStatus.ongoing && !_isCameraOff)
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    // Toggle camera
                    setState(() {
                      _isRearCamera = !_isRearCamera;
                    });
                  },
                  child: Container(
                    width: 100,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://picsum.photos/100/150',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            
            // Call duration
            if (call.status == CallStatus.ongoing && _areControlsVisible)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _durationText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Call controls
            if (_areControlsVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: call.status == CallStatus.ringing
                      ? _buildRingingControls(context, call, callProvider)
                      : _buildOngoingControls(context, callProvider),
                ),
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
            icon: Icons.videocam,
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
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'Camera On' : 'Camera Off',
              onPressed: () {
                setState(() {
                  _isCameraOff = !_isCameraOff;
                });
              },
            ),
            _buildControlButton(
              icon: Icons.switch_camera,
              label: 'Flip',
              onPressed: () {
                setState(() {
                  _isRearCamera = !_isRearCamera;
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
