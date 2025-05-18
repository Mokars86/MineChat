import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final String? phone;

  User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.bio,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'phone': phone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      bio: json['bio'],
      phone: json['phone'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _authStateController.stream;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialize the auth service
  Future<void> init() async {
    // Check if user is already logged in from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      try {
        final Map<String, dynamic> userData = Map<String, dynamic>.from({
          'id': prefs.getString('userId') ?? '',
          'name': prefs.getString('userName') ?? '',
          'email': prefs.getString('userEmail'),
          'photoUrl': prefs.getString('userPhotoUrl'),
          'bio': prefs.getString('userBio'),
          'phone': prefs.getString('userPhone'),
        });

        _currentUser = User.fromJson(userData);
        _authStateController.add(_currentUser);
      } catch (e) {
        // If there's an error parsing the user data, clear it
        await prefs.remove('userId');
        await prefs.remove('userName');
        await prefs.remove('userEmail');
        await prefs.remove('userPhotoUrl');
        await prefs.remove('userBio');
        await prefs.remove('userPhone');
        _currentUser = null;
        _authStateController.add(null);
      }
    } else {
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Demo login - in a real app, this would validate with a backend
    if (email == 'user@example.com' && password == 'password123') {
      _currentUser = User(
        id: '1',
        name: 'Demo User',
        email: email,
        photoUrl: 'https://ui-avatars.com/api/?name=Demo+User',
        bio: 'I am a demo user',
        phone: '+1234567890',
      );

      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _currentUser!.id);
      await prefs.setString('userName', _currentUser!.name);
      await prefs.setString('userEmail', _currentUser!.email ?? '');
      await prefs.setString('userPhotoUrl', _currentUser!.photoUrl ?? '');
      await prefs.setString('userBio', _currentUser!.bio ?? '');
      await prefs.setString('userPhone', _currentUser!.phone ?? '');

      _authStateController.add(_currentUser);
      return true;
    } else {
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String name, String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Demo registration - in a real app, this would create a user in a backend
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}',
      bio: '',
      phone: '',
    );

    // Save user data to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('userEmail', _currentUser!.email ?? '');
    await prefs.setString('userPhotoUrl', _currentUser!.photoUrl ?? '');
    await prefs.setString('userBio', _currentUser!.bio ?? '');
    await prefs.setString('userPhone', _currentUser!.phone ?? '');

    _authStateController.add(_currentUser);
    return true;
  }

  // Sign out
  Future<void> signOut() async {
    // Clear user data from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhotoUrl');
    await prefs.remove('userBio');
    await prefs.remove('userPhone');

    _currentUser = null;
    _authStateController.add(null);
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, this would send a password reset email
    return true;
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    String? phone,
  }) async {
    if (_currentUser == null) return false;

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Update user data
    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      photoUrl: photoUrl,
      bio: bio,
      phone: phone,
    );

    // Save updated user data to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('userEmail', _currentUser!.email ?? '');
    await prefs.setString('userPhotoUrl', _currentUser!.photoUrl ?? '');
    await prefs.setString('userBio', _currentUser!.bio ?? '');
    await prefs.setString('userPhone', _currentUser!.phone ?? '');

    // Notify listeners
    _authStateController.add(_currentUser);

    return true;
  }

  // Dispose
  void dispose() {
    _authStateController.close();
  }
}
