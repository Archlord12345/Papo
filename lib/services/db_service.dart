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
String _walletId(String addr, int slot) => 'PAPO-$addr-$slot';

class DbService {
  final _db = DatabaseHelper.instance;

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<bool> phoneExists(String phone) async {
    final r = await _db.queryFirst('users', where: 'phone = ?', whereArgs: [phone]);
    return r != null;
  }

  Future<UserModel> createUser({
    required String name,
    required String phone,
    required String pin,
  }) async {
    // Supprimer tout utilisateur existant pour respecter "un compte par appareil"
    final db = await _db.database;
    await db.delete('users');
    await db.delete('wallet_slots');
    await db.delete('transactions');
    await db.delete('circles');
    await db.delete('circle_members');
    await db.delete('sessions');

    final addr = sha256.convert(utf8.encode(phone)).toString().substring(0, 16).toUpperCase();
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.map((p) => p[0].toUpperCase()).take(2).join();

    final user = UserModel(
      name: name, phone: phone, pinHash: hashPin(pin),
      blockchainAddr: addr, initials: initials, createdAt: nowIso(),
    );

    final uid = await _db.insert('users', user.toMap());

    // Wallet slot 0 — balance initiale 5000 XOF
    await _db.insert('wallet_slots', {
      'user_id': uid, 'slot': 0, 'wallet_id': _walletId(addr, 0),
      'name': 'Wallet Principal', 'device_name': 'Appareil Principal',
      'is_active': 1, 'balance': 5000.0, 'created_at': nowIso(),
    });

    // Session courante
    await _db.insert('sessions', {
      'user_id': uid, 'label': 'Appareil Principal',
      'peer_id': _uuid.v4(), 'is_current': 1, 'last_seen': nowIso(),
    });

    // Tontine par défaut
    final circleId = await _db.insert('circles', {
      'user_id': uid, 'name': 'Cercle Familial', 'description': 'Tontine mensuelle',
      'target': 500000.0, 'collected': 300000.0, 'contribution': 100000.0,
      'turn_month': 'Ce mois', 'frequency': 'monthly', 'created_at': nowIso(),
    });
    for (final m in [
      {'name': '$name (Vous)', 'phone': phone, 'wallet_id': _walletId(addr, 0), 'paid': 1, 'paid_date': '2024-05-22'},
      {'name': 'Fatou Sy',     'phone': '+225 07 00 00 01', 'wallet_id': '', 'paid': 1, 'paid_date': '2024-05-20'},
      {'name': 'Kouassi Yao', 'phone': '+225 07 00 00 02', 'wallet_id': '', 'paid': 1, 'paid_date': '2024-05-19'},
      {'name': 'Awa Diop',    'phone': '+225 07 00 00 03', 'wallet_id': '', 'paid': 0, 'paid_date': null},
      {'name': 'Ousmane Koné','phone': '+225 07 00 00 04', 'wallet_id': '', 'paid': 0, 'paid_date': null},
    ]) {
      await _db.insert('circle_members', {
        'circle_id': circleId, 'name': m['name'], 'phone': m['phone'],
        'wallet_id': m['wallet_id'], 'paid': m['paid'], 'paid_date': m['paid_date'],
      });
    }

    await _addNotif(uid, 'Bienvenue !',
        'Bienvenue sur PAYPOINT. 5 000 XOF crédités sur votre Wallet Principal.', 'success');

    return user.copyWith(id: uid);
  }

  Future<UserModel?> loginUser(String phone, String pin) async {
    final r = await _db.queryFirst('users',
        where: 'phone = ? AND pin_hash = ?', whereArgs: [phone, hashPin(pin)]);
    return r == null ? null : UserModel.fromMap(r);
  }

