import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiEngine {
  static final ApiEngine _instance = ApiEngine._internal();
  factory ApiEngine() => _instance;
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiEngine._internal() {
    dio = Dio(BaseOptions(baseUrl: 'https://al-muhandis.com/api', connectTimeout: const Duration(seconds: 15)));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'jwt_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }
}
