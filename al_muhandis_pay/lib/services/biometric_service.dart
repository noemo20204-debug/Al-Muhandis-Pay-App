import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate({String reason = 'ضع بصمتك لتأكيد العملية المالية'}) async {
    try {
      bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true; // تجاوز إذا كان الجهاز لا يدعم البصمة
      
      // 🛡️ الصيغة المجردة والآمنة 100% التي يقبلها أي إصدار
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (_) {
      return false; // فشل أو إلغاء البصمة
    }
  }

  static Future<bool> authenticateForTransfer({required double amount, required String recipientName}) async {
    return await authenticate(reason: 'أكّد بصمتك لتحويل $amount USDT إلى $recipientName');
  }
}
