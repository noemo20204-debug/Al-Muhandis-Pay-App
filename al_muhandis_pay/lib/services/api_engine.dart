import 'dart:convert';
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
  
  // 🎯 رقم الإصدار الحالي لتطبيقك (قم بزيادته عند كل تحديث ترفعه للمتجر)
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
        'X-App-Version': currentAppVersion, // 🛡️ ختم الإصدار يُرسل مع كل نبضة
      },
    ));

    // ─── الدرع 1: المصادقة و مقصلة البنك المركزي (Error 426) ───
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
        // 🚨 التقاط حكم الإعدام للإصدارات القديمة أو حالة الصيانة
        if (e.response?.statusCode == 426) {
          final data = e.response?.data;
          final updateUrl = data?['update_url'] ?? 'https://al-muhandis.com/download/app.apk';
          final isMaintenance = data?['maintenance'] == true;

          _triggerKillSwitch(updateUrl, isMaintenance);
        }
        return handler.next(e);
      }
    ));

    // ─── الدرع 2: التوقيع المشفر (HMAC) ───
    dio.interceptors.add(HmacInterceptor(secretKey: _hmacSecret));
  }

  // 🗡️ تنفيذ حكم الإعدام: تدمير كل الشاشات وفتح شاشة التحديث الإجباري
  void _triggerKillSwitch(String updateUrl, bool isMaintenance) {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ForceUpdateScreen(
            updateUrl: updateUrl,
            isMaintenance: isMaintenance,
          ),
        ),
        (Route<dynamic> route) => false, // هذا السطر يمنع العميل من الرجوع للخلف نهائياً
      );
    }
  }

  // 📡 إرسال نبضة للسيرفر عند العودة من الخلفية لاصطياد الـ 426
  Future<void> pingForVersionCheck() async {
    try {
      await dio.get('/app-config');
    } catch (e) {
      // سيتم تجاهل الأخطاء العادية بصمت، لأن الـ onError بالأعلى سيتكفل بالـ 426
    }
  }

  Future<void> clearAuth() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'admin_name');
  }

  // ═══════════════════════════════════════════════════════════
  //  العمليات الأساسية
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
