import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class HmacInterceptor extends Interceptor {
  final String secretKey;

  HmacInterceptor({required this.secretKey});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = base64Encode(utf8.encode(timestamp + 'AlMuhandisBankSecret2026'));

    String rawBody = '';
    if (options.data != null) {
      rawBody = jsonEncode(options.data);
    }

    final method = options.method.toUpperCase();
    final path = options.uri.path;
    
    final signingString = '$method|$path|$rawBody|$timestamp|$nonce';

    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(signingString));
    
    options.headers['X-Hmac-Signature'] = digest.toString();
    options.headers['X-Request-Timestamp'] = timestamp;
    options.headers['X-Request-Nonce'] = nonce;
    
    if (rawBody.isNotEmpty) {
      options.headers['X-Body-Hash'] = sha256.convert(utf8.encode(rawBody)).toString();
    }

    super.onRequest(options, handler);
  }
}
