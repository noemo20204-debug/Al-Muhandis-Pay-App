import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart'; // 🟢 مكتبة البصمة
import '../services/api_engine.dart';
import '../core/elite_theme.dart';
import '../core/elite_alerts.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _receiverCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitTransfer() async {
    final receiver = _receiverCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();

    if (receiver.isEmpty || amountText.isEmpty) {
      EliteAlerts.show(context, title: 'بيانات ناقصة', message: 'الرجاء إدخال حساب المستلم والمبلغ.', isSuccess: false);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      EliteAlerts.show(context, title: 'مبلغ غير صالح', message: 'الرجاء إدخال مبلغ صحيح أكبر من الصفر.', isSuccess: false);
      return;
    }

    // 🟢 طبقة الأمان البيومترية (قبل التحويل)
    final LocalAuthentication auth = LocalAuthentication();
    bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (canAuthenticate) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'يرجى تأكيد هويتك لتنفيذ الحوالة المالية',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (!authenticated) {
          EliteAlerts.show(context, title: 'تم الإلغاء', message: 'تم إلغاء عملية التحويل لعدم تأكيد الهوية.', isSuccess: false);
          return;
        }
      } catch (e) {
        EliteAlerts.show(context, title: 'خطأ في المصادقة', message: 'حدث خطأ في نظام البصمة.', isSuccess: false);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiEngine().dio.post(
        '/transfer',
        data: {
          'receiver_id': receiver,
          'amount': amount,
          'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : 'حوالة مالية عبر التطبيق'
        },
      );

      if (response.statusCode == 200) {
        EliteAlerts.show(context, title: 'تم التحويل بنجاح', message: 'تم إرسال $amount USDT إلى حساب $receiver', isSuccess: true);
        
        _receiverCtrl.clear();
        _amountCtrl.clear();
        _descCtrl.clear();
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'فشل الاتصال بالخادم المركزي.';
      EliteAlerts.show(context, title: 'فشل التحويل', message: errorMsg, isSuccess: false);
    } catch (e) {
      EliteAlerts.show(context, title: 'خطأ داخلي', message: 'حدث خطأ غير متوقع.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteColors.nightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('تحويل مالي', style: TextStyle(color: EliteColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())),
          SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات المستفيد', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInputField(controller: _receiverCtrl, label: 'رقم حساب المهندس (AMP) أو الإيميل', icon: Icons.account_box),
                const SizedBox(height: 20),
                _buildInputField(controller: _amountCtrl, label: 'المبلغ (USDT)', icon: Icons.attach_money, isNumber: true),
                const SizedBox(height: 20),
                _buildInputField(controller: _descCtrl, label: 'ملاحظات التحويل (اختياري)', icon: Icons.notes),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EliteColors.goldPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: EliteColors.goldPrimary.withOpacity(0.3),
                    ),
                    onPressed: _isLoading ? null : _submitTransfer,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('تأكيد وتنفيذ التحويل', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: EliteColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: EliteColors.goldPrimary, size: 22),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}