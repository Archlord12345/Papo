import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
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
    int? customId,
  }) async {
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
      id: customId,
      name: name, phone: phone, pinHash: hashPin(pin),
      blockchainAddr: addr, initials: initials, createdAt: nowIso(),
    );

    final uid = await _db.insert('users', user.toMap());

    // Default Wallet
    await _db.insert('wallet_slots', {
      'user_id': uid, 'slot': 0, 'wallet_id': _walletId(addr, 0),
      'name': 'Wallet Principal', 'device_name': 'Appareil Principal',
      'asset': 'PAPO', 'is_active': 1, 'balance': 5000.0, 'created_at': nowIso(),
    });

    return user.copyWith(id: uid);
  }

  Future<UserModel?> getSavedUser() async {
    final r = await _db.queryFirst('users');
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

  Future<void> updateSlotBalance(String walletId, double balance) async {
    await _db.dbUpdate('wallet_slots', {'balance': balance}, 'wallet_id = ?', [walletId]);
  }

  // ── TRANSACTIONS ──────────────────────────────────────────────────────────

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

  Future<void> addNotification({required int userId, required String title, required String content, String type = 'info'}) async {
    await _db.insert('notifications', {
      'id': _uuid.v4(), 'user_id': userId, 'title': title,
      'content': content, 'type': type, 'is_read': 0, 'created_at': nowIso(),
    });
  }

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

  // ── SYNC HELPERS ──────────────────────────────────────────────────────────

  Future<void> syncWallets(int userId, List<dynamic> remoteWallets) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Clear old wallets for this user first
      await txn.delete('wallet_slots', where: 'user_id = ?', whereArgs: [userId]);

      for (final w in remoteWallets) {
        await txn.insert('wallet_slots', {
          'user_id': userId,
          'remote_id': w['id'],
          'slot': w['slot'],
          'wallet_id': w['walletId'],
          'name': w['name'],
          'device_name': w['deviceName'],
          'asset': w['asset'] ?? 'PAPO',
          'is_active': (w['isActive'] as bool) ? 1 : 0,
          'balance': (w['balance'] as num).toDouble(),
          'created_at': w['createdAt'],
        });
      }
    });
  }

  Future<void> syncTransactions(int userId, List<dynamic> remoteTxs) async {
    final db = await _db.database;
    final wallets = await getWalletSlots(userId);

    await db.transaction((txn) async {
      // Clear old transactions for this user first
      await txn.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);

      for (final t in remoteTxs) {
        final tx = TransactionModel.fromJson(t);

        int localSlotId = 0;
        final matchingWallet = wallets.where((w) {
          return w.remoteId == tx.slotId;
        }).toList();

        if (matchingWallet.isNotEmpty) {
          localSlotId = matchingWallet.first.id!;
        }

        await txn.insert('transactions', {
          'id': tx.id,
          'user_id': userId,
          'slot_id': localSlotId,
          'title': tx.title,
          'amount': tx.amount,
          'type': tx.type,
          'status': tx.status.toLowerCase(),
          'description': tx.description,
          'recipient': tx.recipient,
          'method': tx.method,
          'is_offline': tx.isOffline ? 1 : 0,
          'created_at': tx.createdAt,
        });
      }
    });
  }

  Future<void> syncCircles(int userId, List<dynamic> remoteCircles) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Clear old circles and members first
      await txn.delete('circle_members', where: 'circle_id IN (SELECT id FROM circles WHERE user_id = ?)', whereArgs: [userId]);
      await txn.delete('circles', where: 'user_id = ?', whereArgs: [userId]);

      for (final c in remoteCircles) {
        await txn.insert('circles', {
          'id': c['id'],
          'user_id': userId,
          'name': c['name'],
          'description': c['description'] ?? '',
          'target': (c['target'] as num).toDouble(),
          'collected': (c['collected'] as num).toDouble(),
          'contribution': (c['contribution'] as num).toDouble(),
          'turn_month': c['turnMonth'] ?? '',
          'frequency': c['frequency'] ?? 'monthly',
          'created_at': c['createdAt'],
        });

        if (c['members'] != null) {
          for (final m in c['members']) {
            await txn.insert('circle_members', {
              'id': m['id'],
              'circle_id': c['id'],
              'name': m['name'],
              'phone': m['phone'],
              'wallet_id': m['walletId'] ?? '',
              'paid': (m['paid'] as bool) ? 1 : 0,
              'paid_date': m['paidDate'],
            });
          }
        }
      }
    });
  }

  Future<void> syncNotifications(int userId, List<dynamic> remoteNotifs) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Clear old notifications first
      await txn.delete('notifications', where: 'user_id = ?', whereArgs: [userId]);

      for (final n in remoteNotifs) {
        await txn.insert('notifications', {
          'id': n['id'],
          'user_id': userId,
          'title': n['title'],
          'content': n['content'],
          'type': (n['type'] as String).toLowerCase(),
          'is_read': (n['isRead'] as bool) ? 1 : 0,
          'created_at': n['createdAt'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSessions(int userId) async {
    return _db.query('sessions', where: 'user_id = ?', whereArgs: [userId], orderBy: 'last_seen DESC');
  }
}
