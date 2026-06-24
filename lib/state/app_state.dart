import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/wallet_slot_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../models/circle_model.dart';
import '../services/db_service.dart';

class AppState extends ChangeNotifier {
  final DbService _db = DbService();

  // ── Navigation stack ───────────────────────────────────────────────────────
  final List<String> _navStack = ['Splash'];

  String get currentScreen => _navStack.last;

  /// Push a new screen (go forward)
  void setScreen(String screen) {
    if (_navStack.last == screen) return;
    // Tab screens replace stack for cleaner navigation
    const tabScreens = {'Dashboard', 'Wallet', 'SendMoney', 'History', 'Menu'};
    if (tabScreens.contains(screen)) {
      // Keep only base screens below current tab root
      _navStack.clear();
      _navStack.add(screen);
    } else {
      _navStack.add(screen);
    }
    notifyListeners();
  }

  /// Pop back to previous screen. Returns false if nothing to pop.
  bool popScreen() {
    if (_navStack.length <= 1) return false;
    _navStack.removeLast();
    notifyListeners();
    return true;
  }

  /// Replace current screen (no back possible to previous)
  void replaceScreen(String screen) {
    _navStack.clear();
    _navStack.add(screen);
    notifyListeners();
  }

  /// Clear stack and set root (for logout / login transitions)
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
  String get kycStatus => _user?.kycStatus ?? 'none';
  bool get isFaceVerified => _user?.faceVerified ?? false;
  bool get biometricsEnabled => _user?.biometricsEnabled ?? true;
  bool get twoFactorEnabled => _user?.twoFactorEnabled ?? false;
  String get language => _user?.language ?? 'fr';
  String get walletAddress => activeWalletId;
  String get kycDocType => _user?.kycDocType ?? '';
  String get kycDocName => _user?.kycDocName ?? '';

  // ── Theme ──────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // ── Wallet slots ──────────────────────────────────────────────────────────
  List<WalletSlotModel> walletSlots = [];
  WalletSlotModel? get activeSlot =>
      walletSlots.isEmpty ? null : walletSlots.firstWhere(
        (s) => s.isActive,
        orElse: () => walletSlots.first,
      );

  /// Active wallet balance (XOF only)
  double get balance => activeSlot?.balance ?? 0;

  // Compat : les anciens écrans utilisent balances['XOF']
  Map<String, double> get balances => {'XOF': balance};

  /// Active wallet ID e.g. PAPO-ABC123-0
  String get activeWalletId => activeSlot?.walletId ?? '';
  List<Map<String, dynamic>> deviceCatalog = [];

  // ── Cached data ───────────────────────────────────────────────────────────
  List<TransactionModel> transactions = [];
  List<TransactionModel> offlineQueue = [];
  List<NotificationModel> notifications = [];
  List<Map<String, dynamic>> sessions = [];
  // Alias for backward compat
  List<Map<String, dynamic>> get devices => sessions;
  List<CircleModel> circles = [];

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    deviceCatalog = await _db.getDeviceCatalog();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    final uid = userId;
    walletSlots = await _db.getWalletSlots(uid);
    transactions = await _db.getTransactions(uid);
    offlineQueue = await _db.getOfflineQueue(uid);
    notifications = await _db.getNotifications(uid);
    sessions = await _db.getSessions(uid);
    circles = await _db.getCircles(uid);
    notifyListeners();
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<String?> register(String name, String phone, String pin) async {
    if (name.trim().isEmpty) return 'Veuillez saisir votre nom complet';
    if (phone.trim().isEmpty) return 'Numéro de téléphone requis';
    if (pin.length < 4) return 'Code PIN minimum 4 chiffres';

    if (await _db.phoneExists(phone.trim())) {
      return 'Ce numéro est déjà enregistré';
    }

    _user = await _db.createUser(name: name.trim(), phone: phone.trim(), pin: pin);
    _themeMode = ThemeMode.dark;
    await _loadUserData();
    return null;
  }

  Future<String?> login(String phone, String pin) async {
    if (phone.trim().isEmpty || pin.isEmpty) return 'Champs obligatoires';
    final u = await _db.loginUser(phone.trim(), pin);
    if (u == null) return 'Numéro ou PIN incorrect';

    _user = u;
    _themeMode = u.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    await _loadUserData();
    await _db.addNotification(
      userId: userId,
      title: 'Connexion',
      content: 'Bon retour ${u.name} !',
      type: 'security',
    );
    notifications = await _db.getNotifications(userId);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _user = null;
    walletSlots = [];
    transactions = [];
    offlineQueue = [];
    notifications = [];
    sessions = [];
    circles = [];
    resetToScreen('Login');
  }

  // ── WALLET MANAGEMENT ─────────────────────────────────────────────────────

