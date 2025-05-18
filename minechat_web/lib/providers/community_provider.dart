import 'dart:async';
import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  List<Community> _communities = [];
  Community? _selectedCommunity;
  CommunityChannel? _selectedChannel;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  List<Community> _searchResults = [];

  StreamSubscription? _communitiesSubscription;

  List<Community> get communities => _searchQuery.isEmpty
      ? _communities
      : _searchResults;

  Community? get selectedCommunity => _selectedCommunity;
  CommunityChannel? get selectedChannel => _selectedChannel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  CommunityProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _communityService.init();

      // Listen for communities updates
      _communitiesSubscription = _communityService.communitiesStream.listen((communities) {
        _communities = communities;

        // Apply search filter if there's an active search
        if (_searchQuery.isNotEmpty) {
          _searchResults = _communityService.searchCommunities(_searchQuery);
        }

        // Update selected community if it exists
        if (_selectedCommunity != null) {
          _selectedCommunity = _communities.firstWhere(
            (c) => c.id == _selectedCommunity!.id,
            orElse: () => _selectedCommunity!,
          );
        }

        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCommunity(String communityId) {
    _selectedCommunity = _communities.firstWhere(
      (c) => c.id == communityId,
      orElse: () => throw Exception('Community not found'),
    );
    
    // Select the default channel
    _selectedChannel = _selectedCommunity!.channels.firstWhere(
      (c) => c.isDefault,
      orElse: () => _selectedCommunity!.channels.first,
    );
    
    notifyListeners();
  }

  void selectChannel(String channelId) {
    if (_selectedCommunity == null) return;
    
    _selectedChannel = _selectedCommunity!.channels.firstWhere(
      (c) => c.id == channelId,
      orElse: () => throw Exception('Channel not found'),
    );
    
    notifyListeners();
  }

  void clearSelection() {
    _selectedCommunity = null;
    _selectedChannel = null;
    notifyListeners();
  }

  Future<Community> createCommunity({
    required String name,
    String? description,
    String? avatar,
    String? coverImage,
    CommunityPrivacy privacy = CommunityPrivacy.public,
    List<String>? tags,
    List<CommunityChannel>? channels,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final community = await _communityService.createCommunity(
        name: name,
        description: description,
        avatar: avatar ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=FF9800&color=fff',
        coverImage: coverImage,
        creatorId: currentUser.id,
        privacy: privacy,
        tags: tags,
        channels: channels,
      );

      _isLoading = false;
      notifyListeners();

      return community;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinCommunity(String communityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      await _communityService.joinCommunity(communityId, currentUser.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      await _communityService.leaveCommunity(communityId, currentUser.id);

      if (_selectedCommunity?.id == communityId) {
        clearSelection();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CommunityChannel> createChannel({
    required String name,
    String? description,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_selectedCommunity == null) {
        throw Exception('No community selected');
      }

      final channel = await _communityService.createChannel(
        communityId: _selectedCommunity!.id,
        name: name,
        description: description,
        isDefault: isDefault,
      );

      _isLoading = false;
      notifyListeners();

      return channel;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void searchCommunities(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _communityService.searchCommunities(query);
    }

    notifyListeners();
  }

  bool isMember(String communityId) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final community = _communities.firstWhere(
      (c) => c.id == communityId,
      orElse: () => throw Exception('Community not found'),
    );

    return community.memberIds.contains(currentUser.id);
  }

  CommunityRole? getUserRole(String communityId) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final community = _communities.firstWhere(
      (c) => c.id == communityId,
      orElse: () => throw Exception('Community not found'),
    );

    return community.memberRoles[currentUser.id];
  }

  @override
  void dispose() {
    _communitiesSubscription?.cancel();
    super.dispose();
  }
}
