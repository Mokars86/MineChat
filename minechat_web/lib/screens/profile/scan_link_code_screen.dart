import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class ScanLinkCodeScreen extends StatefulWidget {
  const ScanLinkCodeScreen({super.key});

  @override
  State<ScanLinkCodeScreen> createState() => _ScanLinkCodeScreenState();
}

class _ScanLinkCodeScreenState extends State<ScanLinkCodeScreen> {
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
        title: const Text('Scan Link Code'),
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
                  'Scan the QR code from your other device',
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
      // Expected format: "minechat:link:userId:sessionId:timestamp"
      if (rawValue.startsWith('minechat:link:')) {
        final parts = rawValue.split(':');
        if (parts.length >= 5) {
          final userId = parts[2];
          final sessionId = parts[3];
          final timestamp = int.tryParse(parts[4]) ?? 0;
          
          // Check if QR code is expired (valid for 60 seconds)
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - timestamp > 60000) {
            _showError('QR code has expired. Please refresh and try again.');
            return;
          }
          
          // Link the device
          await _linkDevice(userId, sessionId);
        } else {
          _showError('Invalid QR code format');
        }
      } else {
        _showError('Not a MineChat link QR code');
      }
    } catch (e) {
      _showError('Error processing QR code: ${e.toString()}');
    }
  }

  Future<void> _linkDevice(String userId, String sessionId) async {
    try {
      // In a real app, you would call your backend to link the device
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device linked successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to the linked devices screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error linking device: ${e.toString()}');
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
