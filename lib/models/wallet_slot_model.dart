/// Represents one of the 10 wallet slots (0-9) a user can own.
/// Wallet ID format: PAPO-{BLOCKCHAIN_ADDR}-{SLOT}
class WalletSlotModel {
  final int? id;
  final int userId;
  final int slot;          // 0-9
  final String walletId;   // PAPO-{addr}-{slot}
  final String name;       // user-chosen label
  final String deviceName; // from devices_catalog
  bool isActive;
  final String createdAt;
  Map<String, double> balances; // asset -> amount

  WalletSlotModel({
    this.id,
    required this.userId,
    required this.slot,
    required this.walletId,
    required this.name,
    required this.deviceName,
    this.isActive = false,
    required this.createdAt,
    this.balances = const {},
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'slot': slot,
    'wallet_id': walletId,
    'name': name,
    'device_name': deviceName,
    'is_active': isActive ? 1 : 0,
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
  );

  double get xofBalance => balances['XOF'] ?? 0;
  double totalBalance(String asset) => balances[asset] ?? 0;

  WalletSlotModel copyWith({
    int? id,
    String? name,
    String? deviceName,
    bool? isActive,
    Map<String, double>? balances,
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
      balances: balances ?? this.balances,
    );
}
