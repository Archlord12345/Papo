import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/wallet_slot_model.dart';
import '../models/transaction_model.dart';
import '../models/notification_model.dart';
import '../models/circle_model.dart';

const _uuid = Uuid();

String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
String nowIso() => DateTime.now().toIso8601String();

String _buildWalletId(String blockchainAddr, int slot) =>
    'PAPO-$blockchainAddr-$slot';

class DbService {
  final _db = DatabaseHelper.instance;

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<bool> phoneExists(String phone) async {
    final r = await _db.queryFirst('users', where: 'phone = ?', whereArgs: [phone]);
    return r != null;
  }

  Future<UserModel> createUser({
    required String name,
    required String phone,
    required String pin,
  }) async {
    final addrRaw = sha256.convert(utf8.encode(phone)).toString().substring(0, 16).toUpperCase();
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.map((p) => p[0].toUpperCase()).take(2).join();

    final user = UserModel(
      name: name,
      phone: phone,
      pinHash: hashPin(pin),
      blockchainAddr: addrRaw,
      initials: initials,
      createdAt: nowIso(),
    );

    final uid = await _db.insert('users', user.toMap());
    final created = user.copyWith(id: uid);

    // Create default wallet slot 0 (always active)
    await _createWalletSlot(
      userId: uid,
      slot: 0,
      blockchainAddr: addrRaw,
      name: 'Wallet Principal',
      deviceName: 'Appareil Principal',
      isActive: true,
    );

    // Seed session
    await _db.insert('sessions', {
      'user_id': uid,
      'label': 'Appareil Principal',
      'peer_id': _uuid.v4(),
      'is_current': 1,
      'last_seen': nowIso(),
    });

    // Seed default circle
    final circleId = await _db.insert('circles', {
      'user_id': uid,
      'name': 'Cercle Familial',
      'description': 'Tontine mensuelle',
      'target': 500000.0,
      'collected': 300000.0,
      'contribution': 100000.0,
      'turn_month': 'Ce mois',
      'frequency': 'monthly',
      'created_at': nowIso(),
    });
    for (final m in [
      {'name': '$name (Vous)', 'phone': phone, 'wallet_id': _buildWalletId(addrRaw, 0), 'paid': 1, 'paid_date': '2024-05-22'},
      {'name': 'Fatou Sy', 'phone': '+225 07 00 00 01', 'wallet_id': '', 'paid': 1, 'paid_date': '2024-05-20'},
      {'name': 'Kouassi Yao', 'phone': '+225 07 00 00 02', 'wallet_id': '', 'paid': 1, 'paid_date': '2024-05-19'},
      {'name': 'Awa Diop', 'phone': '+225 07 00 00 03', 'wallet_id': '', 'paid': 0, 'paid_date': null},
      {'name': 'Ousmane Koné', 'phone': '+225 07 00 00 04', 'wallet_id': '', 'paid': 0, 'paid_date': null},
    ]) {
      await _db.insert('circle_members', {
        'circle_id': circleId,
        'name': m['name'],
        'phone': m['phone'],
        'wallet_id': m['wallet_id'],
        'paid': m['paid'],
        'paid_date': m['paid_date'],
      });
    }

    await _addNotif(uid, 'Bienvenue !',
        'Merci de rejoindre PAYPOINT. 1 000 PAPO + 5 000 XOF crédités sur votre Wallet Principal.',
        'success');

    return created;
  }

  Future<UserModel?> loginUser(String phone, String pin) async {
    final r = await _db.queryFirst('users',
        where: 'phone = ? AND pin_hash = ?', whereArgs: [phone, hashPin(pin)]);
    return r == null ? null : UserModel.fromMap(r);
  }

  Future<UserModel?> getUserById(int id) async {
    final r = await _db.queryFirst('users', where: 'id = ?', whereArgs: [id]);
    return r == null ? null : UserModel.fromMap(r);
  }

  Future<void> updateUser(UserModel user) async {
    await _db.dbUpdate('users', user.toMap(), 'id = ?', [user.id]);
  }

  Future<void> changePin(int userId, String newPin) async {
    await _db.dbUpdate('users', {'pin_hash': hashPin(newPin)}, 'id = ?', [userId]);
  }

  // ─── WALLET SLOTS ─────────────────────────────────────────────────────────

