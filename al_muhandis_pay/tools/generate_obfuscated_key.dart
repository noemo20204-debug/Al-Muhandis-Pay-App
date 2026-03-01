import 'dart:convert';
import 'dart:math';

/// ═══════════════════════════════════════════════════════════════
///  Al-Muhandis Pay — أداة توليد المفتاح المشفر (Key Obfuscator)
///  الملف: tools/generate_obfuscated_key.dart
/// ═══════════════════════════════════════════════════════════════
///  الغرض: تحويل مفتاح HMAC النصي إلى أجزاء XOR مشفرة
///          لاستخدامها في hmac_interceptor.dart
///
///  التنفيذ:
///   dart run tools/generate_obfuscated_key.dart "YOUR_HMAC_SECRET_KEY_HERE"
///
///  سيطبع لك الكود الجاهز للنسخ واللصق في hmac_interceptor.dart
/// ═══════════════════════════════════════════════════════════════

void main(List<String> args) {
  if (args.isEmpty) {
    print('═══════════════════════════════════════════');
    print('  أداة توليد المفتاح المشفر');
    print('═══════════════════════════════════════════');
    print('');
    print('الاستخدام:');
    print('  dart run generate_obfuscated_key.dart "مفتاح_HMAC_الخاص_بك"');
    print('');
    print('مثال:');
    print('  dart run generate_obfuscated_key.dart "a1b2c3d4e5f6..."');
    return;
  }

  final secretKey = args[0];
  final bytes = utf8.encode(secretKey);

  print('═══════════════════════════════════════════════════════════');
  print('  Al-Muhandis Pay — Key Obfuscation Generator');
  print('═══════════════════════════════════════════════════════════');
  print('');
  print('طول المفتاح: ${bytes.length} بايت');
  print('');

  // تقسيم المفتاح إلى 4 أجزاء متساوية (تقريباً)
  final partSize = (bytes.length / 4).ceil();
  final parts = <List<int>>[];
  for (int i = 0; i < 4; i++) {
    final start = i * partSize;
    final end = (start + partSize > bytes.length) ? bytes.length : start + partSize;
    if (start < bytes.length) {
      parts.add(bytes.sublist(start, end));
    } else {
      parts.add([]);
    }
  }

  // توليد أقنعة XOR عشوائية
  final random = Random.secure();
  final masks = <List<int>>[];
  final encoded = <List<int>>[];

  for (int p = 0; p < parts.length; p++) {
    final mask = List<int>.generate(parts[p].length, (_) => random.nextInt(256));
    final enc = <int>[];
    for (int i = 0; i < parts[p].length; i++) {
      enc.add(parts[p][i] ^ mask[i]);
    }
    masks.add(mask);
    encoded.add(enc);
  }

  // طباعة الكود الجاهز
  print('══════ انسخ الكود التالي إلى hmac_interceptor.dart ══════');
  print('══════ (داخل دالة _assembleBootstrapKey)              ══════');
  print('');
  print('  static String _assembleBootstrapKey() {');

  for (int p = 0; p < parts.length; p++) {
    print('    final List<int> part${p + 1}Encoded = ${_formatList(encoded[p])};');
  }
  print('');
  for (int p = 0; p < parts.length; p++) {
    print('    final List<int> mask${p + 1} = ${_formatList(masks[p])};');
  }

  print('');
  print('    final buffer = StringBuffer();');
  print('');
  for (int p = 0; p < parts.length; p++) {
    print('    for (int i = 0; i < part${p + 1}Encoded.length; i++) {');
    print('      buffer.writeCharCode(part${p + 1}Encoded[i] ^ mask${p + 1}[i]);');
    print('    }');
  }
  print('');
  print('    return buffer.toString();');
  print('  }');
  print('');
  print('═══════════════════════════════════════════════════════════');

  // التحقق
  final reconstructed = StringBuffer();
  for (int p = 0; p < parts.length; p++) {
    for (int i = 0; i < encoded[p].length; i++) {
      reconstructed.writeCharCode(encoded[p][i] ^ masks[p][i]);
    }
  }

  if (reconstructed.toString() == secretKey) {
    print('✅ التحقق: المفتاح المُعاد تجميعه يتطابق مع الأصلي');
  } else {
    print('❌ خطأ: المفتاح المُعاد تجميعه لا يتطابق!');
  }
}

String _formatList(List<int> list) {
  final formatted = list.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ');
  return '[$formatted]';
}
