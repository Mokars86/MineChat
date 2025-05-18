import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class MyQRCodeScreen extends StatefulWidget {
  const MyQRCodeScreen({super.key});

  @override
  State<MyQRCodeScreen> createState() => _MyQRCodeScreenState();
}

class _MyQRCodeScreenState extends State<MyQRCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to view your QR code'),
        ),
      );
    }

    // Generate QR code data
    // Format: "minechat:contact:userId:userName"
    final qrData = 'minechat:contact:${currentUser.id}:${currentUser.name}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isSaving ? null : () => _shareQRCode(qrData),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isSaving ? null : _saveQRCode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your Contact QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Let others scan this code to add you as a contact',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // QR Code
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.primaryColor,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.primaryColor,
                            ),
                            embeddedImage: currentUser.photoUrl != null
                                ? NetworkImage(currentUser.photoUrl!)
                                : null,
                            embeddedImageStyle: QrEmbeddedImageStyle(
                              size: const Size(40, 40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentUser.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MineChat User',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Loading indicator
                  if (_isSaving) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Processing...'),
                  ],
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const Text(
                  'Share your QR code with others',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'They can scan it to add you as a contact in MineChat',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveQRCode,
                        icon: const Icon(Icons.download),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _shareQRCode(qrData),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQRCode() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/minechat_qr_code.png');
        await file.writeAsBytes(pngBytes);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR code saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to get image data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving QR code: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _shareQRCode(String qrData) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Share the QR code data as text
      await Share.share(
        'Scan this QR code to add me on MineChat: $qrData',
        subject: 'My MineChat Contact',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sharing QR code: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
