import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  final PocketBase pb = PocketBase(AppConfig.pocketBaseUrl);

  // --- Auth Methods ---

  Future<RecordModel?> getCurrentUser() async {
    if (pb.authStore.isValid) {
      return pb.authStore.model as RecordModel?;
    }
    return null;
  }

  Future<RecordModel> register({
    required String fullName,
    required String phone,
    required String pin,
  }) async {
    // PocketBase auth users require a username/email and password.
    // We'll use the phone as username and pin as password for simplicity.
    final body = {
      'username': phone.replaceAll(' ', '').replaceAll('+', ''),
      'password': pin,
      'passwordConfirm': pin,
      'name': fullName,
      'phone': phone,
      'pin': pin,
    };

    final record = await pb.collection('papo_users').create(body: body);

    // Auto login after registration
    await login(phone: phone, pin: pin);

    return record;
  }

  Future<RecordModel> login({
    required String phone,
    required String pin,
  }) async {
    final username = phone.replaceAll(' ', '').replaceAll('+', '');
    final authData = await pb.collection('papo_users').authWithPassword(
      username,
      pin,
    );
    return authData.record;
  }

  Future<void> logout() async {
    pb.authStore.clear();
  }

  Future<void> updatePassword({
    required String currentPin,
    required String newPin,
  }) async {
    if (pb.authStore.model == null) throw Exception("User not logged in");
    final userId = (pb.authStore.model as RecordModel).id;

    await pb.collection('papo_users').update(
      userId,
      body: {
        'password': newPin,
        'passwordConfirm': newPin,
        'pin': newPin,
      },
    );
  }

  // --- Profile / Prefs ---

  Future<Map<String, dynamic>> getPrefs() async {
    if (pb.authStore.model == null) return {};
    final user = pb.authStore.model as RecordModel;
    return user.toJson();
  }

  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    if (pb.authStore.model == null) return;
    final user = pb.authStore.model as RecordModel;

    // Map some prefs back to user record if they match schema
    final body = <String, dynamic>{};
    if (prefs.containsKey('userName')) body['name'] = prefs['userName'];
    if (prefs.containsKey('userPhone')) body['phone'] = prefs['userPhone'];
    // Other prefs could be stored in a separate collection or JSON field if added to schema
    // For now, we update what we can in the user record.

    if (body.isNotEmpty) {
      await pb.collection('papo_users').update(user.id, body: body);
    }
  }

  // --- Wallets ---

  Future<List<RecordModel>> getWallets() async {
    return await pb.collection('papo_wallets').getFullList(
      filter: 'user = "${pb.authStore.model?.id}"',
    );
  }

  Future<RecordModel> createWallet({
    required String address,
    required String currency,
    double balance = 0,
  }) async {
    final body = {
      'user': pb.authStore.model?.id,
      'address': address,
      'currency': currency,
      'balance': balance,
    };
    return await pb.collection('papo_wallets').create(body: body);
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    await pb.collection('papo_wallets').update(walletId, body: {
      'balance': newBalance,
    });
  }

  // --- Transactions ---

  Future<List<RecordModel>> getTransactions() async {
    final userId = pb.authStore.model?.id;
    return await pb.collection('papo_transactions').getFullList(
      filter: 'sender = "$userId" || receiver = "$userId"',
      sort: '-created',
    );
  }

  Future<RecordModel> createTransaction({
    required String receiverId,
    required double amount,
    required String type,
    String status = 'completed',
  }) async {
    final body = {
      'sender': pb.authStore.model?.id,
      'receiver': receiverId,
      'amount': amount,
      'type': type,
      'status': status,
    };
    return await pb.collection('papo_transactions').create(body: body);
  }

  // --- Notifications ---

  Future<List<RecordModel>> getNotifications() async {
    return await pb.collection('papo_notifications').getFullList(
      filter: 'user = "${pb.authStore.model?.id}"',
      sort: '-created',
    );
  }

  Future<void> markNotificationRead(String notificationId, bool read) async {
    await pb.collection('papo_notifications').update(notificationId, body: {
      'read': read,
    });
  }

  // --- KYC ---

  Future<RecordModel?> getKycStatus() async {
    try {
      return await pb.collection('papo_kyc').getFirstListItem(
        'user = "${pb.authStore.model?.id}"',
      );
    } catch (_) {
      return null;
    }
  }

  Future<RecordModel> uploadKycDocument({
    required String status,
    PlatformFile? file,
  }) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) throw Exception("User not logged in");

    // Check if record exists
    RecordModel? existing = await getKycStatus();

    final body = {
      'user': userId,
      'status': status,
    };

    List<http.MultipartFile> files = [];
    if (file != null) {
      if (file.bytes != null) {
        files.add(http.MultipartFile.fromBytes(
          'document',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        files.add(await http.MultipartFile.fromPath(
          'document',
          file.path!,
        ));
      }
    }

    if (existing == null) {
      return await pb.collection('papo_kyc').create(body: body, files: files);
    } else {
      return await pb.collection('papo_kyc').update(existing.id, body: body, files: files);
    }
  }

  // --- Devices ---

  Future<List<RecordModel>> getDevices() async {
    return await pb.collection('papo_devices').getFullList(
      filter: 'user = "${pb.authStore.model?.id}"',
    );
  }

  Future<RecordModel> registerDevice(String deviceId) async {
    final body = {
      'user': pb.authStore.model?.id,
      'device_id': deviceId,
    };
    return await pb.collection('papo_devices').create(body: body);
  }
}
