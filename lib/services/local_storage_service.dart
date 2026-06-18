import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _pairingsKey = 'papo_pairings_v1';
  static const _offlineBackupKey = 'papo_offline_queue_backup_v1';
  static const _userProfileKey = 'papo_user_profile_v1';
  static const _walletBalancesKey = 'papo_wallet_balances_v1';
  static const _transactionsKey = 'papo_transactions_v1';

  // --- User Profile ---
  Future<Map<String, dynamic>?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userProfileKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile));
  }

  // --- Wallet Balances ---
  Future<Map<String, double>> loadBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_walletBalancesKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<void> saveBalances(Map<String, double> balances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletBalancesKey, jsonEncode(balances));
  }

  // --- Transactions ---
  Future<List<Map<String, dynamic>>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transactionsKey, jsonEncode(transactions));
  }

  // --- Pairings & Offline ---
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
