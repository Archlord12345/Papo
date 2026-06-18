import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String asset;
  final String type; // 'send', 'receive', 'offline', 'merchant'
  final DateTime timestamp;
  String status; // 'completed', 'pending', 'failed'
  final String description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.asset,
    required this.type,
    required this.timestamp,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'asset': asset,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'description': description,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    title: map['title'],
    amount: (map['amount'] as num).toDouble(),
    asset: map['asset'],
    type: map['type'],
    timestamp: DateTime.parse(map['timestamp']),
    status: map['status'],
    description: map['description'],
  );
}

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type; // 'security', 'success', 'info'
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
    id: map['id'],
    title: map['title'],
    content: map['content'],
    type: map['type'],
    timestamp: DateTime.parse(map['timestamp']),
    isRead: map['isRead'] ?? false,
  );
}

class AppState extends ChangeNotifier {
  // Navigation
  String _currentScreen = "Splash";
  String get currentScreen => _currentScreen;
  
  List<String> recentlyVisited = ['Dashboard', 'Wallet', 'Circle', 'Developer'];

  void setScreen(String screenName) {
    _currentScreen = screenName;
    if (['Dashboard', 'Wallet', 'Circle', 'Developer'].contains(screenName)) {
      recentlyVisited.remove(screenName);
      recentlyVisited.insert(0, screenName);
      if (recentlyVisited.length > 4) {
        recentlyVisited.removeLast();
      }
    }
    notifyListeners();
  }

  // Language
  String language = 'fr';
  void changeLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  // Theme Mode
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // User Profile
  bool isLoggedIn = false;
  String userName = "";
  String userPhone = "";
  String walletAddress = "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";
  String avatarInitials = "";
  bool isMerchant = false;
  String? userPin;

  // Balances
  Map<String, double> balances = {
    'XOF': 0,
    'USD': 0,
    'PAPO': 0,
    'BTC': 0,
  };

  // Lists
  List<Transaction> transactions = [];
  List<Transaction> offlineQueue = [];
  List<NotificationModel> notifications = [];
  
  List<String> activeDevices = [
    "Tecno Camon 20 • Abidjan, CI (Actuel)",
  ];

  // KYC States
  String kycStatus = "none"; 
  String? uploadedDocType;
  String? uploadedDocName;
  bool isFaceVerified = false;

  // Security
  bool biometricsEnabled = true;
  bool twoFactorEnabled = false;

  final LocalStorageService _localStorageService = LocalStorageService();
  List<Map<String, dynamic>> pairedDevices = [];

  AppState() {
    _restoreLocalData();
  }

  Future<void> _restoreLocalData() async {
    final profile = await _localStorageService.loadUserProfile();
    if (profile != null) {
      userName = profile['name'] ?? "";
      userPhone = profile['phone'] ?? "";
      userPin = profile['pin'];
      walletAddress = profile['walletAddress'] ?? "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";
      avatarInitials = profile['initials'] ?? "";
      isLoggedIn = profile['isLoggedIn'] ?? false;
      kycStatus = profile['kycStatus'] ?? "none";
      isFaceVerified = profile['isFaceVerified'] ?? false;
    }

    balances = await _localStorageService.loadBalances();
    if (balances.isEmpty) {
      balances = {'XOF': 0, 'USD': 0, 'PAPO': 0, 'BTC': 0};
    }

    final txData = await _localStorageService.loadTransactions();
    transactions = txData.map((e) => Transaction.fromMap(e)).toList();

    pairedDevices = await _localStorageService.loadPairings();
    notifyListeners();
  }

  Future<void> _persistProfile() async {
    await _localStorageService.saveUserProfile({
      'name': userName,
      'phone': userPhone,
      'pin': userPin,
      'walletAddress': walletAddress,
      'initials': avatarInitials,
      'isLoggedIn': isLoggedIn,
      'kycStatus': kycStatus,
      'isFaceVerified': isFaceVerified,
    });
  }

  Future<void> _persistBalances() async {
    await _localStorageService.saveBalances(balances);
  }

