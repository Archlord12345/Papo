import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';

class AppwriteService {
  AppwriteService()
      : _client = Client()
          ..setEndpoint(AppwriteConfig.endpoint)
          ..setProject(AppwriteConfig.projectId);

  final Client _client;

  late final Account _account = Account(_client);
  late final Storage _storage = Storage(_client);

  String phoneToEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@papo.app';
  }

  String pinToPassword(String pin) {
    return 'papo::$pin';
  }

  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<Map<String, dynamic>> getPrefs() async {
    final prefs = await _account.getPrefs();
    final dynamic data = prefs.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    await _account.updatePrefs(prefs: prefs);
  }

  Future<models.User> register({
    required String fullName,
    required String phone,
    required String pin,
  }) async {
    final email = phoneToEmail(phone);
    final password = pinToPassword(pin);

    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: fullName,
    );

    return login(phone: phone, pin: pin);
  }

  Future<models.User> login({
    required String phone,
    required String pin,
  }) async {
    final email = phoneToEmail(phone);
    final password = pinToPassword(pin);

    await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );

    return _account.get();
  }

  Future<void> logout() async {
    await _account.deleteSession(sessionId: 'current');
  }

  Future<void> updatePassword({
    required String currentPin,
    required String newPin,
  }) async {
    await _account.updatePassword(
      password: pinToPassword(newPin),
      oldPassword: pinToPassword(currentPin),
    );
  }

  Future<String> uploadUserFile(PlatformFile file) async {
    late final InputFile inputFile;

    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('Aucun contenu fichier disponible pour le web.');
      }
      inputFile = InputFile.fromBytes(
        bytes: file.bytes!,
        filename: file.name,
      );
    } else {
      if (file.path == null || file.path!.isEmpty) {
        throw Exception('Chemin de fichier invalide.');
      }
      inputFile = InputFile(path: file.path!, filename: file.name);
    }

    final uploaded = await _storage.createFile(
      bucketId: AppwriteConfig.userDataBucketId,
      fileId: ID.unique(),
      file: inputFile,
    );

    return uploaded.$id;
  }
}
