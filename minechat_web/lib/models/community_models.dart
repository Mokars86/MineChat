import 'package:uuid/uuid.dart';

enum CommunityPrivacy { public, private }
enum CommunityRole { admin, moderator, member }

class Community {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final String? coverImage;
  final String creatorId;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final List<String> memberIds;
  final Map<String, CommunityRole> memberRoles;
  final CommunityPrivacy privacy;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final List<CommunityChannel> channels;

  Community({
    String? id,
    required this.name,
    this.description,
    this.avatar,
    this.coverImage,
    required this.creatorId,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? memberIds,
    Map<String, CommunityRole>? memberRoles,
    this.privacy = CommunityPrivacy.public,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    List<String>? tags,
    this.metadata,
    List<CommunityChannel>? channels,
  }) :
    this.id = id ?? const Uuid().v4(),
    this.adminIds = adminIds ?? [creatorId],
    this.moderatorIds = moderatorIds ?? [],
    this.memberIds = memberIds ?? [creatorId],
    this.memberRoles = memberRoles ?? {creatorId: CommunityRole.admin},
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastActivityAt = lastActivityAt ?? DateTime.now(),
    this.tags = tags ?? [],
    this.channels = channels ?? [
      CommunityChannel(
        name: 'general',
        description: 'General discussion',
        isDefault: true,
      )
    ];

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    String? coverImage,
    String? creatorId,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? memberIds,
    Map<String, CommunityRole>? memberRoles,
    CommunityPrivacy? privacy,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<CommunityChannel>? channels,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      creatorId: creatorId ?? this.creatorId,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberIds: memberIds ?? this.memberIds,
      memberRoles: memberRoles ?? this.memberRoles,
      privacy: privacy ?? this.privacy,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      channels: channels ?? this.channels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'coverImage': coverImage,
      'creatorId': creatorId,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'memberIds': memberIds,
      'memberRoles': memberRoles.map((key, value) => MapEntry(key, value.index)),
      'privacy': privacy.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActivityAt': lastActivityAt.millisecondsSinceEpoch,
      'tags': tags,
      'metadata': metadata,
      'channels': channels.map((channel) => channel.toJson()).toList(),
    };
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatar: json['avatar'],
      coverImage: json['coverImage'],
      creatorId: json['creatorId'],
      adminIds: List<String>.from(json['adminIds']),
      moderatorIds: List<String>.from(json['moderatorIds']),
      memberIds: List<String>.from(json['memberIds']),
      memberRoles: (json['memberRoles'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, CommunityRole.values[value as int])
      ),
      privacy: CommunityPrivacy.values[json['privacy']],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastActivityAt: DateTime.fromMillisecondsSinceEpoch(json['lastActivityAt']),
      tags: List<String>.from(json['tags']),
      metadata: json['metadata'],
      channels: (json['channels'] as List)
          .map((channelJson) => CommunityChannel.fromJson(channelJson))
          .toList(),
    );
  }
}

class CommunityChannel {
  final String id;
  final String name;
  final String? description;
  final bool isDefault;
  final DateTime createdAt;
  final String? conversationId; // Link to the chat conversation

  CommunityChannel({
    String? id,
    required this.name,
    this.description,
    this.isDefault = false,
    DateTime? createdAt,
    this.conversationId,
  }) :
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  CommunityChannel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    String? conversationId,
  }) {
    return CommunityChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'conversationId': conversationId,
    };
  }

  factory CommunityChannel.fromJson(Map<String, dynamic> json) {
    return CommunityChannel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      conversationId: json['conversationId'],
    );
  }
}
