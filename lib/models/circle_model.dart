class CircleModel {
  final int? id;
  final int userId;
  String name;
  String description;
  double target;
  double collected;
  double contribution;
  String turnMonth;
  String frequency;
  final String createdAt;
  List<CircleMember> members;

  CircleModel({
    this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.target,
    this.collected = 0,
    this.contribution = 100000,
    this.turnMonth = '',
    this.frequency = 'monthly',
    required this.createdAt,
    this.members = const [],
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'target': target,
    'collected': collected,
    'contribution': contribution,
    'turn_month': turnMonth,
    'frequency': frequency,
    'created_at': createdAt,
  };

  factory CircleModel.fromMap(Map<String, dynamic> m) => CircleModel(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    target: (m['target'] as num).toDouble(),
    collected: (m['collected'] as num).toDouble(),
    contribution: (m['contribution'] as num?)?.toDouble() ?? 100000,
    turnMonth: m['turn_month'] as String? ?? '',
    frequency: m['frequency'] as String? ?? 'monthly',
    createdAt: m['created_at'] as String,
  );

  double get progress => target > 0 ? (collected / target).clamp(0.0, 1.0) : 0;
  int get paidCount => members.where((m) => m.paid).length;
}

class CircleMember {
  final int? id;
  final int circleId;
  final String name;
  final String phone;
  final String walletId;
  bool paid;
  final String? paidDate;

  CircleMember({
    this.id,
    required this.circleId,
    required this.name,
    this.phone = '',
    this.walletId = '',
    this.paid = false,
    this.paidDate,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'circle_id': circleId,
    'name': name,
    'phone': phone,
    'wallet_id': walletId,
    'paid': paid ? 1 : 0,
    'paid_date': paidDate,
  };

  factory CircleMember.fromMap(Map<String, dynamic> m) => CircleMember(
    id: m['id'] as int?,
    circleId: m['circle_id'] as int,
    name: m['name'] as String,
    phone: m['phone'] as String? ?? '',
    walletId: m['wallet_id'] as String? ?? '',
    paid: (m['paid'] as int? ?? 0) == 1,
    paidDate: m['paid_date'] as String?,
  );
}
