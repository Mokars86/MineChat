import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_models.dart';
import '../models/chat_models.dart';
import 'auth_service.dart';
import 'chat_service.dart';

class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final List<Community> _communities = [];
  final _communitiesController = StreamController<List<Community>>.broadcast();

  Stream<List<Community>> get communitiesStream => _communitiesController.stream;
  List<Community> get communities => _communities;

  // Initialize the community service
  Future<void> init() async {
    await _loadData();

    if (_communities.isEmpty) {
      await _loadDemoData();
    }

    _notifyListeners();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load communities
    final communitiesJson = prefs.getString('communities');
    if (communitiesJson != null) {
      final List<dynamic> communitiesData = jsonDecode(communitiesJson);
      _communities.clear();
      _communities.addAll(
        communitiesData.map((data) => Community.fromJson(data)).toList()
      );
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save communities
    final communitiesJson = jsonEncode(_communities.map((c) => c.toJson()).toList());
    await prefs.setString('communities', communitiesJson);
  }

  // Load demo data
  Future<void> _loadDemoData() async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    // Create demo communities
    final List<Community> demoCommunities = [
      Community(
        name: 'Crypto Enthusiasts',
        description: 'A community for crypto enthusiasts to discuss the latest trends and technologies.',
        avatar: 'https://ui-avatars.com/api/?name=Crypto+Enthusiasts&background=FF9800&color=fff',
        coverImage: 'https://images.unsplash.com/photo-1621761191319-c6fb62004040?q=80&w=1000',
        creatorId: currentUser.id,
        tags: ['crypto', 'blockchain', 'mining'],
        channels: [
          CommunityChannel(
            name: 'general',
            description: 'General discussion about crypto',
            isDefault: true,
          ),
          CommunityChannel(
            name: 'mining',
            description: 'Mining tips and tricks',
          ),
          CommunityChannel(
            name: 'trading',
            description: 'Trading strategies and market analysis',
          ),
        ],
      ),
      Community(
        name: 'Blockchain Developers',
        description: 'A community for blockchain developers to share knowledge and collaborate on projects.',
        avatar: 'https://ui-avatars.com/api/?name=Blockchain+Developers&background=4CAF50&color=fff',
        coverImage: 'https://images.unsplash.com/photo-1639322537228-f710d846310a?q=80&w=1000',
        creatorId: currentUser.id,
        tags: ['blockchain', 'development', 'coding'],
        channels: [
          CommunityChannel(
            name: 'general',
            description: 'General discussion about blockchain development',
            isDefault: true,
          ),
          CommunityChannel(
            name: 'smart-contracts',
            description: 'Smart contract development',
          ),
          CommunityChannel(
            name: 'jobs',
            description: 'Job opportunities in blockchain',
          ),
        ],
      ),
    ];

    _communities.addAll(demoCommunities);
    await _saveData();
  }

  // Create a new community
  Future<Community> createCommunity({
    required String name,
    String? description,
    String? avatar,
    String? coverImage,
    required String creatorId,
    CommunityPrivacy privacy = CommunityPrivacy.public,
    List<String>? tags,
    List<CommunityChannel>? channels,
  }) async {
    final community = Community(
      name: name,
      description: description,
      avatar: avatar,
      coverImage: coverImage,
      creatorId: creatorId,
      privacy: privacy,
      tags: tags,
      channels: channels,
    );

    _communities.add(community);
    await _saveData();
    _notifyListeners();

    return community;
  }

  // Join a community
  Future<void> joinCommunity(String communityId, String userId) async {
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index == -1) {
      throw Exception('Community not found');
    }

    final community = _communities[index];
    if (community.memberIds.contains(userId)) {
      return; // Already a member
    }

    final updatedMemberIds = List<String>.from(community.memberIds)..add(userId);
    final updatedMemberRoles = Map<String, CommunityRole>.from(community.memberRoles)
      ..putIfAbsent(userId, () => CommunityRole.member);

    _communities[index] = community.copyWith(
      memberIds: updatedMemberIds,
      memberRoles: updatedMemberRoles,
      lastActivityAt: DateTime.now(),
    );

    await _saveData();
    _notifyListeners();
  }

  // Leave a community
  Future<void> leaveCommunity(String communityId, String userId) async {
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index == -1) {
      throw Exception('Community not found');
    }

    final community = _communities[index];
    if (!community.memberIds.contains(userId)) {
      return; // Not a member
    }

    // Creator cannot leave the community
    if (community.creatorId == userId) {
      throw Exception('Creator cannot leave the community');
    }

    final updatedMemberIds = List<String>.from(community.memberIds)..remove(userId);
    final updatedMemberRoles = Map<String, CommunityRole>.from(community.memberRoles)
      ..remove(userId);
    final updatedAdminIds = List<String>.from(community.adminIds)..remove(userId);
    final updatedModeratorIds = List<String>.from(community.moderatorIds)..remove(userId);

    _communities[index] = community.copyWith(
      memberIds: updatedMemberIds,
      memberRoles: updatedMemberRoles,
      adminIds: updatedAdminIds,
      moderatorIds: updatedModeratorIds,
      lastActivityAt: DateTime.now(),
    );

    await _saveData();
    _notifyListeners();
  }

  // Create a new channel in a community
  Future<CommunityChannel> createChannel({
    required String communityId,
    required String name,
    String? description,
    bool isDefault = false,
  }) async {
    final chatService = ChatService();
    final index = _communities.indexWhere((c) => c.id == communityId);
    if (index == -1) {
      throw Exception('Community not found');
    }

    final community = _communities[index];
    
    // Create a conversation for this channel
    final conversation = await chatService.createConversation(
      name: '$name (${community.name})',
      avatar: community.avatar,
      participantIds: community.memberIds,
      participantNames: {
        for (var memberId in community.memberIds)
          memberId: 'Member', // This would need to be replaced with actual names
      },
      isGroup: true,
    );

    final channel = CommunityChannel(
      name: name,
      description: description,
      isDefault: isDefault,
      conversationId: conversation.id,
    );

    final updatedChannels = List<CommunityChannel>.from(community.channels)..add(channel);
    _communities[index] = community.copyWith(
      channels: updatedChannels,
      lastActivityAt: DateTime.now(),
    );

    await _saveData();
    _notifyListeners();

    return channel;
  }

  // Search communities
  List<Community> searchCommunities(String query) {
    if (query.isEmpty) return _communities;

    final lowercaseQuery = query.toLowerCase();
    return _communities.where((community) {
      return community.name.toLowerCase().contains(lowercaseQuery) ||
             (community.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             community.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Notify listeners
  void _notifyListeners() {
    _communitiesController.add(_communities);
  }
}
