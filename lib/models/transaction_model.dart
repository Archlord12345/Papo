class TransactionModel {
  final String id;
  final int userId;
  final int slotId;
  final String title;
  final double amount;
  final String asset; // toujours 'XOF'
  final String type;  // send | receive | offline | bill | deposit | tontine
  String status;      // completed | pending | failed
  final String description;
  final String recipient;
  final String method; // standard | qr | nfc | bluetooth | offline
  final bool isOffline;
  final String createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.title,
    required this.amount,
    this.asset = 'XOF',
    required this.type,
    this.status = 'completed',
    this.description = '',
    this.recipient = '',
    this.method = 'standard',
    this.isOffline = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'slot_id': slotId,
    'title': title,
    'amount': amount,
    'type': type,
    'status': status,
    'description': description,
    'recipient': recipient,
    'method': method,
    'is_offline': isOffline ? 1 : 0,
    'created_at': createdAt,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
    id: m['id'] as String,
    userId: m['user_id'] as int? ?? 0,
    slotId: m['slot_id'] as int? ?? 0,
    title: m['title'] as String? ?? 'Transaction',
    amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
    asset: 'XOF',
    type: m['type'] as String? ?? 'TRANSFER',
    status: m['status'] as String? ?? 'COMPLETED',
    description: m['description'] as String? ?? '',
    recipient: m['recipient'] as String? ?? '',
    method: m['method'] as String? ?? 'STANDARD',
    isOffline: (m['is_offline'] as int? ?? 0) == 1,
    createdAt: m['created_at'] as String? ?? DateTime.now().toIso8601String(),
  );

  factory TransactionModel.fromJson(Map<String, dynamic> m) => TransactionModel(
    id: m['id'] as String,
    userId: m['userId'] as int? ?? 0,
    slotId: m['walletId'] as int? ?? 0,
    title: m['title'] as String? ?? 'Transaction',
    amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
    asset: m['currency'] as String? ?? 'XOF',
    type: m['type'] as String? ?? 'TRANSFER',
    status: m['status'] as String? ?? 'COMPLETED',
    description: m['description'] as String? ?? '',
    recipient: m['recipientPhone'] as String? ?? '',
    method: m['method'] as String? ?? 'STANDARD',
    isOffline: m['isOffline'] as bool? ?? false,
    createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
  );

  DateTime get timestamp => DateTime.parse(createdAt);
}
