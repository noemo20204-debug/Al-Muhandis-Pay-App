import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'hmac_interceptor.dart';
import 'ssl_pinning_service.dart';

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

    dio.interceptors.add(HmacInterceptor(secretKey: _hmacSecret));
  }

  Future<void> clearAuth() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'admin_name');
  }
}
