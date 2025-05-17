import 'package:uuid/uuid.dart';

class TransactionMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final String? note;
  final TransactionStatus status;

  TransactionMessage({
    String? id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.currency = 'MC',
    DateTime? timestamp,
    this.note,
    this.status = TransactionStatus.pending,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();

  TransactionMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    double? amount,
    String? currency,
    DateTime? timestamp,
    String? note,
    TransactionStatus? status,
  }) {
    return TransactionMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'note': note,
      'status': status.index,
    };
  }

  factory TransactionMessage.fromJson(Map<String, dynamic> json) {
    return TransactionMessage(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      amount: json['amount'],
      currency: json['currency'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      note: json['note'],
      status: TransactionStatus.values[json['status']],
    );
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled
}
