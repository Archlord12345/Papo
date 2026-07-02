import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_info_service.dart';

class ApiService {
  static const String baseUrl = 'http://82.165.150.150:20080/api';
  static const String baseUrlLocal = 'http://localhost:20080/api';

  final Dio _dio = Dio();
  bool useLocalApi = false;

  ApiService() {
    _initializeDio();
  }

  String get currentBaseUrl => useLocalApi ? baseUrlLocal : baseUrl;

  Future<void> _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    useLocalApi = prefs.getBool('useLocalApi') ?? false;

    _dio.options.baseUrl = currentBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (error, handler) => handler.next(error),
    ));
  }

  // ─── ASSETS (Currencies) ───────────────────────────────────────────────────

  Future<List<dynamic>> getAssets() async {
    try {
      final response = await _dio.get('/assets');
      return response.data['assets'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(
      String name, String phone, String pin, String? email) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        'pin': pin,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login(String phone, String pin) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': phone,
        'pin': pin,
      });
      final token = response.data['token'] as String?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePin(String currentPin, String newPin) async {
    try {
      await _dio.post('/auth/change-pin', data: {
        'currentPin': currentPin,
        'newPin': newPin,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── WALLETS ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getWallets() async {
    try {
      final response = await _dio.get('/wallets');
      return response.data['wallets'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createWallet(
      String name, String deviceName, String asset) async {
    try {
      final response = await _dio.post('/wallets', data: {
        'name': name,
        'deviceName': deviceName,
        'assetCode': asset,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> setActiveWallet(int walletId) async {
    try {
      final response = await _dio.put('/wallets/$walletId/set-active');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateWallet(int walletId, String name) async {
    try {
      final response = await _dio.put('/wallets/$walletId', data: {'name': name});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteWallet(int walletId) async {
    try {
      await _dio.delete('/wallets/$walletId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getTransactions({
    int? page,
    int? limit,
    String? type,
    String? status,
    int? walletId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (page != null) params['page'] = page;
      if (limit != null) params['limit'] = limit;
      if (type != null) params['type'] = type;
      if (status != null) params['status'] = status;
      if (walletId != null) params['walletId'] = walletId;

      final response = await _dio.get('/transactions', queryParameters: params);
      return response.data['transactions'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendMoney({
    required String recipientPhone,
    required double amount,
    String? description,
    String method = 'STANDARD',
    bool isOffline = false,
  }) async {
    try {
      final response = await _dio.post('/transactions/send', data: {
        'recipientPhone': recipientPhone,
        'amount': amount,
        'description': description ?? '',
        'method': method.toUpperCase(),
        'isOffline': isOffline,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> syncOfflineTransactions() async {
    try {
      final response = await _dio.post('/transactions/sync-offline');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response.data['notifications'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── UPLOAD ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _dio.post('/upload/single', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadMultipleFiles(List<File> files) async {
    try {
      final formData = FormData.fromMap({});
      for (final file in files) {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path),
        ));
      }
      final response = await _dio.post('/upload/multiple', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── KYC ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitKyc(
      String docType, String docImageUrl, String? docNumber) async {
    try {
      final response = await _dio.post('/kyc/submit', data: {
        'docType': docType,
        'docImageUrl': docImageUrl,
        if (docNumber != null) 'docNumber': docNumber,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getMyKycReviews() async {
    try {
      final response = await _dio.get('/kyc/me');
      return response.data['reviews'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── CIRCLES ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getCircles() async {
    try {
      final response = await _dio.get('/circles');
      return response.data['circles'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createCircle({
    required String name,
    required String description,
    required double target,
    required double contribution,
    String frequency = 'monthly',
  }) async {
    try {
      final response = await _dio.post('/circles', data: {
        'name': name,
        'description': description,
        'target': target,
        'contribution': contribution,
        'frequency': frequency,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addCircleMember(
      int circleId, String name, String phone, String? walletId) async {
    try {
      final response = await _dio.post('/circles/$circleId/members', data: {
        'name': name,
        'phone': phone,
        if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteCircle(int circleId) async {
    try {
      await _dio.delete('/circles/$circleId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> markCircleMemberPaid(
      int circleId, int memberId, double amount) async {
    try {
      final response = await _dio.post(
        '/circles/$circleId/members/$memberId/pay',
        data: {'amount': amount},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── DISPUTES ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getMyDisputes() async {
    try {
      final response = await _dio.get('/disputes/my-disputes');
      return response.data['disputes'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createDispute({
    required String subject,
    required String category,
    required double amount,
    String? transactionId,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/disputes', data: {
        'subject': subject,
        'category': category,
        'amount': amount,
        if (transactionId != null) 'transactionId': transactionId,
        if (description != null) 'description': description,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── SUPPORT ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getMyTickets() async {
    try {
      final response = await _dio.get('/support/my-tickets');
      return response.data['tickets'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String category,
    required String message,
    String priority = 'MEDIUM',
  }) async {
    try {
      final response = await _dio.post('/support/tickets', data: {
        'subject': subject,
        'category': category,
        'message': message,
        'priority': priority,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getTicketMessages(String ticketId) async {
    try {
      final response = await _dio.get('/support/tickets/$ticketId/messages');
      return response.data['messages'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendTicketMessage(
      String ticketId, String content) async {
    try {
      final response = await _dio.post(
        '/support/tickets/$ticketId/messages',
        data: {'content': content},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ADMIN ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final response = await _dio.get('/stats/dashboard');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await _dio.get('/users');
      return List<Map<String, dynamic>>.from(response.data['users'] as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> adminUpdateUser(int userId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/users/$userId', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getKycQueue() async {
    try {
      final response = await _dio.get('/kyc/reviews', queryParameters: {'status': 'PENDING'});
      return List<Map<String, dynamic>>.from(response.data['reviews'] as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> adminReviewKyc(int reviewId, String status, String? notes) async {
    try {
      await _dio.put('/kyc/reviews/$reviewId', data: {
        'status': status,
        if (notes != null) 'notes': notes,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAdminDisputes() async {
    try {
      final response = await _dio.get('/disputes');
      return List<Map<String, dynamic>>.from(response.data['disputes'] as List);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> adminUpdateDispute(String disputeId, String status, String? resolution) async {
    try {
      await _dio.put('/disputes/$disputeId', data: {
        'status': status,
        if (resolution != null) 'resolutionNotes': resolution,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── ERROR HANDLER ─────────────────────────────────────────────────────────

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return 'Erreur serveur (${error.response!.statusCode})';
    }
    return 'Une erreur est survenue';
  }
}