  Future<int> _createWalletSlot({
    required int userId,
    required int slot,
    required String blockchainAddr,
    required String name,
    required String deviceName,
    bool isActive = false,
  }) async {
    final walletId = _buildWalletId(blockchainAddr, slot);
    final slotId = await _db.insert('wallet_slots', {
      'user_id': userId,
      'slot': slot,
      'wallet_id': walletId,
      'name': name,
      'device_name': deviceName,
      'is_active': isActive ? 1 : 0,
      'created_at': nowIso(),
    });
    // Seed balances
    for (final entry in {'XOF': isActive ? 5000.0 : 0.0, 'USD': 0.0, 'PAPO': isActive ? 1000.0 : 0.0, 'BTC': 0.0}.entries) {
      await _db.insert('wallet_balances', {
        'slot_id': slotId,
        'asset': entry.key,
        'balance': entry.value,
      });
    }
    return slotId;
  }

  Future<List<WalletSlotModel>> getWalletSlots(int userId) async {
    final rows = await _db.query('wallet_slots',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'slot ASC');
    final slots = <WalletSlotModel>[];
    for (final r in rows) {
      final slot = WalletSlotModel.fromMap(r);
      final balRows = await _db.query('wallet_balances',
          where: 'slot_id = ?', whereArgs: [slot.id]);
      slot.balances = {for (final b in balRows) b['asset'] as String: (b['balance'] as num).toDouble()};
      slots.add(slot);
    }
    return slots;
  }

  Future<WalletSlotModel?> getActiveSlot(int userId) async {
    final r = await _db.queryFirst('wallet_slots',
        where: 'user_id = ? AND is_active = 1', whereArgs: [userId]);
    if (r == null) return null;
    final slot = WalletSlotModel.fromMap(r);
    final balRows = await _db.query('wallet_balances',
        where: 'slot_id = ?', whereArgs: [slot.id]);
    slot.balances = {for (final b in balRows) b['asset'] as String: (b['balance'] as num).toDouble()};
    return slot;
  }

  Future<void> setActiveSlot(int userId, int slotId) async {
    await _db.dbUpdate('wallet_slots', {'is_active': 0}, 'user_id = ?', [userId]);
    await _db.dbUpdate('wallet_slots', {'is_active': 1}, 'id = ?', [slotId]);
  }

  Future<WalletSlotModel?> createNewSlot({
    required int userId,
    required String blockchainAddr,
    required String name,
    required String deviceName,
  }) async {
    // Find next available slot
    final existing = await _db.query('wallet_slots',
        where: 'user_id = ?', whereArgs: [userId]);
    final usedSlots = existing.map((r) => r['slot'] as int).toSet();
    int? nextSlot;
    for (int i = 0; i <= 9; i++) {
      if (!usedSlots.contains(i)) { nextSlot = i; break; }
    }
    if (nextSlot == null) return null; // max 10 slots

    final slotId = await _createWalletSlot(
      userId: userId,
      slot: nextSlot,
      blockchainAddr: blockchainAddr,
      name: name,
      deviceName: deviceName,
    );
    return (await getWalletSlots(userId)).firstWhere((s) => s.id == slotId);
  }

  Future<void> updateSlotName(int slotId, String newName) async {
    await _db.dbUpdate('wallet_slots', {'name': newName}, 'id = ?', [slotId]);
  }

  Future<void> deleteSlot(int slotId) async {
    await _db.dbDelete('wallet_slots', 'id = ?', [slotId]);
  }

  Future<List<Map<String, dynamic>>> getDeviceCatalog() async {
    return _db.query('devices_catalog', orderBy: 'name ASC');
  }

  // ─── BALANCES ─────────────────────────────────────────────────────────────

  Future<double> getSlotBalance(int slotId, String asset) async {
    final r = await _db.queryFirst('wallet_balances',
        where: 'slot_id = ? AND asset = ?', whereArgs: [slotId, asset]);
    return r == null ? 0.0 : (r['balance'] as num).toDouble();
  }

  Future<void> setSlotBalance(int slotId, String asset, double value) async {
    await _db.rawExecute(
      'INSERT INTO wallet_balances (slot_id, asset, balance) VALUES (?, ?, ?) '
      'ON CONFLICT(slot_id, asset) DO UPDATE SET balance = excluded.balance',
      [slotId, asset, value],
    );
  }

