import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticate({String reason = 'ضع بصمتك لتأكيد العملية المالية'}) async {
    try {
      // التحقق من وجود بصمة مسجلة في الجهاز
      bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true; // تجاوز إذا كان الجهاز لا يدعم البصمة
      
      // الصيغة الكلاسيكية المتوافقة مع جميع الإصدارات
      return await _auth.authenticate(
        localizedReason: reason,
        useErrorDialogs: true,
        stickyAuth: true,
        biometricOnly: false,
      );
    } on PlatformException catch (e) {
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') return false;
      return false;
    }
  }

  static Future<bool> authenticateForTransfer({required double amount, required String recipientName}) async {
    return await authenticate(reason: 'أكّد بصمتك لتحويل $amount USDT إلى $recipientName');
  }
}
