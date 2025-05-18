import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../chat/chat_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR Scanner
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                
                // Scanning overlay
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  width: 250,
                  height: 250,
                ),
                
                // Scanning animation
                if (_isScanning && !_isProcessing)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Processing indicator
                if (_isProcessing)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                
                // Error message
                if (_errorMessage != null)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const Text(
                  'Scan a QR code to add a contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Position the QR code within the frame to scan',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final Barcode barcode = barcodes.first;
    final String? rawValue = barcode.rawValue;
    
    if (rawValue == null) return;
    
    // Stop scanning while processing
    setState(() {
      _isScanning = false;
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      // Parse the QR code data
      // Expected format: "minechat:contact:userId:userName"
      if (rawValue.startsWith('minechat:contact:')) {
        final parts = rawValue.split(':');
        if (parts.length >= 4) {
          final userId = parts[2];
          final userName = parts[3];
          
          // Add the contact
          await _addContact(userId, userName);
        } else {
          _showError('Invalid QR code format');
        }
      } else {
        _showError('Not a MineChat contact QR code');
      }
    } catch (e) {
      _showError('Error processing QR code: ${e.toString()}');
    }
  }

  Future<void> _addContact(String contactId, String contactName) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      _showError('You need to be logged in to add contacts');
      return;
    }
    
    try {
      // Create a new conversation with the scanned contact
      final conversation = await chatProvider.createConversation(
        name: contactName,
        avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(contactName)}',
        participantIds: [currentUser.id, contactId],
        participantNames: {
          currentUser.id: currentUser.name,
          contactId: contactName,
        },
        participantAvatars: {
          currentUser.id: currentUser.photoUrl,
          contactId: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(contactName)}',
        },
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact $contactName added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to the chat screen
        chatProvider.selectConversation(conversation.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversation.id,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error adding contact: ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
      _errorMessage = message;
    });
    
    // Resume scanning after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _errorMessage = null;
        });
      }
    });
  }
}
