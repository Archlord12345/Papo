import 'dart:math';
import '../database/database_helper.dart';

/// Generates and validates a 6-digit OTP stored locally in SQLite.
/// OTP expires after 10 minutes.
class OtpService {
  final _db = DatabaseHelper.instance;
  static const _ttlMinutes = 10;

  /// Generates a secure 6-digit code, saves it to DB, returns the code.
  Future<String> generate(int userId) async {
    // Invalidate any previous unused OTP for this user
    await _db.rawExecute(
        'UPDATE otp_codes SET used = 1 WHERE user_id = ? AND used = 0',
        [userId]);

    final code = _randomCode();
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: _ttlMinutes))
        .toIso8601String();

    await _db.insert('otp_codes', {
      'user_id': userId,
      'code': code,
      'expires_at': expiresAt,
      'used': 0,
    });

    return code;
  }

  /// Returns true if the code matches and is not expired or used.
  Future<bool> verify(int userId, String code) async {
    final now = DateTime.now().toIso8601String();
    final rows = await _db.query(
      'otp_codes',
      where: 'user_id = ? AND code = ? AND used = 0 AND expires_at > ?',
      whereArgs: [userId, code, now],
    );

    if (rows.isEmpty) return false;

    // Mark as used
    await _db.dbUpdate('otp_codes', {'used': 1}, 'id = ?', [rows.first['id']]);
    return true;
  }

  static String _randomCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }
}
