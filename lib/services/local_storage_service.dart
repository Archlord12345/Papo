import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _pairingsKey = 'papo_pairings_v1';
  static const _offlineBackupKey = 'papo_offline_queue_backup_v1';

  Future<List<Map<String, dynamic>>> loadPairings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pairingsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Future<void> savePairings(List<Map<String, dynamic>> pairings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pairingsKey, jsonEncode(pairings));
  }

  Future<void> saveOfflineQueueBackup(List<Map<String, dynamic>> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlineBackupKey, jsonEncode(transactions));
  }
}
