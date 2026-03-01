import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ═══════════════════════════════════════════════════════════════
///  Al-Muhandis Pay — HMAC Interceptor v2.0 (مُحَصَّن)
///  الملف: lib/services/hmac_interceptor.dart
/// ═══════════════════════════════════════════════════════════════
///  التحديثات في v2.0:
///   ✅ إزالة المفتاح المكتوب كنص صريح (Hardcoded Secret)
///   ✅ تجميع المفتاح ديناميكياً من أجزاء مشفرة (Obfuscated Key Assembly)
///   ✅ Nonce عشوائي حقيقي بـ SecureRandom (بدلاً من Timestamp ثابت)
///   ✅ دعم مفتاح الجلسة المؤقت (Session HMAC Key)
/// ═══════════════════════════════════════════════════════════════

class HmacInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  HmacInterceptor({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  /// ═══════════════════════════════════════════════════════
  ///  🔐 تجميع المفتاح المبدئي (Bootstrap Key)
  /// ═══════════════════════════════════════════════════════
  ///  هذا المفتاح يُستخدم فقط لطلبات ما قبل المصادقة (Login).
  ///  بعد المصادقة الناجحة، يُستبدل بمفتاح الجلسة من السيرفر.
  ///
  ///  الاستراتيجية: XOR Obfuscated Assembly
  ///   - المفتاح مقسم إلى 4 أجزاء
  ///   - كل جزء مشفر بـ XOR مع mask مختلف
  ///   - يتم تجميعهم في الذاكرة فقط عند الحاجة
  ///   - هذا يمنع استخراج المفتاح بالبحث النصي في APK
  ///
  ///  ⚠️ عند تغيير HMAC_SECRET_KEY في .env:
  ///   1. شغّل أداة generate_obfuscated_key.dart (سأزودك بها)
  ///   2. استبدل القيم أدناه بالقيم الجديدة
  /// ═══════════════════════════════════════════════════════
  static String _assembleBootstrapKey() {
    final List<int> part1Encoded = [0x35, 0x80, 0x5B, 0x17, 0xC6, 0xE0, 0x34, 0xB1, 0xD4, 0x86, 0xC5, 0xEB, 0x5E, 0x24, 0x4C, 0x94];
    final List<int> part2Encoded = [0x6B, 0x41, 0x5B, 0x0B, 0x80, 0xC3, 0x3C, 0xCC, 0x73, 0x87, 0xBC, 0xAD, 0xCD, 0xB9, 0xC8, 0xC5];
    final List<int> part3Encoded = [0x74, 0x18, 0x21, 0x69, 0x58, 0x60, 0x65, 0x98, 0x9A, 0x06, 0x78, 0xA9, 0xD5, 0xD6, 0xF9, 0xB0];
    final List<int> part4Encoded = [0xFD, 0x57, 0x90, 0x9C, 0x93, 0x4E, 0xB2, 0x25, 0x17, 0x45, 0x82, 0x11, 0xC0, 0xE3, 0x3A, 0x89];

    final List<int> mask1 = [0x07, 0xE6, 0x6A, 0x26, 0xA3, 0xD6, 0x00, 0xD7, 0xB2, 0xBF, 0xF7, 0x8F, 0x6A, 0x47, 0x75, 0xA5];
    final List<int> mask2 = [0x08, 0x77, 0x63, 0x6A, 0xE2, 0xA6, 0x09, 0xFA, 0x17, 0xB4, 0x8D, 0x9C, 0xAE, 0x8C, 0xFE, 0xA7];
    final List<int> mask3 = [0x10, 0x28, 0x12, 0x0A, 0x6E, 0x05, 0x03, 0xAA, 0xAC, 0x36, 0x49, 0x9E, 0xB4, 0xEF, 0x9C, 0x82];
    final List<int> mask4 = [0x9F, 0x67, 0xF4, 0xA9, 0xA7, 0x2D, 0xD6, 0x44, 0x2F, 0x72, 0xB2, 0x26, 0xA3, 0xDA, 0x0C, 0xEB];

    final buffer = StringBuffer();

    for (int i = 0; i < part1Encoded.length; i++) {
      buffer.writeCharCode(part1Encoded[i] ^ mask1[i]);
    }
    for (int i = 0; i < part2Encoded.length; i++) {
      buffer.writeCharCode(part2Encoded[i] ^ mask2[i]);
    }
    for (int i = 0; i < part3Encoded.length; i++) {
      buffer.writeCharCode(part3Encoded[i] ^ mask3[i]);
    }
    for (int i = 0; i < part4Encoded.length; i++) {
      buffer.writeCharCode(part4Encoded[i] ^ mask4[i]);
    }

    return buffer.toString();
  }

  /// ═══════════════════════════════════════════════════════
  ///  جلب المفتاح الفعال (Session Key أو Bootstrap Key)
  /// ═══════════════════════════════════════════════════════
  Future<String> _getActiveHmacKey() async {
    // أولاً: نبحث عن مفتاح الجلسة المؤقت (إن وجد)
    try {
      final sessionKey = await _secureStorage.read(key: 'session_hmac_key');
      if (sessionKey != null && sessionKey.isNotEmpty) {
        return sessionKey;
      }
    } catch (_) {
      // تجاهل — ربما لم يتم تسجيل الدخول بعد
    }

    // ثانياً: استخدام المفتاح المبدئي (Bootstrap Key)
    return _assembleBootstrapKey();
  }

  /// ═══════════════════════════════════════════════════════
  ///  🎲 توليد Nonce عشوائي حقيقي (Cryptographically Secure)
  /// ═══════════════════════════════════════════════════════
  static String _generateSecureNonce() {
    final random = Random.secure();
    final bytes = Uint8List(24); // 24 بايت = 192 بت
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// ═══════════════════════════════════════════════════════
  ///  التوقيع على كل طلب صادر
  /// ═══════════════════════════════════════════════════════
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final hmacKey = await _getActiveHmacKey();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final nonce = _generateSecureNonce(); // ✅ عشوائي حقيقي

      String rawBody = '';
      if (options.data != null) {
        rawBody = jsonEncode(options.data);
      }

      final method = options.method.toUpperCase();
      final path = options.uri.path;

      final signingString = '$method|$path|$rawBody|$timestamp|$nonce';

      final hmac = Hmac(sha256, utf8.encode(hmacKey));
      final digest = hmac.convert(utf8.encode(signingString));

      options.headers['X-Hmac-Signature'] = digest.toString();
      options.headers['X-Request-Timestamp'] = timestamp;
      options.headers['X-Request-Nonce'] = nonce;

      if (rawBody.isNotEmpty) {
        options.headers['X-Body-Hash'] =
            sha256.convert(utf8.encode(rawBody)).toString();
      }
    } catch (e) {
      // في حالة فشل التوقيع — لا نُسقط الطلب، نُكمله بدون HMAC
      // السيرفر سيرفضه بـ 401 وهذا أفضل من crash في التطبيق
    }

    super.onRequest(options, handler);
  }

  /// ═══════════════════════════════════════════════════════
  ///  حفظ مفتاح الجلسة المؤقت (يُستدعى بعد Login الناجح)
  /// ═══════════════════════════════════════════════════════
  Future<void> saveSessionKey(String sessionKey) async {
    await _secureStorage.write(key: 'session_hmac_key', value: sessionKey);
  }

  /// مسح مفتاح الجلسة (عند تسجيل الخروج)
  Future<void> clearSessionKey() async {
    await _secureStorage.delete(key: 'session_hmac_key');
  }
}
