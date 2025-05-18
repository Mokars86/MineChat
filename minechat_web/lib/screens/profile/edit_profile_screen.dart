import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  XFile? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  void _loadUserData() {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _bioController.text = currentUser.bio ?? '';
      _emailController.text = currentUser.email ?? '';
      _phoneController.text = currentUser.phone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('You need to be logged in to edit your profile'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            backgroundImage: _getProfileImage(currentUser.photoUrl),
                            child: _imageFile == null && currentUser.photoUrl == null
                                ? Text(
                                    currentUser.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 40,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        
                        // Edit button
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Profile Picture'),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                          });
                        },
                        child: const Text('Remove Selected Image'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio field
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icon(Icons.info),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Simple email validation
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  ImageProvider? _getProfileImage(String? photoUrl) {
    if (_imageFile != null) {
      if (kIsWeb) {
        return NetworkImage(_imageFile!.path);
      } else {
        return FileImage(File(_imageFile!.path));
      }
    } else if (photoUrl != null) {
      return NetworkImage(photoUrl);
    }
    return null;
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show image source options
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) return;
      
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: ${e.toString()}';
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      
      // Upload image if selected
      String? photoUrl;
      if (_imageFile != null) {
        // In a real app, you would upload the image to a storage service
        // For this demo, we'll just use the local path or a placeholder URL
        if (kIsWeb) {
          photoUrl = _imageFile!.path;
        } else {
          // For simplicity, we'll use a generated avatar URL
          photoUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.trim())}';
        }
      }
      
      // Update user profile
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
