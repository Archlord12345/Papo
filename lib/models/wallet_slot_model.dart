/// Un wallet PAPO = un seul solde XOF + un appareil physique dédié.
/// Format ID : PAPO-{BLOCKCHAIN_ADDR}-{SLOT}  (slot 0-9)
class WalletSlotModel {
  final int? id;
  final int userId;
  final int slot;          // 0..9
  final String walletId;   // PAPO-{addr}-{slot}
  String name;             // label choisi par l'utilisateur
  final String deviceName; // appareil physique associé (devices_catalog)
  bool isActive;
  final String createdAt;
  double balance;          // UNIQUE balance XOF

  WalletSlotModel({
    this.id,
    required this.userId,
    required this.slot,
    required this.walletId,
    required this.name,
    required this.deviceName,
    this.isActive = false,
    required this.createdAt,
    this.balance = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'slot': slot,
    'wallet_id': walletId,
    'name': name,
    'device_name': deviceName,
    'is_active': isActive ? 1 : 0,
    'balance': balance,
    'created_at': createdAt,
  };

  factory WalletSlotModel.fromMap(Map<String, dynamic> m) => WalletSlotModel(
    id: m['id'] as int?,
    userId: m['user_id'] as int,
    slot: m['slot'] as int,
    walletId: m['wallet_id'] as String,
    name: m['name'] as String? ?? 'Wallet',
    deviceName: m['device_name'] as String? ?? 'Inconnu',
    isActive: (m['is_active'] as int? ?? 0) == 1,
    createdAt: m['created_at'] as String,
    balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
  );

  WalletSlotModel copyWith({
    int? id,
    String? name,
    String? deviceName,
    bool? isActive,
    double? balance,
  }) =>
    WalletSlotModel(
      id: id ?? this.id,
      userId: userId,
      slot: slot,
      walletId: walletId,
      name: name ?? this.name,
      deviceName: deviceName ?? this.deviceName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      balance: balance ?? this.balance,
    );
}
