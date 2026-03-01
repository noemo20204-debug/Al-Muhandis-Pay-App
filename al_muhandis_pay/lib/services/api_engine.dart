import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hmac_interceptor.dart';
import '../screens/force_update_screen.dart';

/// ═══════════════════════════════════════════════════════════════
///  Al-Muhandis Pay — محرك الاتصالات السيادي v2.0 (مُحَصَّن)
///  الملف: lib/services/api_engine.dart
/// ═══════════════════════════════════════════════════════════════
///  التحديثات في v2.0:
///   ✅ إزالة المفتاح المكتوب كنص صريح (Hardcoded HMAC Secret)
///   ✅ إزالة Fallback على SharedPreferences (غير مشفر!)
///   ✅ التوكن يُخزَّن فقط في FlutterSecureStorage
///   ✅ دعم مفتاح الجلسة المؤقت (Session HMAC Key) بعد Login
///   ✅ دعم تسجيل الخروج الكامل (مسح كل البيانات الحساسة)
/// ═══════════════════════════════════════════════════════════════

class ApiEngine {
  static final ApiEngine _instance = ApiEngine._internal();
  factory ApiEngine() => _instance;
  late Dio dio;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  FlutterSecureStorage get storage => _secureStorage;
  late final HmacInterceptor _hmacInterceptor;

  static const String currentAppVersion = '1.0.0';

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  ApiEngine._internal() {
    // ─── إنشاء HMAC Interceptor بدون مفتاح صريح ───
    // المفتاح يُجمَّع ديناميكياً داخل الـ Interceptor
    _hmacInterceptor = HmacInterceptor(storage: _secureStorage);

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

    // ─── Interceptor 1: HMAC التوقيع ───
    dio.interceptors.add(_hmacInterceptor);

    // ─── Interceptor 2: Auth Token + Error Handling ───
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ✅ v2.0: التوكن يُقرأ فقط من FlutterSecureStorage
        // ⛔ لا SharedPreferences — لأنه غير مشفر ويمكن قراءته على Root
        try {
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // تجاهل — إذا فشلت القراءة، يذهب الطلب بدون توكن
          // والسيرفر يرد بـ 401
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // ─── Kill Switch: تحديث إجباري / صيانة ───
        if (e.response?.statusCode == 426) {
          final data = e.response?.data;
          final updateUrl = data is Map
              ? (data['update_url'] ?? 'https://al-muhandis.com/download/app.apk')
              : 'https://al-muhandis.com/download/app.apk';
          final isMaintenance = data is Map ? (data['maintenance'] == true) : false;
          _triggerKillSwitch(updateUrl, isMaintenance);
        }

        // ─── انتهاء الجلسة: مسح التوكن تلقائياً ───
        if (e.response?.statusCode == 401) {
          await clearAuth();
        }

        return handler.next(e);
      },
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
    } catch (e) {
      // صمت — هذا فحص في الخلفية
    }
  }

  // ════════════════════════════════════════════════════════
  //  🔐 إدارة المصادقة
  // ════════════════════════════════════════════════════════

  /// حفظ التوكن بعد تسجيل الدخول الناجح
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  /// حفظ مفتاح HMAC الخاص بالجلسة (يُرسله السيرفر بعد Login)
  Future<void> saveSessionHmacKey(String key) async {
    await _hmacInterceptor.saveSessionKey(key);
  }

  /// تسجيل الخروج الكامل — مسح كل البيانات الحساسة
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _hmacInterceptor.clearSessionKey();
  }

  // ════════════════════════════════════════════════════════
  //  📡 عمليات الـ API
  // ════════════════════════════════════════════════════════

  Future<Response> login(String username, String password) async {
    return await dio.post('/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> verifyEmail(String ticket, String code) async {
    return await dio.post('/verify-email', data: {
      'auth_ticket': ticket,
      'email_otp': code,
    });
  }

  Future<Response> verifyGoogle(String ticket, String code) async {
    return await dio.post('/verify-google', data: {
      'auth_ticket': ticket,
      'google_code': code,
    });
  }

  /// 💸 تنفيذ الحوالة المالية
  Future<Map<String, dynamic>> sendTransfer(
      String receiverId, double amount, String description) async {
    try {
      final res = await dio.post('/transfer', data: {
        'receiver_id': receiverId,
        'amount': amount,
        'description': description,
      });
      return {
        'success': true,
        'message': res.data['message'] ?? 'تم التحويل بنجاح',
        'data': res.data['data'] ?? {},
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'فشل التحويل',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ أثناء الاتصال',
      };
    }
  }
}
