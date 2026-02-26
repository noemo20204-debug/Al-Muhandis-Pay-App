import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hmac_interceptor.dart';

class ApiEngine {
  static final ApiEngine _instance = ApiEngine._internal();
  factory ApiEngine() => _instance;
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _hmacSecret = 'AlMuhandis_HMAC_Secret_2026_!@#\$%^&*';

  ApiEngine._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://al-muhandis.com/api',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Client-Platform': 'Al-Muhandis-Secure-Core',
      },
    ));

    // ─── الدرع 1: المصادقة و Anti-Replay ───
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
    ));

    // ─── الدرع 2: التوقيع المشفر (HMAC) ───
    dio.interceptors.add(HmacInterceptor(secretKey: _hmacSecret));
  }

  Future<void> clearAuth() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'admin_name');
  }

  // ═══════════════════════════════════════════════════════════
  //  العمليات الأساسية (التي تم استردادها)
  // ═══════════════════════════════════════════════════════════

  Future<Response> login(String username, String password) async {
    return await dio.post('/login', data: {'username': username, 'password': password});
  }

  Future<Response> verifyEmail(String ticket, String code) async {
    return await dio.post('/verify-email', data: {'auth_ticket': ticket, 'email_otp': code});
  }

  Future<Response> verifyGoogle(String ticket, String code) async {
    return await dio.post('/verify-google', data: {'auth_ticket': ticket, 'google_code': code});
  }

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
