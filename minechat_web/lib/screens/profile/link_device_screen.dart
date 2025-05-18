import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class LinkDeviceScreen extends StatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  bool _isLoading = true;
  String _qrData = '';
  Timer? _refreshTimer;
  int _timeLeft = 60; // QR code valid for 60 seconds

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = 60;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Regenerate QR code when timer expires
          _generateQRCode();
          _timeLeft = 60;
        }
      });
    });
  }

  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Generate a unique session ID
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create QR code data
      // Format: "minechat:link:userId:sessionId:timestamp"
      _qrData = 'minechat:link:${user.id}:$sessionId:${DateTime.now().millisecondsSinceEpoch}';
      
      // In a real app, you would register this session with your backend
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating QR code: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link a Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _generateQRCode();
              _startTimer();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Instructions
              const Text(
                'Scan this QR code to link a device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Open MineChat on your other device and scan this code to link it to your account',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // QR Code
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryColor,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'QR code expires in $_timeLeft seconds',
                        style: TextStyle(
                          color: _timeLeft < 10 ? Colors.red : Colors.grey,
                          fontWeight: _timeLeft < 10 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // Steps
              const Text(
                'How to link a device:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(
                1,
                'Open MineChat on your other device',
                Icons.smartphone,
              ),
              _buildStep(
                2,
                'Go to Settings > Linked Devices',
                Icons.settings,
              ),
              _buildStep(
                3,
                'Tap on "Link a Device"',
                Icons.link,
              ),
              _buildStep(
                4,
                'Point your camera at this screen to scan the QR code',
                Icons.qr_code_scanner,
              ),
              
              const SizedBox(height: 30),
              
              // Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your messages will be synced across all linked devices. You can manage your linked devices in the profile settings.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