  /// Returns null if max 10 slots reached, or error string.
  Future<String?> createWalletSlot({
    required String name,
    required String deviceName,
  }) async {
    if (walletSlots.length >= 10) return 'Maximum 10 wallets atteint';
    final slot = await _db.createNewSlot(
      userId: userId,
      blockchainAddr: blockchainAddr,
      name: name,
      deviceName: deviceName,
    );
    if (slot == null) return 'Impossible de créer le wallet';
    walletSlots = await _db.getWalletSlots(userId);
    await _db.addNotification(
      userId: userId,
      title: 'Wallet créé',
      content: '$name (${slot.walletId}) a été activé.',
      type: 'success',
    );
    notifications = await _db.getNotifications(userId);
    notifyListeners();
    return null;
  }

  Future<void> setActiveWalletSlot(int slotId) async {
    await _db.setActiveSlot(userId, slotId);
    walletSlots = await _db.getWalletSlots(userId);
    transactions = await _db.getTransactions(userId);
    notifyListeners();
  }

  Future<void> renameWalletSlot(int slotId, String newName) async {
    await _db.updateSlotName(slotId, newName);
    walletSlots = await _db.getWalletSlots(userId);
    notifyListeners();
  }

  Future<String?> deleteWalletSlot(int slotId) async {
    final slot = walletSlots.firstWhere((s) => s.id == slotId, orElse: () => walletSlots.first);
    if (slot.isActive) return 'Impossible de supprimer le wallet actif';
    await _db.deleteSlot(slotId);
    walletSlots = await _db.getWalletSlots(userId);
    notifyListeners();
    return null;
  }

  // ── TRANSFERS ─────────────────────────────────────────────────────────────

  Future<bool> sendMoney({
    required String recipient,
    required double amount,
    String asset = 'XOF',
    String method = 'standard',
    bool isOffline = false,
  }) async {
    final slot = activeSlot;
    if (slot == null) return false;

    final ok = await _db.sendMoney(
      userId: userId,
      slotId: slot.id!,
      recipient: recipient,
      amount: amount,
      method: method,
      isOffline: isOffline,
    );
    if (!ok) return false;

    await _db.addNotification(
      userId: userId,
      title: isOffline ? 'Transaction offline signée' : 'Transfert réussi',
      content: '${amount.toStringAsFixed(0)} XOF → $recipient (via ${method.toUpperCase()})',
      type: 'success',
    );
    await _refreshData();
    return true;
  }

  Future<void> receiveMoney(double amount, String asset,
      {String senderLabel = 'Fonds reçus', String method = 'standard'}) async {
    final slot = activeSlot;
    if (slot == null) return;

    await _db.receiveMoney(
      userId: userId,
      slotId: slot.id!,
      amount: amount,
      senderLabel: senderLabel,
      method: method,
    );
    await _db.addNotification(
      userId: userId,
      title: 'Fonds reçus',
      content: '+${amount.toStringAsFixed(0)} XOF reçus sur ${slot.name}',
      type: 'success',
    );
    await _refreshData();
  }

  Future<void> topUp(double amount, String asset) async {
    final slot = activeSlot;
    if (slot == null) return;
    await _db.topUp(userId: userId, slotId: slot.id!, amount: amount);
    await _db.addNotification(
      userId: userId,
      title: 'Dépôt réussi',
      content: '+${amount.toStringAsFixed(0)} XOF crédités sur ${slot.name}',
      type: 'success',
    );
    await _refreshData();
  }

  Future<void> syncOfflineTransactions() async {
    final count = offlineQueue.length;
    await _db.syncOfflineTransactions(userId);
    await _db.addNotification(
      userId: userId,
      title: 'Synchronisation réussie',
      content: '$count transaction(s) ancrées sur la blockchain.',
      type: 'success',
    );
    await _refreshData();
  }

  // ── KYC ──────────────────────────────────────────────────────────────────