  Future<UserModel?> getSavedUser() async {
    final r = await _db.queryFirst('users');
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

  // ── WALLET SLOTS ──────────────────────────────────────────────────────────

  Future<List<WalletSlotModel>> getWalletSlots(int userId) async {
    final rows = await _db.query('wallet_slots',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'slot ASC');
    return rows.map(WalletSlotModel.fromMap).toList();
  }

  Future<WalletSlotModel?> getActiveSlot(int userId) async {
    final r = await _db.queryFirst('wallet_slots',
        where: 'user_id = ? AND is_active = 1', whereArgs: [userId]);
    return r == null ? null : WalletSlotModel.fromMap(r);
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
    String asset = 'XOF',
  }) async {
    final existing = await _db.query('wallet_slots', where: 'user_id = ?', whereArgs: [userId]);
    final usedSlots = existing.map((r) => r['slot'] as int).toSet();
    int? nextSlot;
    for (int i = 0; i <= 9; i++) {
      if (!usedSlots.contains(i)) { nextSlot = i; break; }
    }
    if (nextSlot == null) return null;

    final id = await _db.insert('wallet_slots', {
      'user_id': userId, 'slot': nextSlot, 'wallet_id': _walletId(blockchainAddr, nextSlot),
      'name': name, 'device_name': deviceName, 'asset': asset, 'is_active': 0,
      'balance': 0.0, 'created_at': nowIso(),
    });
    final r = await _db.queryFirst('wallet_slots', where: 'id = ?', whereArgs: [id]);
    return r == null ? null : WalletSlotModel.fromMap(r);
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

  // ── BALANCE ───────────────────────────────────────────────────────────────

  Future<double> getBalance(int slotId) async {
    final r = await _db.queryFirst('wallet_slots', where: 'id = ?', whereArgs: [slotId]);
    return r == null ? 0.0 : (r['balance'] as num).toDouble();
  }

  Future<void> _setBalance(int slotId, double value) async {
    await _db.dbUpdate('wallet_slots', {'balance': value}, 'id = ?', [slotId]);
  }

  // ── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<TransactionModel> _createTx({
    required int userId, required int slotId, required String title,
    required double amount, required String type,
    String status = 'completed', String description = '',
    String recipient = '', String method = 'standard', bool isOffline = false,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(), userId: userId, slotId: slotId, title: title,
      amount: amount, asset: 'XOF', type: type, status: status,
      description: description, recipient: recipient,
      method: method, isOffline: isOffline, createdAt: nowIso(),
    );
    await _db.insert('transactions', tx.toMap());
    return tx;
  }

  Future<bool> sendMoney({
    required int userId, required int slotId, required String recipient,
    required double amount, String asset = 'XOF', String method = 'standard', bool isOffline = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    bool success = false;
    await db.transaction((txn) async {
      final rows = await txn.query('wallet_slots', where: 'id = ?', whereArgs: [slotId]);
      if (rows.isEmpty) return;
      final slotAsset = rows.first['asset'] as String;
      final balance = (rows.first['balance'] as num).toDouble();
      if (balance < amount) return;
      await txn.update('wallet_slots', {'balance': balance - amount}, where: 'id = ?', whereArgs: [slotId]);
      await txn.insert('transactions', {
        'id': _uuid.v4(), 'user_id': userId, 'slot_id': slotId,
        'title': 'Transfert vers $recipient', 'amount': -amount, 'asset': slotAsset, 'type': isOffline ? 'offline' : 'send',
        'status': isOffline ? 'pending' : 'completed',
        'description': isOffline ? 'Signé localement (${method.toUpperCase()})' : 'via ${method.toUpperCase()}',
        'recipient': recipient, 'method': method, 'is_offline': isOffline ? 1 : 0,
        'created_at': nowIso(),
      });
      success = true;
    });
    return success;
  }

  Future<void> receiveMoney({
    required int userId, required int slotId, required double amount,
    String asset = 'XOF', String senderLabel = 'Fonds reçus', String method = 'standard',
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query('wallet_slots', where: 'id = ?', whereArgs: [slotId]);
      if (rows.isEmpty) return;
      final slotAsset = rows.first['asset'] as String;
      final balance = (rows.first['balance'] as num).toDouble();
      await txn.update('wallet_slots', {'balance': balance + amount}, where: 'id = ?', whereArgs: [slotId]);
      await txn.insert('transactions', {
        'id': _uuid.v4(), 'user_id': userId, 'slot_id': slotId,
        'title': senderLabel, 'amount': amount, 'asset': slotAsset, 'type': 'receive',
        'status': 'completed', 'description': 'Reçu via ${method.toUpperCase()}',
        'recipient': '', 'method': method, 'is_offline': 0,
        'created_at': nowIso(),
      });
    });
  }

  Future<void> topUp({required int userId, required int slotId, required double amount, String asset = 'XOF'}) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      final rows = await txn.query('wallet_slots', where: 'id = ?', whereArgs: [slotId]);
      if (rows.isEmpty) return;
      final slotAsset = rows.first['asset'] as String;
      final balance = (rows.first['balance'] as num).toDouble();
      await txn.update('wallet_slots', {'balance': balance + amount}, where: 'id = ?', whereArgs: [slotId]);
      await txn.insert('transactions', {
        'id': _uuid.v4(), 'user_id': userId, 'slot_id': slotId,
        'title': 'Dépôt $slotAsset', 'amount': amount, 'asset': slotAsset, 'type': 'deposit',
        'status': 'completed', 'description': 'Dépôt manuel',
        'recipient': '', 'method': 'standard', 'is_offline': 0,
        'created_at': nowIso(),
      });
    });
  }

  Future<List<TransactionModel>> getTransactions(int userId, {int? slotId, int? limit}) async {
    String where = 'user_id = ?';
    List whereArgs = [userId];
    if (slotId != null) { where += ' AND slot_id = ?'; whereArgs.add(slotId); }
    final rows = await _db.query('transactions', where: where, whereArgs: whereArgs,
        orderBy: 'created_at DESC', limit: limit);
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getOfflineQueue(int userId) async {
    final rows = await _db.query('transactions',
        where: 'user_id = ? AND is_offline = 1 AND status = ?',
        whereArgs: [userId, 'pending'], orderBy: 'created_at DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> syncOfflineTransactions(int userId) async {
    await _db.rawExecute(
        'UPDATE transactions SET status = ?, is_offline = 0 WHERE user_id = ? AND is_offline = 1 AND status = ?',
        ['completed', userId, 'pending']);
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<void> _addNotif(int userId, String title, String content, String type) async {
    await _db.insert('notifications', {
      'id': _uuid.v4(), 'user_id': userId, 'title': title,
      'content': content, 'type': type, 'is_read': 0, 'created_at': nowIso(),
    });
  }

  Future<void> addNotification({required int userId, required String title, required String content, String type = 'info'}) =>
      _addNotif(userId, title, content, type);

  Future<List<NotificationModel>> getNotifications(int userId) async {
    final rows = await _db.query('notifications', where: 'user_id = ?', whereArgs: [userId],
        orderBy: 'created_at DESC', limit: 100);
    return rows.map(NotificationModel.fromMap).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.dbUpdate('notifications', {'is_read': 1}, 'id = ?', [id]);
  }

  Future<void> markAllNotificationsRead(int userId) async {
    await _db.dbUpdate('notifications', {'is_read': 1}, 'user_id = ?', [userId]);
  }

  // ── SESSIONS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSessions(int userId) async {
    return _db.query('sessions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'last_seen DESC');
  }

  Future<void> addSession(int userId, String peerId, String label) async {
    final exists = await _db.queryFirst('sessions',
        where: 'user_id = ? AND peer_id = ?', whereArgs: [userId, peerId]);
    if (exists == null) {
      await _db.insert('sessions', {
        'user_id': userId, 'label': label, 'peer_id': peerId, 'is_current': 0, 'last_seen': nowIso(),
      });
    }
  }

  Future<void> removeSession(int sessionId) async {
    await _db.dbDelete('sessions', 'id = ?', [sessionId]);
  }

  // ── CIRCLES ───────────────────────────────────────────────────────────────

  Future<List<CircleModel>> getCircles(int userId) async {
    final rows = await _db.query('circles', where: 'user_id = ?', whereArgs: [userId]);
    final result = <CircleModel>[];
    for (final r in rows) {
      final c = CircleModel.fromMap(r);
      final mRows = await _db.query('circle_members', where: 'circle_id = ?', whereArgs: [c.id]);
      c.members = mRows.map(CircleMember.fromMap).toList();
      result.add(c);
    }
    return result;
  }

  Future<CircleModel> createCircle({
    required int userId, required String name, String description = '',
    required double target, required double contribution, String frequency = 'monthly',
  }) async {
    final id = await _db.insert('circles', {
      'user_id': userId, 'name': name, 'description': description,
      'target': target, 'collected': 0.0, 'contribution': contribution,
      'turn_month': '', 'frequency': frequency, 'created_at': nowIso(),
    });
    return CircleModel(id: id, userId: userId, name: name, description: description,
        target: target, contribution: contribution, frequency: frequency, createdAt: nowIso());
  }

  Future<void> updateCircle(CircleModel c) async {
    await _db.dbUpdate('circles', c.toMap(), 'id = ?', [c.id]);
  }

  Future<void> deleteCircle(int id) async {
    await _db.dbDelete('circles', 'id = ?', [id]);
  }

  Future<CircleMember> addCircleMember({
    required int circleId, required String name, required String phone, String walletId = '',
  }) async {
    final id = await _db.insert('circle_members', {
      'circle_id': circleId, 'name': name, 'phone': phone, 'wallet_id': walletId, 'paid': 0,
    });
    return CircleMember(id: id, circleId: circleId, name: name, phone: phone, walletId: walletId);
  }

  Future<void> removeCircleMember(int id) async {
    await _db.dbDelete('circle_members', 'id = ?', [id]);
  }

  Future<void> markMemberPaid(int circleId, int memberId, double contribution) async {
    final now = DateTime.now().toIso8601String().substring(0, 10);
    await _db.dbUpdate('circle_members', {'paid': 1, 'paid_date': now}, 'id = ?', [memberId]);
    await _db.rawExecute('UPDATE circles SET collected = collected + ? WHERE id = ?', [contribution, circleId]);
  }

  // ── BILLS ─────────────────────────────────────────────────────────────────

  Future<bool> payBill({
    required int userId, required int slotId, required String provider,
    required String reference, required double amount,
  }) async {
    final db = await DatabaseHelper.instance.database;
    bool success = false;
    await db.transaction((txn) async {
      final rows = await txn.query('wallet_slots', where: 'id = ?', whereArgs: [slotId]);
      if (rows.isEmpty) return;
      final balance = (rows.first['balance'] as num).toDouble();
      if (balance < amount) return;
      await txn.update('wallet_slots', {'balance': balance - amount}, where: 'id = ?', whereArgs: [slotId]);
      await txn.insert('bill_payments', {
        'id': _uuid.v4(), 'user_id': userId, 'provider': provider,
        'reference': reference, 'amount': amount, 'status': 'completed', 'created_at': nowIso(),
      });
      await txn.insert('transactions', {
        'id': _uuid.v4(), 'user_id': userId, 'slot_id': slotId,
        'title': 'Facture $provider', 'amount': -amount, 'type': 'bill',
        'status': 'completed', 'description': '$provider — Réf: $reference',
        'recipient': provider, 'method': 'standard', 'is_offline': 0, 'created_at': nowIso(),
      });
      success = true;
    });
    if (success) {
      await _addNotif(userId, 'Facture payée',
          'Paiement de ${amount.toStringAsFixed(0)} XOF pour $provider confirmé.', 'success');
    }
    return success;
  }
}
