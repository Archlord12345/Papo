/// Un wallet PAPO = un seul solde XOF + un appareil physique dédié.
/// Format ID : PAPO-{BLOCKCHAIN_ADDR}-{SLOT}  (slot 0-9)
class WalletSlotModel {
  final int? id;
  final int? remoteId;    // ID dans la base de données backend
  final int userId;
  final int slot;          // 0..9
  final String walletId;   // PAPO-{addr}-{slot}
  String name;             // label choisi par l'utilisateur
  final String deviceName; // appareil physique associé (devices_catalog)
  final String asset;      // Devise du wallet (XOF, USD, PAPO, BTC)
  bool isActive;
  final String createdAt;
  double balance;          // UNIQUE balance dans la devise choisie

  WalletSlotModel({
    this.id,
    this.remoteId,
    required this.userId,
    required this.slot,
    required this.walletId,
    required this.name,
    required this.deviceName,
    required this.asset,
    this.isActive = false,
    required this.createdAt,
    this.balance = 0,
  });

  double get xofBalance => asset == 'XOF' ? balance : 0;

  Map<String, double> get balances => {
    asset: balance,
  };

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'remote_id': remoteId,
    'user_id': userId,
    'slot': slot,
    'wallet_id': walletId,
    'name': name,
    'device_name': deviceName,
    'asset': asset,
    'is_active': isActive ? 1 : 0,
    'balance': balance,
    'created_at': createdAt,
  };

  factory WalletSlotModel.fromMap(Map<String, dynamic> m) => WalletSlotModel(
    id: m['id'] as int?,
    remoteId: m['remote_id'] as int?,
    userId: m['user_id'] as int? ?? 0,
    slot: m['slot'] as int? ?? 0,
    walletId: m['wallet_id'] as String? ?? '',
    name: m['name'] as String? ?? 'Wallet',
    deviceName: m['device_name'] as String? ?? 'Inconnu',
    asset: m['asset'] as String? ?? 'XOF',
    isActive: (m['is_active'] as int? ?? 0) == 1,
    createdAt: m['created_at'] as String? ?? DateTime.now().toIso8601String(),
    balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
  );

  factory WalletSlotModel.fromJson(Map<String, dynamic> m) => WalletSlotModel(
    id: m['id'] as int?,
    remoteId: m['id'] as int?,
    userId: m['userId'] as int? ?? 0,
    slot: m['slot'] as int? ?? 0,
    walletId: m['walletId'] as String? ?? '',
    name: m['name'] as String? ?? 'Wallet',
    deviceName: m['deviceName'] as String? ?? 'Inconnu',
    asset: m['asset'] as String? ?? 'XOF',
    isActive: m['isActive'] as bool? ?? false,
    createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
  );

  WalletSlotModel copyWith({
    int? id,
    int? remoteId,
    String? name,
    String? deviceName,
    String? asset,
    bool? isActive,
    double? balance,
  }) =>
    WalletSlotModel(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      userId: userId,
      slot: slot,
      walletId: walletId,
      name: name ?? this.name,
      deviceName: deviceName ?? this.deviceName,
      asset: asset ?? this.asset,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      balance: balance ?? this.balance,
    );
}