  Future<void> uploadKYCDocument(String type, String name) async {
    _user = _user!.copyWith(kycDocType: type, kycDocName: name, kycStatus: 'pending');
    await _db.updateUser(_user!);
    await _db.addNotification(userId: userId, title: 'KYC Soumis', content: 'Documents ($type) soumis.', type: 'info');
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> verifyFace() async {
    _user = _user!.copyWith(faceVerified: true);
    await _db.updateUser(_user!);
    notifyListeners();
  }

  Future<void> approveKYC() async {
    _user = _user!.copyWith(kycStatus: 'verified');
    await _db.updateUser(_user!);
    await _db.addNotification(userId: userId, title: 'Compte vérifié', content: 'Identité approuvée ! Limites débloquées.', type: 'success');
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> rejectKYC() async {
    _user = _user!.copyWith(kycStatus: 'rejected');
    await _db.updateUser(_user!);
    await _db.addNotification(userId: userId, title: 'KYC Rejeté', content: 'Documents refusés. Veuillez soumettre à nouveau.', type: 'security');
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> resetKYC() async {
    _user = _user!.copyWith(kycStatus: 'none', kycDocType: null, kycDocName: null, faceVerified: false);
    await _db.updateUser(_user!);
    notifyListeners();
  }

  // ── SECURITY ─────────────────────────────────────────────────────────────

  Future<void> toggleBiometrics() async {
    _user = _user!.copyWith(biometricsEnabled: !biometricsEnabled);
    await _db.updateUser(_user!);
    notifyListeners();
  }

  Future<void> toggle2FA() async {
    _user = _user!.copyWith(twoFactorEnabled: !twoFactorEnabled);
    await _db.updateUser(_user!);
    notifyListeners();
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final check = await _db.loginUser(userPhone, currentPin);
    if (check == null) return false;
    await _db.changePin(userId, newPin);
    await _db.addNotification(userId: userId, title: 'PIN modifié', content: 'Code PIN mis à jour.', type: 'security');
    await _refreshNotifications();
    return true;
  }

  Future<void> removeSession(int sessionId, String label) async {
    await _db.removeSession(sessionId);
    await _db.addNotification(userId: userId, title: 'Appareil révoqué', content: 'Session sur $label clôturée.', type: 'security');
    await _refreshData();
  }

  // Alias for backward compat
  Future<void> removeDevice(int sessionId, String label) => removeSession(sessionId, label);

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<void> addNotification(String title, String content, String type) async {
    await _db.addNotification(userId: userId, title: title, content: content, type: type);
    await _refreshNotifications();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.markNotificationRead(id);
    final i = notifications.indexWhere((n) => n.id == id);
    if (i != -1) { notifications[i].isRead = true; notifyListeners(); }
  }

  Future<void> markAllNotificationsAsRead() async {
    await _db.markAllNotificationsRead(userId);
    for (final n in notifications) n.isRead = true;
    notifyListeners();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  // ── CIRCLE ────────────────────────────────────────────────────────────────

  Future<String?> createCircle({
    required String name,
    required String description,
    required double target,
    required double contribution,
    required String frequency,
  }) async {
    if (name.trim().isEmpty) return 'Nom requis';
    await _db.createCircle(
      userId: userId,
      name: name.trim(),
      description: description,
      target: target,
      contribution: contribution,
      frequency: frequency,
    );
    await _refreshData();
    return null;
  }

  Future<void> updateCircle(CircleModel circle) async {
    await _db.updateCircle(circle);
    await _refreshData();
  }

  Future<void> deleteCircle(int circleId) async {
    await _db.deleteCircle(circleId);
    await _refreshData();
  }

  Future<String?> addCircleMember({
    required int circleId,
    required String name,
    required String phone,
    String walletId = '',
  }) async {
    if (name.trim().isEmpty) return 'Nom requis';
    await _db.addCircleMember(
      circleId: circleId,
      name: name.trim(),
      phone: phone.trim(),
      walletId: walletId,
    );
    circles = await _db.getCircles(userId);
    notifyListeners();
    return null;
  }

  Future<void> removeCircleMember(int memberId) async {
    await _db.removeCircleMember(memberId);
    circles = await _db.getCircles(userId);
    notifyListeners();
  }

  Future<bool> contributeToCircle(int circleId, int memberId, double amount, String asset) async {
    final slot = activeSlot;
    if (slot == null) return false;
    if (slot.balance < amount) return false;

    final ok = await _db.sendMoney(
      userId: userId, slotId: slot.id!, recipient: 'Tontine', amount: amount, method: 'standard',
    );
    if (!ok) return false;
    await _db.markMemberPaid(circleId, memberId, amount);
    await _db.addNotification(
      userId: userId, title: 'Tontine versée',
      content: 'Versement de ${amount.toStringAsFixed(0)} XOF confirmé.', type: 'success',
    );
    await _refreshData();
    return true;
  }

  // ── BILLS ─────────────────────────────────────────────────────────────────

  Future<bool> payBill({
    required String provider,
    required String reference,
    required double amount,
    String asset = 'XOF',
  }) async {
    final slot = activeSlot;
    if (slot == null) return false;
    final ok = await _db.payBill(
      userId: userId,
      slotId: slot.id!,
      provider: provider,
      reference: reference,
      amount: amount,
    );
    if (ok) await _refreshData();
    return ok;
  }

  // ── SETTINGS ─────────────────────────────────────────────────────────────

  Future<void> changeLanguage(String lang) async {
    _user = _user!.copyWith(language: lang);
    await _db.updateUser(_user!);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    if (_user != null) {
      _user = _user!.copyWith(themeMode: _themeMode == ThemeMode.dark ? 'dark' : 'light');
      await _db.updateUser(_user!);
    }
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

  Future<void> _refreshNotifications() async {
    if (_user == null) return;
    notifications = await _db.getNotifications(userId);
    notifyListeners();
  }
}
