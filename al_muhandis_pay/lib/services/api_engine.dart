import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hmac_interceptor.dart';
import '../screens/force_update_screen.dart';

class ApiEngine {
  static final ApiEngine _instance = ApiEngine._internal();
  factory ApiEngine() => _instance;
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _hmacSecret = 'AlMuhandis_HMAC_Secret_2026_!@#\$%^&*';
  static const String currentAppVersion = '1.0.0';

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  ApiEngine._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://al-muhandis.com/api',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Client-Platform': 'Al-Muhandis-Secure-Core',
        'X-App-Version': currentAppVersion,
      },
    ));

    dio.interceptors.add(HmacInterceptor(secretKey: _hmacSecret));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 426) {
          final data = e.response?.data;
          final updateUrl = data is Map ? (data['update_url'] ?? 'https://al-muhandis.com/download/app.apk') : 'https://al-muhandis.com/download/app.apk';
          final isMaintenance = data is Map ? (data['maintenance'] == true) : false;
          _triggerKillSwitch(updateUrl, isMaintenance);
        }
        return handler.next(e);
      }
    ));
  }

  void _triggerKillSwitch(String updateUrl, bool isMaintenance) {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ForceUpdateScreen(
            updateUrl: updateUrl,
            isMaintenance: isMaintenance,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> pingForVersionCheck() async {
    try {
      await dio.get('/app-config');
    } catch (e) {}
  }

  Future<void> clearAuth() async {
    await storage.delete(key: 'jwt_token');
  }

  Future<Response> login(String username, String password) async {
    return await dio.post('/login', data: {'username': username, 'password': password});
  }

  Future<Response> verifyEmail(String ticket, String code) async {
    return await dio.post('/verify-email', data: {'auth_ticket': ticket, 'email_otp': code});
  }

  Future<Response> verifyGoogle(String ticket, String code) async {
    return await dio.post('/verify-google', data: {'auth_ticket': ticket, 'google_code': code});
  }

  // 💸 دالة التحويل السيادية
  Future<Map<String, dynamic>> sendTransfer(String receiverId, double amount, String description) async {
    try {
      final res = await dio.post('/transfer', data: {
        'receiver_id': receiverId,
        'amount': amount,
        'description': description
      });
      return {'success': true, 'message': res.data['message'] ?? 'تم التحويل بنجاح'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل التحويل'};
    } catch (e) {
      return {'success': false, 'message': 'حدث خطأ أثناء الاتصال'};
    }
  }
}
