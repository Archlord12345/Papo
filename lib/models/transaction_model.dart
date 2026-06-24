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
    userId: m['user_id'] as int,
    slotId: m['slot_id'] as int? ?? 0,
    title: m['title'] as String,
    amount: (m['amount'] as num).toDouble(),
    asset: 'XOF',
    type: m['type'] as String,
    status: m['status'] as String? ?? 'completed',
    description: m['description'] as String? ?? '',
    recipient: m['recipient'] as String? ?? '',
    method: m['method'] as String? ?? 'standard',
    isOffline: (m['is_offline'] as int? ?? 0) == 1,
    createdAt: m['created_at'] as String,
  );

  DateTime get timestamp => DateTime.parse(createdAt);
}
