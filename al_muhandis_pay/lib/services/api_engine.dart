import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiEngine {
  static final ApiEngine _instance = ApiEngine._internal();
  factory ApiEngine() => _instance;
  
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiEngine._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://al-muhandis.com/api',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json', 'X-Client-Platform': 'Al-Muhandis-Secure-Core'}
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final nonce = base64Encode(utf8.encode(timestamp + 'AlMuhandisBankSecret2026'));
        options.headers['X-Request-Timestamp'] = timestamp;
        options.headers['X-Request-Nonce'] = nonce;
        
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // لا نمسح الخزنة هنا في الـ login لأن 401 قد تعني باسورد خطأ
          // سنترك معالجة 401 للشاشات
        }
        return handler.next(e);
      }
    ));
  }

  // دوال الـ 3FA
  Future<Response> login(String username, String password) async {
    return await dio.post('/login', data: {"username": username, "password": password});
  }
  Future<Response> verifyEmail(String ticket, String otp) async {
    return await dio.post('/verify-email', data: {"auth_ticket": ticket, "email_otp": otp});
  }
  Future<Response> verifyGoogle(String ticket, String code) async {
    return await dio.post('/verify-google', data: {"auth_ticket": ticket, "google_code": code});
  }

  // دوال النظام الأساسية
  Future<Response> getWallet() async => await dio.get('/wallet');
  
  Future<Map<String, dynamic>> sendTransfer(String receiverId, double amount, String desc) async {
    try {
      final res = await dio.post('/transfer', data: {"receiver_id": receiverId, "amount": amount, "description": desc});
      if (res.statusCode == 200) return {"success": true, "message": "✅ تم التشفير وإرسال الحوالة بنجاح."};
      return {"success": false, "message": "❌ فشل بروتوكول التحويل."};
    } on DioException catch (e) {
      return {"success": false, "message": e.response?.data['message'] ?? 'فشل الاتصال الآمن بالسيرفر'};
    } catch (e) {
      return {"success": false, "message": "🚨 خطأ داخلي حرج."};
    }
  }

  Future<void> clearAuth() async => await storage.deleteAll();
}
