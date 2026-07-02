class UserModel {
  final int? id;
  final String name;
  final String phone;
  final String pinHash;
  final String blockchainAddr; // base address (without slot)
  final String initials;
  final bool isMerchant;
  final bool isAgent;
  final bool isAdmin;
  final String kycStatus;   // lowercase: none | pending | approved | rejected
  final bool faceVerified;
  final String? kycDocType;
  final String? kycDocName;
  final bool biometricsEnabled;
  final bool twoFactorEnabled;
  final String language;
  final String themeMode;
  final String createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.pinHash,
    required this.blockchainAddr,
    required this.initials,
    this.isMerchant = false,
    this.isAgent = false,
    this.isAdmin = false,
    this.kycStatus = 'none',
    this.faceVerified = false,
    this.kycDocType,
    this.kycDocName,
    this.biometricsEnabled = true,
    this.twoFactorEnabled = false,
    this.language = 'fr',
    this.themeMode = 'dark',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'phone': phone,
    'pin_hash': pinHash,
    'blockchain_addr': blockchainAddr,
    'initials': initials,
    'is_merchant': isMerchant ? 1 : 0,
    'is_agent': isAgent ? 1 : 0,
    'is_admin': isAdmin ? 1 : 0,
    'kyc_status': kycStatus,
    'face_verified': faceVerified ? 1 : 0,
    'kyc_doc_type': kycDocType,
    'kyc_doc_name': kycDocName,
    'biometrics_enabled': biometricsEnabled ? 1 : 0,
    'two_factor_enabled': twoFactorEnabled ? 1 : 0,
    'language': language,
    'theme_mode': themeMode,
    'created_at': createdAt,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'] as int?,
    name: m['name'] as String? ?? 'Utilisateur',
    phone: m['phone'] as String? ?? '',
    pinHash: m['pin_hash'] as String? ?? '',
    blockchainAddr: m['blockchain_addr'] as String? ?? '',
    initials: m['initials'] as String? ?? '',
    isMerchant: (m['is_merchant'] as int? ?? 0) == 1,
    isAgent: (m['is_agent'] as int? ?? 0) == 1,
    isAdmin: (m['is_admin'] as int? ?? 0) == 1,
    kycStatus: (m['kyc_status'] as String? ?? 'none').toLowerCase(),
    faceVerified: (m['face_verified'] as int? ?? 0) == 1,
    kycDocType: m['kyc_doc_type'] as String?,
    kycDocName: m['kyc_doc_name'] as String?,
    biometricsEnabled: (m['biometrics_enabled'] as int? ?? 1) == 1,
    twoFactorEnabled: (m['two_factor_enabled'] as int? ?? 0) == 1,
    language: m['language'] as String? ?? 'fr',
    themeMode: m['theme_mode'] as String? ?? 'dark',
    createdAt: m['created_at'] as String? ?? DateTime.now().toIso8601String(),
  );

  factory UserModel.fromJson(Map<String, dynamic> m) => UserModel(
    id: m['id'] as int?,
    name: m['name'] as String? ?? 'Utilisateur',
    phone: m['phone'] as String? ?? '',
    pinHash: m['pinHash'] as String? ?? '',
    blockchainAddr: m['blockchainAddr'] as String? ?? '',
    initials: m['initials'] as String? ?? '',
    isMerchant: m['isMerchant'] as bool? ?? false,
    isAgent: m['isAgent'] as bool? ?? false,
    isAdmin: m['isAdmin'] as bool? ?? false,
    kycStatus: (m['kycStatus'] as String? ?? 'none').toLowerCase(),
    faceVerified: m['faceVerified'] as bool? ?? false,
    kycDocType: m['kycDocType'] as String?,
    kycDocName: m['kycDocName'] as String?,
    biometricsEnabled: m['biometricsEnabled'] as bool? ?? true,
    twoFactorEnabled: m['twoFactorEnabled'] as bool? ?? false,
    language: m['language'] as String? ?? 'fr',
    themeMode: m['themeMode'] as String? ?? 'dark',
    createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
  );

  UserModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? pinHash,
    String? blockchainAddr,
    String? initials,
    bool? isMerchant,
    bool? isAgent,
    bool? isAdmin,
    String? kycStatus,
    bool? faceVerified,
    String? kycDocType,
    String? kycDocName,
    bool? biometricsEnabled,
    bool? twoFactorEnabled,
    String? language,
    String? themeMode,
    String? createdAt,
  }) =>
    UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pinHash: pinHash ?? this.pinHash,
      blockchainAddr: blockchainAddr ?? this.blockchainAddr,
      initials: initials ?? this.initials,
      isMerchant: isMerchant ?? this.isMerchant,
      isAgent: isAgent ?? this.isAgent,
      isAdmin: isAdmin ?? this.isAdmin,
      kycStatus: kycStatus ?? this.kycStatus,
      faceVerified: faceVerified ?? this.faceVerified,
      kycDocType: kycDocType ?? this.kycDocType,
      kycDocName: kycDocName ?? this.kycDocName,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
    );
}
