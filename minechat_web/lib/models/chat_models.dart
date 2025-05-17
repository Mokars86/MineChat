import 'package:uuid/uuid.dart';

enum MessageStatus { sending, sent, delivered, read }
enum MessageType { text, image, video, audio, document, location, contact, transaction }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String conversationId;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;
  final List<String>? reactions;

  ChatMessage({
    String? id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.conversationId,
    required this.content,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    this.isDeleted = false,
    this.metadata,
    this.reactions,
  }) :
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? conversationId,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
    List<String>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'conversationId': conversationId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.index,
      'type': type.index,
      'isDeleted': isDeleted,
      'metadata': metadata,
      'reactions': reactions,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      conversationId: json['conversationId'],
      content: json['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values[json['status']],
      type: MessageType.values[json['type']],
      isDeleted: json['isDeleted'] ?? false,
      metadata: json['metadata'],
      reactions: json['reactions'] != null
          ? List<String>.from(json['reactions'])
          : null,
    );
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String? avatar;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final bool isGroup;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final Map<String, dynamic>? metadata;

  ChatConversation({
    String? id,
    required this.name,
    this.avatar,
    required this.participantIds,
    required this.participantNames,
    this.participantAvatars = const {},
    DateTime? createdAt,
    DateTime? lastMessageTime,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.isGroup = false,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.metadata,
  }) :
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastMessageTime = lastMessageTime ?? DateTime.now();

  ChatConversation copyWith({
    String? id,
    String? name,
    String? avatar,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    DateTime? createdAt,
    DateTime? lastMessageTime,
    String? lastMessageContent,
    String? lastMessageSenderId,
    bool? isGroup,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    Map<String, dynamic>? metadata,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      isGroup: isGroup ?? this.isGroup,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'isGroup': isGroup,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'metadata': metadata,
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      participantIds: List<String>.from(json['participantIds']),
      participantNames: Map<String, String>.from(json['participantNames']),
      participantAvatars: json['participantAvatars'] != null
          ? Map<String, String?>.from(json['participantAvatars'])
          : {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime']),
      lastMessageContent: json['lastMessageContent'],
      lastMessageSenderId: json['lastMessageSenderId'],
      isGroup: json['isGroup'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isPinned: json['isPinned'] ?? false,
      metadata: json['metadata'],
    );
  }
}
