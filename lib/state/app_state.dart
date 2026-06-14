import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/appwrite_service.dart';
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
}

class AppState extends ChangeNotifier {
  AppState() {
    unawaited(initialize());
  }

  final AppwriteService _appwriteService = AppwriteService();
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
  bool isFaceVerified = false;

  bool biometricsEnabled = false;
  bool twoFactorEnabled = false;

  Future<void> initialize() async {
    try {
      pairedDevices = await _localStorageService.loadPairings();
      final user = await _appwriteService.getCurrentUser();
      if (user == null) {
        _resetToGuestState();
      } else {
        await _loadFromCloud(user.$id, fallbackName: user.name);
        isAuthenticated = true;
        _currentScreen = 'Dashboard';
      }
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
      _saveSilently();
    }
    notifyListeners();
  }

  void changeLanguage(String lang) {
    language = lang;
    _saveSilently();
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveSilently();
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
      final user = await _appwriteService.register(
        fullName: fullName,
        phone: phone,
        pin: pin,
      );
      currentUserId = user.$id;
      userName = fullName;
      userPhone = phone;
      walletAddress = _buildWalletAddress(user.$id);
      avatarInitials = _buildInitials(fullName);
      activeDevices = ['Session actuelle'];
      isAuthenticated = true;
      _currentScreen = 'Dashboard';
      addNotification(
        'Compte créé',
        'Votre compte PAYPOINT est maintenant connecté à Appwrite.',
        'success',
      );
      await _persistCloudState();
      return true;
    } on AppwriteException catch (error) {
      lastError = error.message;
      return false;
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
      final user = await _appwriteService.login(phone: phone, pin: pin);
      await _loadFromCloud(user.$id, fallbackName: user.name, fallbackPhone: phone);
      isAuthenticated = true;
      _currentScreen = 'Dashboard';
      return true;
    } on AppwriteException catch (error) {
      lastError = error.message;
      return false;
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
      await _appwriteService.logout();
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
      await _appwriteService.updatePassword(
        currentPin: currentPin,
        newPin: newPin,
      );
      addNotification(
        'PIN mis à jour',
        'Votre code PIN a été modifié avec succès.',
        'security',
      );
      await _persistCloudState();
      return true;
    } on AppwriteException catch (error) {
      lastError = error.message;
      return false;
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
      await _persistCloudState();
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
        description: 'Transfert enregistré sur votre compte Appwrite.',
      ),
    );

    addNotification(
      'Transfert enregistré',
      'Envoi de $amount $asset vers $recipient sauvegardé avec succès.',
      'success',
    );
    _saveSilently();
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
        description: 'Réception enregistrée sur votre compte Appwrite.',
      ),
    );

    addNotification(
      'Fonds reçus',
      'Réception de $amount $asset enregistrée avec succès.',
      'success',
    );
    _saveSilently();
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
          'Transaction signée localement. Synchronisation Appwrite requise.',
    );

    offlineQueue.insert(0, tx);
    transactions.insert(0, tx);
    addNotification(
      'Paiement hors ligne enregistré',
      'Le paiement sera synchronisé avec Appwrite dès que le réseau revient.',
      'info',
    );
    unawaited(persistOfflineQueueSnapshot());
    _saveSilently();
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
    }

    final count = offlineQueue.length;
    offlineQueue.clear();
    addNotification(
      'Synchronisation terminée',
      '$count transaction(s) hors ligne ont été poussées sur Appwrite.',
      'success',
    );
    unawaited(persistOfflineQueueSnapshot());
    _saveSilently();
    notifyListeners();
  }

  Future<bool> uploadKYCDocument({
    required String type,
    required PlatformFile documentFile,
    PlatformFile? selfieFile,
  }) async {
    isBusy = true;
    lastError = null;
    notifyListeners();

    try {
      uploadedDocType = type;
      uploadedDocName = documentFile.name;
      uploadedKycFileId = await _appwriteService.uploadUserFile(documentFile);
      if (selfieFile != null) {
        await _appwriteService.uploadUserFile(selfieFile);
        isFaceVerified = true;
      }
      kycStatus = 'pending';
      addNotification(
        'KYC soumis',
        'Votre dossier $type a été téléversé vers Appwrite pour vérification.',
        'info',
      );
      await _persistCloudState();
      return true;
    } on AppwriteException catch (error) {
      lastError = error.message;
      return false;
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
    _saveSilently();
    notifyListeners();
  }

  void approveKYC() {
    kycStatus = 'verified';
    addNotification(
      'Compte vérifié',
      'Votre identité a été approuvée.',
      'success',
    );
    _saveSilently();
    notifyListeners();
  }

  void rejectKYC() {
    kycStatus = 'rejected';
    addNotification(
      'KYC rejeté',
      'Le dossier nécessite une nouvelle soumission.',
      'security',
    );
    _saveSilently();
    notifyListeners();
  }

  void resetKYC() {
    kycStatus = 'none';
    uploadedDocType = null;
    uploadedDocName = null;
    uploadedKycFileId = null;
    isFaceVerified = false;
    _saveSilently();
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
    _saveSilently();
  }

  void markAllNotificationsAsRead() {
    for (final notification in notifications) {
      notification.isRead = true;
    }
    _saveSilently();
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      _saveSilently();
      notifyListeners();
    }
  }

  void toggleBiometrics() {
    biometricsEnabled = !biometricsEnabled;
    _saveSilently();
    notifyListeners();
  }

  void toggle2FA() {
    twoFactorEnabled = !twoFactorEnabled;
    _saveSilently();
    notifyListeners();
  }

  void removeDevice(String device) {
    activeDevices.remove(device);
    addNotification(
      'Appareil révoqué',
      'La session sur $device a été supprimée.',
      'security',
    );
    _saveSilently();
    notifyListeners();
  }

  Future<void> _loadFromCloud(
    String userId, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    currentUserId = userId;
    final prefs = await _appwriteService.getPrefs();

    userName = prefs['userName']?.toString() ??
        (fallbackName == null || fallbackName.isEmpty ? 'Utilisateur' : fallbackName);
    userPhone = prefs['userPhone']?.toString() ?? (fallbackPhone ?? '');
    walletAddress =
        prefs['walletAddress']?.toString() ?? _buildWalletAddress(userId);
    avatarInitials =
        prefs['avatarInitials']?.toString() ?? _buildInitials(userName);
    isMerchant = prefs['isMerchant'] == true;
    language = prefs['language']?.toString() ?? 'fr';
    biometricsEnabled = prefs['biometricsEnabled'] == true;
    twoFactorEnabled = prefs['twoFactorEnabled'] == true;
    kycStatus = prefs['kycStatus']?.toString() ?? 'none';
    uploadedDocType = prefs['uploadedDocType']?.toString();
    uploadedDocName = prefs['uploadedDocName']?.toString();
    uploadedKycFileId = prefs['uploadedKycFileId']?.toString();
    isFaceVerified = prefs['isFaceVerified'] == true;

    final theme = prefs['themeMode']?.toString();
    _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;

    final storedBalances = prefs['balances'];
    balances
      ..clear()
      ..addAll(_parseBalanceMap(storedBalances));

    transactions = _parseTransactions(prefs['transactions']);
    offlineQueue = _parseTransactions(prefs['offlineQueue']);
    notifications = _parseNotifications(prefs['notifications']);
    activeDevices = _parseStringList(prefs['activeDevices']);

    final storedPairings = prefs['pairedDevices'];
    if (storedPairings is List) {
      pairedDevices = storedPairings
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
  }

  Future<void> _persistCloudState() async {
    if (!isAuthenticated) {
      return;
    }

    await _appwriteService.updatePrefs({
      'userName': userName,
      'userPhone': userPhone,
      'walletAddress': walletAddress,
      'avatarInitials': avatarInitials,
      'isMerchant': isMerchant,
      'language': language,
      'themeMode': _themeMode == ThemeMode.light ? 'light' : 'dark',
      'balances': balances,
      'transactions': transactions.map((tx) => tx.toMap()).toList(),
      'offlineQueue': offlineQueue.map((tx) => tx.toMap()).toList(),
      'notifications': notifications.map((n) => n.toMap()).toList(),
      'activeDevices': activeDevices,
      'pairedDevices': pairedDevices,
      'kycStatus': kycStatus,
      'uploadedDocType': uploadedDocType,
      'uploadedDocName': uploadedDocName,
      'uploadedKycFileId': uploadedKycFileId,
      'isFaceVerified': isFaceVerified,
      'biometricsEnabled': biometricsEnabled,
      'twoFactorEnabled': twoFactorEnabled,
    });
  }

  void _saveSilently() {
    if (!isAuthenticated) {
      return;
    }
    unawaited(_persistCloudState());
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
    isFaceVerified = false;
    biometricsEnabled = false;
    twoFactorEnabled = false;
    _currentScreen = 'Onboarding';
  }

  Map<String, double> _parseBalanceMap(dynamic raw) {
    final result = <String, double>{
      'XOF': 0,
      'USD': 0,
      'PAPO': 0,
      'BTC': 0,
    };

    if (raw is Map) {
      for (final entry in raw.entries) {
        result[entry.key.toString()] = (entry.value as num?)?.toDouble() ?? 0;
      }
    }
    return result;
  }

  List<Transaction> _parseTransactions(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Transaction.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }

  List<NotificationModel> _parseNotifications(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map(
          (entry) => NotificationModel.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    return raw.map((entry) => entry.toString()).toList();
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
