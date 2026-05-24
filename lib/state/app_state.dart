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
  String userName = "Mamadou Diallo";
  String userPhone = "+225 07 08 09 10 11";
  String walletAddress = "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";
  String avatarInitials = "MD";
  bool isMerchant = false;

  // Balances
  final Map<String, double> balances = {
    'XOF': 458500,
    'USD': 750,
    'PAPO': 2500,
    'BTC': 0.015,
  };

  // Lists
  List<Transaction> transactions = [];
  List<Transaction> offlineQueue = [];
  List<NotificationModel> notifications = [];
  
  List<String> activeDevices = [
    "Tecno Camon 20 • Abidjan, CI (Actuel)",
    "iPhone 15 Pro • Dakar, SN",
    "MacBook Pro • Abidjan, CI",
  ];

  // KYC States
  String kycStatus = "none"; // 'none', 'pending', 'verified', 'rejected'
  String? uploadedDocType; // 'CNI' or 'Passport'
  String? uploadedDocName;
  bool isFaceVerified = false;

  // Security
  bool biometricsEnabled = true;
  bool twoFactorEnabled = false;

  final LocalStorageService _localStorageService = LocalStorageService();
  List<Map<String, dynamic>> pairedDevices = [];

  AppState() {
    _initMockData();
    _restoreLocalData();
  }


  Future<void> _restoreLocalData() async {
    pairedDevices = await _localStorageService.loadPairings();
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
        .map((tx) => {
              'id': tx.id,
              'title': tx.title,
              'amount': tx.amount,
              'asset': tx.asset,
              'type': tx.type,
              'timestamp': tx.timestamp.toIso8601String(),
              'status': tx.status,
              'description': tx.description,
            })
        .toList();
    await _localStorageService.saveOfflineQueueBackup(data);
  }

  void _initMockData() {
    // Standard transactions
    transactions = [
      Transaction(
        id: "TX-101",
        title: "Transfert vers K. Yao",
        amount: -15000,
        asset: "XOF",
        type: "send",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: "completed",
        description: "Envoi d'argent mobile à Kouassi Yao",
      ),
      Transaction(
        id: "TX-102",
        title: "Reçu de Papo Airdrop",
        amount: 500,
        asset: "PAPO",
        type: "receive",
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        status: "completed",
        description: "Récompense de bienvenue PAPO Wallet",
      ),
      Transaction(
        id: "TX-103",
        title: "Dépôt Cash Sika",
        amount: 250000,
        asset: "XOF",
        type: "receive",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        status: "completed",
        description: "Dépôt d'espèces via point marchand agréé",
      ),
      Transaction(
        id: "TX-104",
        title: "Paiement Supermarché",
        amount: -24500,
        asset: "XOF",
        type: "merchant",
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        status: "completed",
        description: "Achat de provisions par QR Code",
      ),
      Transaction(
        id: "TX-105",
        title: "Envoi à Fatou Sy",
        amount: -50,
        asset: "USD",
        type: "send",
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        status: "failed",
        description: "Transfert transfrontalier USD échoué",
      ),
    ];

    // Notifications
    notifications = [
      NotificationModel(
        id: "N-1",
        title: "Sécurité : Connexion réussie",
        content: "Une nouvelle connexion a été détectée sur votre compte depuis Tecno Camon 20.",
        type: "security",
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: "N-2",
        title: "Dépôt validé",
        content: "Votre compte a été crédité de 250,000 XOF avec succès.",
        type: "success",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: "N-3",
        title: "Paiement Hors Ligne prêt",
        content: "Votre solde de secours hors ligne est configuré et disponible.",
        type: "info",
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }

  // Theme Action
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Send Money Action
  bool sendMoney(String recipient, double amount, String asset) {
    double currentBal = balances[asset] ?? 0;
    if (currentBal < amount) return false;

    balances[asset] = currentBal - amount;
    
    // Add to transaction log
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
}
