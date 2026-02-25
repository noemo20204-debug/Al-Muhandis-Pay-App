import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (e) { return false; }
  }

  static Future<bool> authenticate({String reason = 'ضع بصمتك لتأكيد العملية المالية'}) async {
    try {
      if (!await isDeviceSupported()) return true;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false, useErrorDialogs: true),
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
