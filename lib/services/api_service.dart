import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Add interceptors
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
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // --- AUTH ---
  Future<Map<String, dynamic>> register(String name, String phone, String pin, String? email) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'phone': phone,
        'pin': pin,
        'email': email,
      });
      return response.data;
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
      
      // Save token
      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- USERS ---
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- WALLETS ---
  Future<List<dynamic>> getWallets() async {
    try {
      final response = await _dio.get('/wallets');
      return response.data['wallets'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createWallet(String name, String deviceName, String asset) async {
    try {
      final response = await _dio.post('/wallets', data: {
        'name': name,
        'deviceName': deviceName,
        'asset': asset,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- TRANSACTIONS ---
  Future<List<dynamic>> getTransactions({int? page, int? limit, String? type, String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (page != null) params['page'] = page;
      if (limit != null) params['limit'] = limit;
      if (type != null) params['type'] = type;
      if (status != null) params['status'] = status;

      final response = await _dio.get('/transactions', queryParameters: params);
      return response.data['transactions'];
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
        'description': description,
        'method': method,
        'isOffline': isOffline,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- UPLOAD ---
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _dio.post('/upload/single', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- KYC ---
  Future<Map<String, dynamic>> submitKyc(String docType, String docImageUrl, String? docNumber) async {
    try {
      final response = await _dio.post('/kyc/submit', data: {
        'docType': docType,
        'docImageUrl': docImageUrl,
        'docNumber': docNumber,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- CIRCLES ---
  Future<List<dynamic>> getCircles() async {
    try {
      final response = await _dio.get('/circles');
      return response.data['circles'];
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
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- ERROR HANDLER ---
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data['error'] != null) {
        return data['error'];
      }
      return 'Erreur serveur (${error.response!.statusCode})';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Délai de connexion dépassé';
    } else if (error.type == DioExceptionType.sendTimeout) {
      return 'Délai d\'envoi dépassé';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Délai de réception dépassé';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Erreur de connexion';
    } else {
      return 'Une erreur est survenue';
    }
  }
}