  Future<void> _persistTransactions() async {
    final data = transactions.map((tx) => tx.toMap()).toList();
    await _localStorageService.saveTransactions(data);
  }

  // --- Auth Actions ---

  Future<bool> register(String name, String phone, String pin) async {
    userName = name;
    userPhone = phone;
    userPin = pin;
    
    final phoneHash = phone.hashCode.toRadixString(16).padLeft(8, '0');
    walletAddress = "0x${phoneHash}6EC7ab88b098defB751B7401B5f6d8976F".toUpperCase();
    
    // Generate initials safely
    if (name.isNotEmpty) {
      final names = name.trim().split(" ");
      avatarInitials = names
          .where((n) => n.isNotEmpty)
          .map((n) => n[0])
          .take(2)
          .join()
          .toUpperCase();
    } else {
      avatarInitials = "??";
    }
    isLoggedIn = true;
    
    // Initial gift
    balances['PAPO'] = 1000;
    balances['XOF'] = 5000;

    await _persistProfile();
    await _persistBalances();
    
    addNotification("Bienvenue !", "Merci d'avoir rejoint PAYPOINT. Vous avez reçu 1000 PAPO en bonus.", "success");
    notifyListeners();
    return true;
  }

  Future<bool> login(String phone, String pin) async {
    if (userPhone == phone && userPin == pin) {
      isLoggedIn = true;
      await _persistProfile();
      addNotification("Connexion", "Bon retour sur votre compte PAYPOINT.", "security");
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    isLoggedIn = false;
    await _persistProfile();
    setScreen("Login");
    notifyListeners();
  }

  // --- Wallet Actions (CRUD) ---

  // CREATE Transaction is handled by send/receive
  // READ is via the transactions list

  // UPDATE balance (Top up simulation)
  void topUp(double amount, String asset) {
    balances[asset] = (balances[asset] ?? 0) + amount;
    
    transactions.insert(0, Transaction(
      id: "DEP-${DateTime.now().millisecondsSinceEpoch}",
      title: "Dépôt $asset",
      amount: amount,
      asset: asset,
      type: "receive",
      timestamp: DateTime.now(),
      status: "completed",
      description: "Dépôt manuel pour simulation",
    ));

    _persistBalances();
    _persistTransactions();
    addNotification("Dépôt réussi", "Votre compte a été crédité de $amount $asset.", "success");
    notifyListeners();
  }

  // DELETE/Reset Wallet (for testing/real use case)
  Future<void> resetWallet() async {
    balances = {'XOF': 0, 'USD': 0, 'PAPO': 0, 'BTC': 0};
    transactions.clear();
    await _persistBalances();
    await _persistTransactions();
    notifyListeners();
  }

  // Send Money Action
  bool sendMoney(String recipient, double amount, String asset) {
    double currentBal = balances[asset] ?? 0;
    if (currentBal < amount) return false;

    balances[asset] = currentBal - amount;
    
    transactions.insert(
      0,
      Transaction(
        id: "TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
        title: "Transfert vers $recipient",
        amount: -amount,
        asset: asset,
        type: "send",
        timestamp: DateTime.now(),
        status: "completed",
        description: "Transfert immédiat initié depuis l'application",
      ),
    );

    _persistBalances();
    _persistTransactions();

    addNotification(
      "Transfert réussi",
      "Vous avez envoyé $amount $asset à $recipient avec succès.",
      "success"
    );

    notifyListeners();
    return true;
  }

  // Receive Money Action
  void receiveMoney(double amount, String asset) {
    double currentBal = balances[asset] ?? 0;
    balances[asset] = currentBal + amount;

    transactions.insert(
      0,
      Transaction(
        id: "TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
        title: "Reçu de fonds",
        amount: amount,
        asset: asset,
        type: "receive",
        timestamp: DateTime.now(),
        status: "completed",
        description: "Fonds reçus via code QR",
      ),
    );

    _persistBalances();
    _persistTransactions();

    addNotification(
      "Fonds reçus",
      "Vous avez reçu $amount $asset sur votre portefeuille.",
      "success"
    );

    notifyListeners();
  }

  // Offline Payment Queue Action
  void addOfflineTransaction(double amount, String recipient) {
    double currentBal = balances['XOF'] ?? 0;
    balances['XOF'] = currentBal - amount; // deduct locally

    Transaction offTx = Transaction(
      id: "OFF-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      title: "Paiement Offline vers $recipient",
      amount: -amount,
      asset: "XOF",
      type: "offline",
      timestamp: DateTime.now(),
      status: "pending",
      description: "Signé localement par Bluetooth/NFC (En attente de synchro)",
    );

    offlineQueue.insert(0, offTx);
    transactions.insert(0, offTx);

    addNotification(
      "Transaction Offline signée",
      "Paiement de $amount XOF vers $recipient signé localement. Synchronisation requise.",
      "info"
    );

    persistOfflineQueueSnapshot();
    notifyListeners();
  }

  // Sync Offline Queue
  void syncOfflineTransactions() {
    if (offlineQueue.isEmpty) return;

    for (var tx in offlineQueue) {
      // Find inside transaction list and update status
      int index = transactions.indexWhere((element) => element.id == tx.id);
      if (index != -1) {
        transactions[index].status = "completed";
      }
    }
    
    int count = offlineQueue.length;
    offlineQueue.clear();

    addNotification(
      "Synchronisation réussie",
      "Vos $count transactions hors ligne ont été ancrées sur la blockchain avec succès.",
      "success"
    );

    persistOfflineQueueSnapshot();
    notifyListeners();
  }

  // KYC Actions
  void uploadKYCDocument(String type, String name) {
    uploadedDocType = type;
    uploadedDocName = name;
    kycStatus = "pending";
    
    addNotification(
      "KYC Soumis",
      "Vos documents d'identité ($type) ont été soumis pour vérification.",
      "info"
    );
    notifyListeners();
  }

  void verifyFace() {
    isFaceVerified = true;
    notifyListeners();
  }

  void approveKYC() {
    kycStatus = "verified";
    addNotification(
      "Compte vérifié",
      "Félicitations, votre identité a été approuvée ! Limites de compte débloquées.",
      "success"
    );
    notifyListeners();
  }

  void rejectKYC() {
    kycStatus = "rejected";
    addNotification(
      "KYC Rejeté",
      "La vérification de votre identité a échoué. Veuillez soumettre une pièce valide.",
      "security"
    );
    notifyListeners();
  }

  void resetKYC() {
    kycStatus = "none";
    uploadedDocType = null;
    uploadedDocName = null;
    isFaceVerified = false;
    notifyListeners();
  }

  // Notifications helper
  void addNotification(String title, String content, String type) {
    notifications.insert(
      0,
      NotificationModel(
        id: "N-${DateTime.now().millisecondsSinceEpoch}",
        title: title,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void toggleBiometrics() {
    biometricsEnabled = !biometricsEnabled;
    notifyListeners();
  }

  void toggle2FA() {
    twoFactorEnabled = !twoFactorEnabled;
    notifyListeners();
  }

  void removeDevice(String device) {
    activeDevices.remove(device);
    addNotification(
      "Appareil révoqué",
      "La session sur $device a été clôturée avec succès.",
      "security"
    );
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> addPairedDevice({required String peerId, required String alias}) async {
    final exists = pairedDevices.any((d) => d['peerId'] == peerId);
    if (!exists) {
      pairedDevices.insert(0, {
        'peerId': peerId,
        'alias': alias,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _localStorageService.savePairings(pairedDevices);
      addNotification('Appareil appairé', 'Nouveau contact NFC enregistré: $alias', 'success');
      notifyListeners();
    }
  }

  Future<void> persistOfflineQueueSnapshot() async {
    final data = offlineQueue
        .map((tx) => tx.toMap())
        .toList();
    await _localStorageService.saveOfflineQueueBackup(data);
  }
}
