import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class HmacInterceptor extends Interceptor {
  final String _secretKey;
  HmacInterceptor({required String secretKey}) : _secretKey = secretKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String method = options.method.toUpperCase();
    final String path = options.path;
    final String timestamp = options.headers['X-Request-Timestamp']?.toString() ?? '';
    final String nonce = options.headers['X-Request-Nonce']?.toString() ?? '';

    String bodyString = '';
    if (options.data != null) {
      if (options.data is Map || options.data is List) {
        bodyString = jsonEncode(options.data);
      } else if (options.data is String) {
        bodyString = options.data;
      }
    }

    final String signingString = [method, path, bodyString, timestamp, nonce].join('|');
    final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmacSha256.convert(utf8.encode(signingString));
    
    options.headers['X-HMAC-Signature'] = digest.toString();
    options.headers['X-Body-Hash'] = sha256.convert(utf8.encode(bodyString)).toString();

    handler.next(options);
  }
}
