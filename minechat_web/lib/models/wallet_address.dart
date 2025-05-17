import 'package:uuid/uuid.dart';

class WalletAddress {
  final String address;
  final String userId;
  final String label;
  final DateTime createdAt;
  final bool isDefault;

  WalletAddress({
    String? address,
    required this.userId,
    this.label = 'My Wallet',
    DateTime? createdAt,
    this.isDefault = true,
  }) : 
    this.address = address ?? _generateWalletAddress(),
    this.createdAt = createdAt ?? DateTime.now();

  WalletAddress copyWith({
    String? address,
    String? userId,
    String? label,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return WalletAddress(
      address: address ?? this.address,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'userId': userId,
      'label': label,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isDefault': isDefault,
    };
  }

  factory WalletAddress.fromJson(Map<String, dynamic> json) {
    return WalletAddress(
      address: json['address'],
      userId: json['userId'],
      label: json['label'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      isDefault: json['isDefault'],
    );
  }

  // Generate a random wallet address
  static String _generateWalletAddress() {
    final uuid = const Uuid().v4().replaceAll('-', '');
    return 'MC${uuid.substring(0, 32)}';
  }

  // Format the address for display (with spaces)
  String get formattedAddress {
    final addr = address;
    if (addr.length < 10) return addr;
    
    // Format as MC XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX
    final prefix = addr.substring(0, 2); // MC
    final rest = addr.substring(2);
    
    final buffer = StringBuffer(prefix);
    for (int i = 0; i < rest.length; i += 4) {
      buffer.write(' ');
      buffer.write(rest.substring(i, i + 4 < rest.length ? i + 4 : rest.length));
    }
    
    return buffer.toString();
  }

  // Get a shortened version of the address for display
  String get shortAddress {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }
}

class ExternalTransaction {
  final String id;
  final String walletAddress;
  final String? externalAddress;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final bool isOutgoing;
  final TransactionStatus status;
  final String userId;
  final String? note;

  ExternalTransaction({
    String? id,
    required this.walletAddress,
    this.externalAddress,
    required this.amount,
    this.currency = 'MC',
    DateTime? timestamp,
    required this.isOutgoing,
    this.status = TransactionStatus.pending,
    required this.userId,
    this.note,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.timestamp = timestamp ?? DateTime.now();

  ExternalTransaction copyWith({
    String? id,
    String? walletAddress,
    String? externalAddress,
    double? amount,
    String? currency,
    DateTime? timestamp,
    bool? isOutgoing,
    TransactionStatus? status,
    String? userId,
    String? note,
  }) {
    return ExternalTransaction(
      id: id ?? this.id,
      walletAddress: walletAddress ?? this.walletAddress,
      externalAddress: externalAddress ?? this.externalAddress,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletAddress': walletAddress,
      'externalAddress': externalAddress,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isOutgoing': isOutgoing,
      'status': status.index,
      'userId': userId,
      'note': note,
    };
  }

  factory ExternalTransaction.fromJson(Map<String, dynamic> json) {
    return ExternalTransaction(
      id: json['id'],
      walletAddress: json['walletAddress'],
      externalAddress: json['externalAddress'],
      amount: json['amount'],
      currency: json['currency'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isOutgoing: json['isOutgoing'],
      status: TransactionStatus.values[json['status']],
      userId: json['userId'],
      note: json['note'],
    );
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled
}
