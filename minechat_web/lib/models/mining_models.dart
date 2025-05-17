import 'package:uuid/uuid.dart';

enum MiningStatus { idle, mining, completed, claimed }

class MiningRate {
  final int level;
  final String name;
  final double hashRate;
  final double price;
  final String description;

  const MiningRate({
    required this.level,
    required this.name,
    required this.hashRate,
    required this.price,
    required this.description,
  });

  static const List<MiningRate> rates = [
    MiningRate(
      level: 1,
      name: 'Basic',
      hashRate: 10.0,
      price: 0.0,
      description: 'Basic mining rate with 10 MH/s',
    ),
    MiningRate(
      level: 2,
      name: 'Standard',
      hashRate: 25.0,
      price: 50.0,
      description: 'Standard mining rate with 25 MH/s',
    ),
    MiningRate(
      level: 3,
      name: 'Advanced',
      hashRate: 50.0,
      price: 100.0,
      description: 'Advanced mining rate with 50 MH/s',
    ),
    MiningRate(
      level: 4,
      name: 'Professional',
      hashRate: 100.0,
      price: 200.0,
      description: 'Professional mining rate with 100 MH/s',
    ),
    MiningRate(
      level: 5,
      name: 'Expert',
      hashRate: 200.0,
      price: 500.0,
      description: 'Expert mining rate with 200 MH/s',
    ),
  ];

  static MiningRate getByLevel(int level) {
    return rates.firstWhere(
      (rate) => rate.level == level,
      orElse: () => rates.first,
    );
  }
}

class MiningSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final MiningStatus status;
  final double hashRate;
  final double estimatedReward;
  final double? actualReward;
  final String userId;
  final int miningRateLevel;

  MiningSession({
    String? id,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.hashRate,
    required this.estimatedReward,
    this.actualReward,
    required this.userId,
    this.miningRateLevel = 1,
  }) : this.id = id ?? const Uuid().v4();

  MiningSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    MiningStatus? status,
    double? hashRate,
    double? estimatedReward,
    double? actualReward,
    String? userId,
    int? miningRateLevel,
  }) {
    return MiningSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      hashRate: hashRate ?? this.hashRate,
      estimatedReward: estimatedReward ?? this.estimatedReward,
      actualReward: actualReward ?? this.actualReward,
      userId: userId ?? this.userId,
      miningRateLevel: miningRateLevel ?? this.miningRateLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'status': status.index,
      'hashRate': hashRate,
      'estimatedReward': estimatedReward,
      'actualReward': actualReward,
      'userId': userId,
      'miningRateLevel': miningRateLevel,
    };
  }

  factory MiningSession.fromJson(Map<String, dynamic> json) {
    return MiningSession(
      id: json['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      status: MiningStatus.values[json['status']],
      hashRate: json['hashRate'],
      estimatedReward: json['estimatedReward'],
      actualReward: json['actualReward'],
      userId: json['userId'],
      miningRateLevel: json['miningRateLevel'] ?? 1,
    );
  }

  MiningRate get miningRate => MiningRate.getByLevel(miningRateLevel);

  // Calculate the remaining time in seconds
  int get remainingTimeInSeconds {
    if (status != MiningStatus.mining) return 0;

    final miningDuration = const Duration(hours: 24);
    final endDateTime = startTime.add(miningDuration);
    final now = DateTime.now();

    if (now.isAfter(endDateTime)) return 0;

    return endDateTime.difference(now).inSeconds;
  }

  // Calculate the progress percentage (0-100)
  double get progressPercentage {
    if (status == MiningStatus.idle) return 0;
    if (status == MiningStatus.completed || status == MiningStatus.claimed) return 100;

    final miningDuration = const Duration(hours: 24).inSeconds;
    final elapsedTime = DateTime.now().difference(startTime).inSeconds;

    if (elapsedTime >= miningDuration) return 100;

    return (elapsedTime / miningDuration) * 100;
  }

  // Format the remaining time as a string (HH:MM:SS)
  String get remainingTimeFormatted {
    final seconds = remainingTimeInSeconds;

    if (seconds <= 0) return '00:00:00';

    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Check if mining is complete
  bool get isMiningComplete {
    if (status == MiningStatus.completed || status == MiningStatus.claimed) return true;
    if (status != MiningStatus.mining) return false;

    final miningDuration = const Duration(hours: 24);
    final endDateTime = startTime.add(miningDuration);

    return DateTime.now().isAfter(endDateTime);
  }
}

class WalletTransaction {
  final String id;
  final DateTime timestamp;
  final double amount;
  final String description;
  final String userId;
  final String? miningSessionId;
  final bool isDeposit;

  WalletTransaction({
    String? id,
    required this.timestamp,
    required this.amount,
    required this.description,
    required this.userId,
    this.miningSessionId,
    required this.isDeposit,
  }) : this.id = id ?? const Uuid().v4();

  WalletTransaction copyWith({
    String? id,
    DateTime? timestamp,
    double? amount,
    String? description,
    String? userId,
    String? miningSessionId,
    bool? isDeposit,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      miningSessionId: miningSessionId ?? this.miningSessionId,
      isDeposit: isDeposit ?? this.isDeposit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'amount': amount,
      'description': description,
      'userId': userId,
      'miningSessionId': miningSessionId,
      'isDeposit': isDeposit,
    };
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      amount: json['amount'],
      description: json['description'],
      userId: json['userId'],
      miningSessionId: json['miningSessionId'],
      isDeposit: json['isDeposit'],
    );
  }
}