  Future<void> adjustSlotBalance(int slotId, String asset, double delta) async {
    final current = await getSlotBalance(slotId, asset);
    await setSlotBalance(slotId, asset, current + delta);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────────────

  Future<TransactionModel> createTransaction({
    required int userId,
    required int slotId,
    required String title,
    required double amount,
    required String asset,
    required String type,
    String status = 'completed',
    String description = '',
    String recipient = '',
    String method = 'standard',
    bool isOffline = false,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      userId: userId,
      slotId: slotId,
      title: title,
      amount: amount,
      asset: asset,
      type: type,
      status: status,
      description: description,
      recipient: recipient,
      method: method,
      isOffline: isOffline,
      createdAt: nowIso(),
    );
    await _db.insert('transactions', tx.toMap());
    return tx;
  }

  Future<List<TransactionModel>> getTransactions(int userId, {int? slotId, int? limit}) async {
    String where = 'user_id = ?';
    List whereArgs = [userId];
    if (slotId != null) { where += ' AND slot_id = ?'; whereArgs.add(slotId); }
    final rows = await _db.query('transactions',
        where: where, whereArgs: whereArgs,
        orderBy: 'created_at DESC', limit: limit);
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getOfflineQueue(int userId) async {
    final rows = await _db.query('transactions',
        where: 'user_id = ? AND is_offline = 1 AND status = ?',
        whereArgs: [userId, 'pending'],
        orderBy: 'created_at DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> syncOfflineTransactions(int userId) async {
    await _db.rawExecute(
      'UPDATE transactions SET status = ?, is_offline = 0 '
      'WHERE user_id = ? AND is_offline = 1 AND status = ?',
      ['completed', userId, 'pending'],
    );
  }

  /// Full transfer: debit active slot, record tx. Returns false if insufficient funds.
  Future<bool> sendMoney({
    required int userId,
    required int slotId,
    required String recipient,
    required double amount,
    required String asset,
    String method = 'standard',
    bool isOffline = false,
  }) async {
    final balance = await getSlotBalance(slotId, asset);
    if (balance < amount) return false;
    await adjustSlotBalance(slotId, asset, -amount);
    await createTransaction(
      userId: userId,
      slotId: slotId,
      title: 'Transfert vers $recipient',
      amount: -amount,
      asset: asset,
      type: isOffline ? 'offline' : 'send',
      status: isOffline ? 'pending' : 'completed',
      description: isOffline
          ? 'Signé localement (${method.toUpperCase()})'
          : 'Transfert via ${method.toUpperCase()}',
      recipient: recipient,
      method: method,
      isOffline: isOffline,
    );
    return true;
  }

  Future<void> receiveMoney({
    required int userId,
    required int slotId,
    required double amount,
    required String asset,
    String senderLabel = 'Fonds reçus',
    String method = 'standard',
  }) async {
    await adjustSlotBalance(slotId, asset, amount);
    await createTransaction(
      userId: userId,
      slotId: slotId,
      title: senderLabel,
      amount: amount,
      asset: asset,
      type: 'receive',
      description: 'Reçu via ${method.toUpperCase()}',
      method: method,
    );
  }

  Future<void> topUp({
    required int userId,
    required int slotId,
    required double amount,
    required String asset,
  }) async {
    await adjustSlotBalance(slotId, asset, amount);
    await createTransaction(
      userId: userId,
      slotId: slotId,
      title: 'Dépôt $asset',
      amount: amount,
      asset: asset,
      type: 'deposit',
      description: 'Dépôt manuel',
    );
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Future<void> _addNotif(int userId, String title, String content, String type) async {
    await _db.insert('notifications', {
      'id': _uuid.v4(),
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type,
      'is_read': 0,
      'created_at': nowIso(),
    });
  }

  Future<void> addNotification({required int userId, required String title, required String content, String type = 'info'}) =>
      _addNotif(userId, title, content, type);

  Future<List<NotificationModel>> getNotifications(int userId) async {
    final rows = await _db.query('notifications',
        where: 'user_id = ?', whereArgs: [userId],
        orderBy: 'created_at DESC', limit: 100);
    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.dbUpdate('notifications', {'is_read': 1}, 'id = ?', [id]);
  }

  Future<void> markAllNotificationsRead(int userId) async {
    await _db.dbUpdate('notifications', {'is_read': 1}, 'user_id = ?', [userId]);
  }

  // ─── SESSIONS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSessions(int userId) async {
    return _db.query('sessions',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'last_seen DESC');
  }

  Future<void> addSession(int userId, String peerId, String label) async {
    final exists = await _db.queryFirst('sessions',
        where: 'user_id = ? AND peer_id = ?', whereArgs: [userId, peerId]);
    if (exists == null) {
      await _db.insert('sessions', {
        'user_id': userId,
        'label': label,
        'peer_id': peerId,
        'is_current': 0,
        'last_seen': nowIso(),
      });
    }
  }

  Future<void> removeSession(int sessionId) async {
    await _db.dbDelete('sessions', 'id = ?', [sessionId]);
  }

  // ─── CIRCLE (TONTINE) ─────────────────────────────────────────────────────

  Future<List<CircleModel>> getCircles(int userId) async {
    final rows = await _db.query('circles', where: 'user_id = ?', whereArgs: [userId]);
    final result = <CircleModel>[];
    for (final r in rows) {
      final circle = CircleModel.fromMap(r);
      final memberRows = await _db.query('circle_members',
          where: 'circle_id = ?', whereArgs: [circle.id]);
      circle.members = memberRows.map(CircleMember.fromMap).toList();
      result.add(circle);
    }
    return result;
  }

  Future<CircleModel> createCircle({
    required int userId,
    required String name,
    String description = '',
    required double target,
    required double contribution,
    String frequency = 'monthly',
  }) async {
    final id = await _db.insert('circles', {
      'user_id': userId,
      'name': name,
      'description': description,
      'target': target,
      'collected': 0.0,
      'contribution': contribution,
      'turn_month': '',
      'frequency': frequency,
      'created_at': nowIso(),
    });
    return CircleModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      target: target,
      contribution: contribution,
      frequency: frequency,
      createdAt: nowIso(),
    );
  }

  Future<void> updateCircle(CircleModel circle) async {
    await _db.dbUpdate('circles', circle.toMap(), 'id = ?', [circle.id]);
  }

  Future<void> deleteCircle(int circleId) async {
    await _db.dbDelete('circles', 'id = ?', [circleId]);
  }

  Future<CircleMember> addCircleMember({
    required int circleId,
    required String name,
    required String phone,
    String walletId = '',
  }) async {
    final id = await _db.insert('circle_members', {
      'circle_id': circleId,
      'name': name,
      'phone': phone,
      'wallet_id': walletId,
      'paid': 0,
    });
    return CircleMember(
        id: id, circleId: circleId, name: name, phone: phone, walletId: walletId);
  }

  Future<void> removeCircleMember(int memberId) async {
    await _db.dbDelete('circle_members', 'id = ?', [memberId]);
  }

  Future<void> markMemberPaid(int circleId, int memberId, double contribution) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    await _db.dbUpdate('circle_members',
        {'paid': 1, 'paid_date': now}, 'id = ?', [memberId]);
    await _db.rawExecute(
        'UPDATE circles SET collected = collected + ? WHERE id = ?',
        [contribution, circleId]);
  }

  // ─── BILLS ────────────────────────────────────────────────────────────────

  Future<bool> payBill({
    required int userId,
    required int slotId,
    required String provider,
    required String reference,
    required double amount,
    String asset = 'XOF',
  }) async {
    final balance = await getSlotBalance(slotId, asset);
    if (balance < amount) return false;

    await adjustSlotBalance(slotId, asset, -amount);
    await _db.insert('bill_payments', {
      'id': _uuid.v4(),
      'user_id': userId,
      'provider': provider,
      'reference': reference,
      'amount': amount,
      'asset': asset,
      'status': 'completed',
      'created_at': nowIso(),
    });
    await createTransaction(
      userId: userId,
      slotId: slotId,
      title: 'Facture $provider',
      amount: -amount,
      asset: asset,
      type: 'bill',
      description: '$provider — Réf: $reference',
      recipient: provider,
    );
    await _addNotif(userId, 'Facture payée',
        'Paiement de ${amount.toStringAsFixed(0)} $asset pour $provider confirmé.',
        'success');
    return true;
  }
}
