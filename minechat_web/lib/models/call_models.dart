import 'package:uuid/uuid.dart';

enum CallType { audio, video }
enum CallStatus { ringing, ongoing, ended, missed, rejected, busy }

class Call {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool isOutgoing;
  final String? conversationId;

  Call({
    String? id,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.type,
    this.status = CallStatus.ringing,
    DateTime? startTime,
    this.endTime,
    this.duration,
    required this.isOutgoing,
    this.conversationId,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.startTime = startTime ?? DateTime.now();

  Call copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    CallType? type,
    CallStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    bool? isOutgoing,
    String? conversationId,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'type': type.index,
      'status': status.index,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'duration': duration?.inSeconds,
      'isOutgoing': isOutgoing,
      'conversationId': conversationId,
    };
  }

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      callerAvatar: json['callerAvatar'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      receiverAvatar: json['receiverAvatar'],
      type: CallType.values[json['type']],
      status: CallStatus.values[json['status']],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: json['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime']) 
          : null,
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration']) 
          : null,
      isOutgoing: json['isOutgoing'],
      conversationId: json['conversationId'],
    );
  }

  String get statusText {
    switch (status) {
      case CallStatus.ringing:
        return isOutgoing ? 'Calling...' : 'Incoming call';
      case CallStatus.ongoing:
        return 'Ongoing';
      case CallStatus.ended:
        return 'Ended';
      case CallStatus.missed:
        return isOutgoing ? 'No answer' : 'Missed';
      case CallStatus.rejected:
        return isOutgoing ? 'Declined' : 'Rejected';
      case CallStatus.busy:
        return 'Busy';
    }
  }

  String get durationText {
    if (duration == null) return '';
    
    final minutes = duration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    if (duration!.inHours > 0) {
      final hours = duration!.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    
    return '$minutes:$seconds';
  }
}
