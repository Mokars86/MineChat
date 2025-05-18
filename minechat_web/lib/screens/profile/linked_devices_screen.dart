import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'link_device_screen.dart';
import 'scan_link_code_screen.dart';

class LinkedDevice {
  final String id;
  final String name;
  final String type;
  final DateTime lastActive;
  final bool isCurrentDevice;

  LinkedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastActive,
    this.isCurrentDevice = false,
  });
}

class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  bool _isLoading = true;
  List<LinkedDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would fetch this from your backend
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Demo data
      setState(() {
        _devices = [
          LinkedDevice(
            id: '1',
            name: 'Current Browser',
            type: 'Web',
            lastActive: DateTime.now(),
            isCurrentDevice: true,
          ),
          LinkedDevice(
            id: '2',
            name: 'iPhone 13',
            type: 'iOS',
            lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          LinkedDevice(
            id: '3',
            name: 'Samsung Galaxy S21',
            type: 'Android',
            lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          LinkedDevice(
            id: '4',
            name: 'Work Laptop',
            type: 'Web',
            lastActive: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading devices: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlinkDevice(LinkedDevice device) async {
    if (device.isCurrentDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot unlink your current device')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would call your backend to unlink the device
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _devices.removeWhere((d) => d.id == device.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name} has been unlinked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking device: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlinkAllDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would call your backend to unlink all devices
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      setState(() {
        _devices = _devices.where((d) => d.isCurrentDevice).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All devices have been unlinked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking devices: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUnlinkConfirmation(LinkedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Device'),
        content: Text('Are you sure you want to unlink ${device.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unlinkDevice(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink All Devices'),
        content: const Text('Are you sure you want to unlink all devices except this one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unlinkAllDevices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlink All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Link device options
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Generate QR code button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LinkDeviceScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Generate QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Scan QR code button
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanLinkCodeScreen(),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadDevices();
                            }
                          });
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),

                // Devices list
                Expanded(
                  child: _devices.isEmpty
                      ? const Center(
                          child: Text('No linked devices'),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            return ListTile(
                              leading: Icon(
                                _getDeviceIcon(device.type),
                                color: device.isCurrentDevice
                                    ? AppTheme.primaryColor
                                    : null,
                              ),
                              title: Text(
                                device.name,
                                style: TextStyle(
                                  fontWeight: device.isCurrentDevice
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                _formatLastActive(device.lastActive),
                              ),
                              trailing: device.isCurrentDevice
                                  ? const Chip(
                                      label: Text('Current'),
                                      backgroundColor: AppTheme.primaryColor,
                                      labelStyle: TextStyle(color: Colors.white),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.link_off),
                                      onPressed: () => _showUnlinkConfirmation(device),
                                    ),
                            );
                          },
                        ),
                ),

                // Unlink all devices button
                if (_devices.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton.icon(
                      onPressed: _showUnlinkAllConfirmation,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Unlink All Other Devices',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Android':
        return Icons.phone_android;
      case 'iOS':
        return Icons.phone_iphone;
      case 'Web':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inSeconds < 60) {
      return 'Active now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours} hours ago';
    } else {
      return 'Active ${difference.inDays} days ago';
    }
  }
}
