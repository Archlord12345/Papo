import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../services/pocketbase_service.dart';
import '../services/local_storage_service.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String asset;
  final String type;
  final DateTime timestamp;
  String status;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'asset': asset,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'description': description,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      asset: map['asset']?.toString() ?? 'XOF',
      type: map['type']?.toString() ?? 'send',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      status: map['status']?.toString() ?? 'completed',
      description: map['description']?.toString() ?? '',
    );
  }

  factory Transaction.fromRecord(RecordModel record) {
    return Transaction(
      id: record.id,
      title: record.getStringValue('type') == 'send' ? 'Transfert envoyé' : 'Réception de fonds',
      amount: record.getDoubleValue('amount'),
      asset: 'XOF', // PocketBase schema doesn't have asset, defaulting to XOF
      type: record.getStringValue('type'),
      timestamp: DateTime.parse(record.created),
      status: record.getStringValue('status'),
      description: 'Transaction PocketBase',
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String content;
  final String type;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      type: map['type']?.toString() ?? 'info',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isRead: map['isRead'] == true,
    );
  }

  factory NotificationModel.fromRecord(RecordModel record) {
    return NotificationModel(
      id: record.id,
      title: 'Notification',
      content: record.getStringValue('message'),
      type: 'info',
      timestamp: DateTime.parse(record.created),
      isRead: record.getBoolValue('read'),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState() {
    unawaited(initialize());
  }

  final PocketBaseService _pbService = PocketBaseService();
  final LocalStorageService _localStorageService = LocalStorageService();

  bool isInitializing = true;
  bool isAuthenticated = false;
  bool isBusy = false;
  String? lastError;
  String currentAuthFlow = 'login';

  String _currentScreen = 'Splash';
  String get currentScreen => _currentScreen;

  List<String> recentlyVisited = ['Dashboard', 'Wallet', 'Circle', 'Developer'];

  String currentUserId = '';
  String language = 'fr';
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  String userName = 'Utilisateur';
  String userPhone = '';
  String walletAddress = '';
  String avatarInitials = 'PP';
  bool isMerchant = false;

  final Map<String, double> balances = {
    'XOF': 0,
    'USD': 0,
    'PAPO': 0,
    'BTC': 0,
  };

  List<Transaction> transactions = [];
  List<Transaction> offlineQueue = [];
  List<NotificationModel> notifications = [];

  List<String> activeDevices = [];
  List<Map<String, dynamic>> pairedDevices = [];

  String kycStatus = 'none';
  String? uploadedDocType;
  String? uploadedDocName;
  String? uploadedKycFileId;
  String? uploadedSelfieFileId;
  bool isFaceVerified = false;

  bool biometricsEnabled = false;
  bool twoFactorEnabled = false;

  Future<void> initialize() async {
    try {
      pairedDevices = await _localStorageService.loadPairings();
      final user = await _pbService.getCurrentUser();
      if (user == null) {
        _resetToGuestState();
      } else {
        await _loadFromPocketBase(user);
        isAuthenticated = true;
        _currentScreen = 'Dashboard';
      }
    } catch (e) {
      _resetToGuestState();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  void setBusy(bool value) {
    isBusy = value;
    notifyListeners();
  }

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

  void changeLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String pin,
  }) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      final user = await _pbService.register(
        fullName: fullName,
        phone: phone,
        pin: pin,
      );
      await _loadFromPocketBase(user);

      // Initialize a default wallet
      await _pbService.createWallet(
        address: walletAddress,
        currency: 'XOF',
        balance: 10000, // Welcome bonus
      );
      balances['XOF'] = 10000;

      isAuthenticated = true;
      _currentScreen = 'Dashboard';
      addNotification(
        'Compte créé',
        'Votre compte PAYPOINT est maintenant connecté à PocketBase.',
        'success',
      );
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String phone,
    required String pin,
  }) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      final user = await _pbService.login(phone: phone, pin: pin);
      await _loadFromPocketBase(user);
      isAuthenticated = true;
      _currentScreen = 'Dashboard';
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isBusy = true;
    notifyListeners();

    try {
      await _pbService.logout();
      _resetToGuestState();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      await _pbService.updatePassword(
        currentPin: currentPin,
        newPin: newPin,
      );
      addNotification(
        'PIN mis à jour',
        'Votre code PIN a été modifié avec succès.',
        'security',
      );
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> addPairedDevice({
    required String peerId,
    required String alias,
  }) async {
    final exists = pairedDevices.any((d) => d['peerId'] == peerId);
    if (!exists) {
      pairedDevices.insert(0, {
        'peerId': peerId,
        'alias': alias,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _localStorageService.savePairings(pairedDevices);
      addNotification(
        'Appareil appairé',
        'Nouveau contact NFC enregistré : $alias.',
        'success',
      );
      notifyListeners();
    }
  }

  Future<void> persistOfflineQueueSnapshot() async {
    await _localStorageService.saveOfflineQueueBackup(
      offlineQueue.map((tx) => tx.toMap()).toList(),
    );
  }

  bool sendMoney(String recipient, double amount, String asset) {
    final currentBal = balances[asset] ?? 0;
    if (currentBal < amount) {
      return false;
    }

    balances[asset] = currentBal - amount;

    // In a real app, recipient should be a user ID
    // We'll simulate finding a user or using a placeholder
    _pbService.createTransaction(
      receiverId: recipient, // Assuming recipient is a valid user ID or address for this simulation
      amount: amount,
      type: 'send',
    );

    transactions.insert(
      0,
      Transaction(
        id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Transfert vers $recipient',
        amount: -amount,
        asset: asset,
        type: 'send',
        timestamp: DateTime.now(),
        status: 'completed',
        description: 'Transfert enregistré sur PocketBase.',
      ),
    );

    addNotification(
      'Transfert enregistré',
      'Envoi de $amount $asset vers $recipient sauvegardé avec succès.',
      'success',
    );
    notifyListeners();
    return true;
  }

  void receiveMoney(double amount, String asset) {
    final currentBal = balances[asset] ?? 0;
    balances[asset] = currentBal + amount;

    transactions.insert(
      0,
      Transaction(
        id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Réception de fonds',
        amount: amount,
        asset: asset,
        type: 'receive',
        timestamp: DateTime.now(),
        status: 'completed',
        description: 'Réception enregistrée sur PocketBase.',
      ),
    );

    addNotification(
      'Fonds reçus',
      'Réception de $amount $asset enregistrée avec succès.',
      'success',
    );
    notifyListeners();
  }

  void addOfflineTransaction(double amount, String recipient) {
    final currentBal = balances['XOF'] ?? 0;
    balances['XOF'] = currentBal - amount;

    final tx = Transaction(
      id: 'OFF-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Paiement hors ligne vers $recipient',
      amount: -amount,
      asset: 'XOF',
      type: 'offline',
      timestamp: DateTime.now(),
      status: 'pending',
      description:
          'Transaction signée localement. Synchronisation PocketBase requise.',
    );

    offlineQueue.insert(0, tx);
    transactions.insert(0, tx);
    addNotification(
      'Paiement hors ligne enregistré',
      'Le paiement sera synchronisé dès que le réseau revient.',
      'info',
    );
    unawaited(persistOfflineQueueSnapshot());
    notifyListeners();
  }

  void syncOfflineTransactions() {
    if (offlineQueue.isEmpty) {
      return;
    }

    for (final tx in offlineQueue) {
      final index = transactions.indexWhere((element) => element.id == tx.id);
      if (index != -1) {
        transactions[index].status = 'completed';
      }
      // Create transaction in PocketBase
      _pbService.createTransaction(
        receiverId: 'offline-sync',
        amount: tx.amount.abs(),
        type: 'offline',
      );
    }

    final count = offlineQueue.length;
    offlineQueue.clear();
    addNotification(
      'Synchronisation terminée',
      '$count transaction(s) hors ligne ont été poussées sur PocketBase.',
      'success',
    );
    unawaited(persistOfflineQueueSnapshot());
    notifyListeners();
  }

  Future<bool> uploadKYCDocument({
    required String type,
    PlatformFile? documentFile,
    PlatformFile? selfieFile,
  }) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      uploadedDocType = type;
      if (documentFile != null) {
        uploadedDocName = documentFile.name;
        await _pbService.uploadKycDocument(status: 'pending', file: documentFile);
      }
      if (selfieFile != null) {
        await _pbService.uploadKycDocument(status: 'pending', file: selfieFile);
        isFaceVerified = true;
      }
      kycStatus = 'pending';
      addNotification(
        'KYC soumis',
        'Votre dossier $type a été téléversé vers PocketBase pour vérification.',
        'info',
      );
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void verifyFace() {
    isFaceVerified = true;
    notifyListeners();
  }

  void approveKYC() {
    kycStatus = 'verified';
    addNotification(
      'Compte vérifié',
      'Votre identité a été approuvée.',
      'success',
    );
    notifyListeners();
  }

  void rejectKYC() {
    kycStatus = 'rejected';
    addNotification(
      'KYC rejeté',
      'Le dossier nécessite une nouvelle soumission.',
      'security',
    );
    notifyListeners();
  }

  void resetKYC() {
    kycStatus = 'none';
    uploadedDocType = null;
    uploadedDocName = null;
    uploadedKycFileId = null;
    uploadedSelfieFileId = null;
    isFaceVerified = false;
    notifyListeners();
  }

  void addNotification(String title, String content, String type) {
    notifications.insert(
      0,
      NotificationModel(
        id: 'N-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
    // In a real app, save to PocketBase
  }

  void markAllNotificationsAsRead() {
    for (final notification in notifications) {
      notification.isRead = true;
      if (!notification.id.startsWith('N-')) {
        _pbService.markNotificationRead(notification.id, true);
      }
    }
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      if (!id.startsWith('N-')) {
        _pbService.markNotificationRead(id, true);
      }
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
      'Appareil révoqué',
      'La session sur $device a été supprimée.',
      'security',
    );
    notifyListeners();
  }

  Future<void> _loadFromPocketBase(RecordModel user) async {
    currentUserId = user.id;
    userName = user.getStringValue('name').isEmpty ? 'Utilisateur' : user.getStringValue('name');
    userPhone = user.getStringValue('phone');
    walletAddress = _buildWalletAddress(user.id);
    avatarInitials = _buildInitials(userName);

    // Load Wallets
    final walletRecords = await _pbService.getWallets();
    balances.clear();
    balances.addAll({'XOF': 0, 'USD': 0, 'PAPO': 0, 'BTC': 0});
    for (var w in walletRecords) {
      balances[w.getStringValue('currency')] = w.getDoubleValue('balance');
    }

    // Load Transactions
    final transRecords = await _pbService.getTransactions();
    transactions = transRecords.map((r) => Transaction.fromRecord(r)).toList();

    // Load Notifications
    final notifRecords = await _pbService.getNotifications();
    notifications = notifRecords.map((r) => NotificationModel.fromRecord(r)).toList();

    // Load KYC
    final kycRecord = await _pbService.getKycStatus();
    if (kycRecord != null) {
      kycStatus = kycRecord.getStringValue('status');
      uploadedDocType = 'Identité';
      isFaceVerified = kycRecord.getStringValue('document').isNotEmpty;
    }

    // Load Devices
    final deviceRecords = await _pbService.getDevices();
    activeDevices = deviceRecords.map((r) => r.getStringValue('device_id')).toList();
    if (activeDevices.isEmpty) activeDevices.add('Session actuelle');
  }

  void _resetToGuestState() {
    isAuthenticated = false;
    currentUserId = '';
    userName = 'Utilisateur';
    userPhone = '';
    walletAddress = '';
    avatarInitials = 'PP';
    isMerchant = false;
    language = 'fr';
    _themeMode = ThemeMode.dark;
    balances
      ..clear()
      ..addAll({
        'XOF': 0,
        'USD': 0,
        'PAPO': 0,
        'BTC': 0,
      });
    transactions = [];
    offlineQueue = [];
    notifications = [];
    activeDevices = [];
    kycStatus = 'none';
    uploadedDocType = null;
    uploadedDocName = null;
    uploadedKycFileId = null;
    uploadedSelfieFileId = null;
    isFaceVerified = false;
    biometricsEnabled = false;
    twoFactorEnabled = false;
    _currentScreen = 'Onboarding';
  }

  String _buildWalletAddress(String userId) {
    final compact = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'papo_${compact.substring(0, compact.length > 12 ? 12 : compact.length)}';
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'PP';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
