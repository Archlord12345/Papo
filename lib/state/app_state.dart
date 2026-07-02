import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/wallet_slot_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../models/circle_model.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final DbService _db = DbService();
  final ApiService _api = ApiService();
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // ── Navigation stack ───────────────────────────────────────────────────────
  final List<String> _navStack = ['Splash'];
  String get currentScreen => _navStack.last;

  void setScreen(String screen) {
    if (_navStack.last == screen) return;
    const tabScreens = {'Dashboard', 'Wallet', 'SendMoney', 'History', 'Menu'};
    if (tabScreens.contains(screen)) {
      _navStack.clear();
      _navStack.add(screen);
    } else {
      _navStack.add(screen);
    }
    notifyListeners();
  }

  bool popScreen() {
    if (_navStack.length <= 1) return false;
    _navStack.removeLast();
    notifyListeners();
    return true;
  }

  void replaceScreen(String screen) {
    _navStack.clear();
    _navStack.add(screen);
    notifyListeners();
  }

  void resetToScreen(String screen) {
    _navStack.clear();
    _navStack.add(screen);
    notifyListeners();
  }

  bool get canGoBack => _navStack.length > 1;

  // ── Authenticated user ─────────────────────────────────────────────────────
  UserModel? _user;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  int get userId => _user?.id ?? 0;

  String get userName => _user?.name ?? '';
  String get userPhone => _user?.phone ?? '';
  String get blockchainAddr => _user?.blockchainAddr ?? '';
  String get avatarInitials => _user?.initials ?? '';
  bool get isMerchant => _user?.isMerchant ?? false;
  bool get isAgent => _user?.isAgent ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  String get kycStatus => _user?.kycStatus ?? 'none';
  bool get isFaceVerified => _user?.faceVerified ?? false;
  bool get biometricsEnabled => _user?.biometricsEnabled ?? true;
  bool get twoFactorEnabled => _user?.twoFactorEnabled ?? false;
  String get language => _user?.language ?? 'fr';
  String get walletAddress => activeWalletId;
  String get kycDocType => _user?.kycDocType ?? '';
  String get kycDocName => _user?.kycDocName ?? '';
  bool get isRefreshing => _isRefreshing;

  // ── Theme ──────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ── Wallet slots ──────────────────────────────────────────────────────────
  List<WalletSlotModel> walletSlots = [];

  WalletSlotModel? get activeSlot {
    if (walletSlots.isEmpty) return null;
    try {
      return walletSlots.firstWhere((s) => s.isActive);
    } catch (_) {
      return walletSlots.first;
    }
  }

  double get balance => activeSlot?.balance ?? 0;
  Map<String, double> get balances => activeSlot?.balances ?? {'PAPO': 0};
  String get activeWalletId => activeSlot?.walletId ?? '';
  List<Map<String, dynamic>> deviceCatalog = [];

  // ── Cached data ───────────────────────────────────────────────────────────
  List<TransactionModel> transactions = [];
  List<TransactionModel> offlineQueue = [];
  List<NotificationModel> notifications = [];
  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> get devices => sessions;
  List<CircleModel> circles = [];

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicRefresh();
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      try {
        await _loadUserData();
        setScreen('Dashboard');
      } catch (e) {
        setScreen('Login');
      }
    } else {
      setScreen('Login');
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshFromBackend();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPeriodicRefresh();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isLoggedIn && !_isRefreshing) {
        refreshFromBackend();
      }
    });
  }

  void _stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadUserData() async {
    _isRefreshing = true;
    notifyListeners();
    
    try {
      if (_user == null) {
        try {
          final res = await _api.getCurrentUser();
          _user = UserModel.fromJson(res['user']);
          await _db.updateUser(_user!);
        } catch (e) {
          return;
        }
      }
      
      try {
        final walletsJson = await _api.getWallets();
        await _db.syncWallets(userId, walletsJson);
        
        final txsJson = await _api.getTransactions();
        await _db.syncTransactions(userId, txsJson);
        
        final notifsJson = await _api.getNotifications();
        await _db.syncNotifications(userId, notifsJson);

        final circlesJson = await _api.getCircles();
        await _db.syncCircles(userId, circlesJson);

        await _refreshData();
      } catch (e) {
        debugPrint('Sync error: $e');
        await _refreshData();
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ── ASSETS ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getAvailableAssets() async {
    try {
      return await _api.getAssets();
    } catch (e) {
      return [{'code': 'PAPO', 'name': 'Papo Coin'}, {'code': 'XOF', 'name': 'Franc CFA'}];
    }
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<String?> register(String name, String phone, String pin) async {
    try {
      final res = await _api.register(name.trim(), phone.trim(), pin, null);
      _user = UserModel.fromJson(res['user']);
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String phone, String pin) async {
    try {
      final res = await _api.login(phone.trim(), pin);
      _user = UserModel.fromJson(res['user']);
      _themeMode = (_user!.themeMode == 'dark') ? ThemeMode.dark : ThemeMode.light;
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> unlockWithBiometrics() async {
    await _loadUserData();
    setScreen('Dashboard');
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    walletSlots = [];
    transactions = [];
    resetToScreen('Login');
  }

  // ── WALLET MANAGEMENT ─────────────────────────────────────────────────────

  Future<String?> createWalletSlot({required String name, required String deviceName, String asset = 'PAPO'}) async {
    try {
      await _api.createWallet(name, deviceName, asset);
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> setActiveWalletSlot(int slotId) async {
    try {
      await _api.setActiveWallet(slotId);
      await _loadUserData();
    } catch (e) {
      debugPrint('Remote setActiveWallet failed: $e');
    }
  }

  Future<void> renameWalletSlot(int slotId, String newName) async {
    try {
      await _api.updateWallet(slotId, newName);
      await _loadUserData();
    } catch (e) {
      debugPrint('Remote updateWallet failed: $e');
    }
  }

  Future<String?> deleteWalletSlot(int slotId) async {
    try {
      await _api.deleteWallet(slotId);
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── TRANSFERS ─────────────────────────────────────────────────────────────

  Future<bool> sendMoney({
    required String recipient,
    required double amount,
    String asset = 'PAPO',
    String method = 'standard',
    bool isOffline = false,
  }) async {
    final slot = activeSlot;
    if (slot == null) return false;

    final tempTx = TransactionModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      slotId: slot.id!,
      title: 'Transfert vers $recipient',
      amount: -amount,
      asset: asset,
      type: 'TRANSFER',
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    transactions.insert(0, tempTx);
    notifyListeners();

    try {
      await _api.sendMoney(
        recipientPhone: recipient,
        amount: amount,
        method: method,
        isOffline: isOffline,
      );
      await refreshFromBackend();
      return true;
    } catch (e) {
      transactions.removeWhere((tx) => tx.id == tempTx.id);
      notifyListeners();
      return false;
    }
  }

  Future<void> receiveMoney(double amount, String asset, {String senderLabel = 'Fonds reçus'}) async {
    await _loadUserData();
  }

  Future<void> topUp(double amount, String asset) async {
    await _loadUserData();
  }

  Future<void> syncOfflineTransactions() async {
    try {
      await _api.syncOfflineTransactions();
      await _loadUserData();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  // ── KYC ──────────────────────────────────────────────────────────────────

  Future<void> uploadKYCDocument(String type, String filePath, {String? secondFilePath}) async {
    try {
      String fileUrl;
      if (secondFilePath != null && secondFilePath.isNotEmpty) {
        final files = [File(filePath), File(secondFilePath)];
        final uploadRes = await _api.uploadMultipleFiles(files);
        fileUrl = (uploadRes['files'] as List)[0]['url'];
      } else {
        final uploadRes = await _api.uploadFile(File(filePath));
        fileUrl = uploadRes['file']['url'];
      }
      await _api.submitKyc(type, fileUrl, 'DOC-${DateTime.now().millisecondsSinceEpoch}');
      await _loadUserData();
    } catch (e) {
      debugPrint('KYC upload error: $e');
      rethrow;
    }
  }

  Future<void> verifyFace() async {
    await _loadUserData();
  }

  Future<void> resetKYC() async {
    await _loadUserData();
  }

  // ── SECURITY ─────────────────────────────────────────────────────────────

  Future<void> toggleBiometrics() async {
    await _loadUserData();
  }

  Future<void> toggle2FA() async {
    await _loadUserData();
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      await _api.changePin(currentPin, newPin);
      await _loadUserData();
      return true;
    } catch (e) {
      debugPrint('Change PIN error: $e');
      return false;
    }
  }

  Future<void> removeDevice(int sessionId, String label) async {
    await _loadUserData();
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<void> addNotification(String title, String content, String type) async {
    await _db.addNotification(userId: userId, title: title, content: content, type: type);
    await _refreshData();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.markNotificationRead(id);
    await _loadUserData();
  }

  Future<void> markAllNotificationsAsRead() async {
    await _api.markAllNotificationsRead();
    await _loadUserData();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // ── CIRCLE ────────────────────────────────────────────────────────────────

  Future<String?> createCircle({required String name, required String description, required double target, required double contribution, required String frequency}) async {
    try {
      await _api.createCircle(name: name, description: description, target: target, contribution: contribution, frequency: frequency);
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateCircle(CircleModel circle) async {
    await _loadUserData();
  }

  Future<void> deleteCircle(int circleId) async {
    await _api.deleteCircle(circleId);
    await _loadUserData();
  }

  Future<String?> addCircleMember({required int circleId, required String name, required String phone, String? walletId}) async {
    try {
      await _api.addCircleMember(circleId, name, phone, walletId);
      await _loadUserData();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> contributeToCircle(int circleId, int memberId, double amount, String asset) async {
    try {
      await _api.markCircleMemberPaid(circleId, memberId, amount);
      await _loadUserData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> removeCircleMember(int memberId) async {
    await _loadUserData();
  }

  // ── BILLS ─────────────────────────────────────────────────────────────────

  Future<bool> payBill({required String provider, required String reference, required double amount}) async {
    try {
      await _loadUserData();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── SETTINGS ─────────────────────────────────────────────────────────────

  Future<void> changeLanguage(String lang) async {
    _user = _user?.copyWith(language: lang);
    notifyListeners();
  }

  // ── Refresh helpers ───────────────────────────────────────────────────────

  Future<void> _refreshData() async {
    if (_user == null) return;
    walletSlots = await _db.getWalletSlots(userId);
    transactions = await _db.getTransactions(userId);
    offlineQueue = await _db.getOfflineQueue(userId);
    notifications = await _db.getNotifications(userId);
    sessions = await _db.getSessions(userId);
    circles = await _db.getCircles(userId);
    notifyListeners();
  }

  Future<void> refreshFromBackend() async {
    await _loadUserData();
  }

  // ── ADMIN ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> _adminStats = {};
  Map<String, dynamic> get adminStats => _adminStats;
  bool adminLoading = false;
  List<Map<String, dynamic>> adminUsers = [];
  List<Map<String, dynamic>> kycQueue = [];
  List<Map<String, dynamic>> adminDisputes = [];

  Future<void> loadAdminStats() async {
    if (!isAdmin) return;
    adminLoading = true;
    notifyListeners();
    try {
      _adminStats = await _api.getAdminDashboardStats();
    } finally {
      adminLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadKycQueue() async {
    kycQueue = await _api.getKycQueue();
    notifyListeners();
  }

  Future<void> loadAdminUsers() async {
    adminUsers = await _api.getAdminUsers();
    notifyListeners();
  }

  Future<void> loadAdminDisputes() async {
    adminDisputes = await _api.getAdminDisputes();
    notifyListeners();
  }

  Future<bool> adminApproveKyc(int id) async {
    try {
      await _api.adminReviewKyc(id, 'APPROVED', null);
      await loadKycQueue();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> adminRejectKyc(int id, String? reason) async {
    try {
      await _api.adminReviewKyc(id, 'REJECTED', reason);
      await loadKycQueue();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> adminToggleUserActive(int id, bool current) async {
    try {
      await _api.adminUpdateUser(id, {'isActive': !current});
      await loadAdminUsers();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> adminSetMerchant(int id, bool current) async {
    try {
      await _api.adminUpdateUser(id, {'isMerchant': !current});
      await loadAdminUsers();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> adminUpdateDispute(String id, String status, String? resolution) async {
    try {
      await _api.adminUpdateDispute(id, status, resolution);
      await loadAdminDisputes();
      return true;
    } catch (e) { return false; }
  }
}
