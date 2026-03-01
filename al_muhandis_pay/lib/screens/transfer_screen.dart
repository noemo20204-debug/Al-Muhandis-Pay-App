import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
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

  Future<void> _processTransfer() async {
    final receiver = _receiverCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();

    if (receiver.isEmpty || amountText.isEmpty) {
      EliteAlerts.show(context, title: 'بيانات غير مكتملة', message: 'الرجاء إدخال رقم حساب المستفيد والمبلغ.', isSuccess: false);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      EliteAlerts.show(context, title: 'قيمة غير صالحة', message: 'الرجاء إدخال مبلغ صحيح أكبر من الصفر.', isSuccess: false);
      return;
    }

    // 🟢 طبقة المصادقة البيومترية (إلزامية)
    final LocalAuthentication auth = LocalAuthentication();
    bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
    
    if (canAuthenticate) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'قم بتأكيد هويتك لإرسال ${amount.toStringAsFixed(2)} USDT',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (!authenticated) {
          EliteAlerts.show(context, title: 'إلغاء أمني', message: 'تم إيقاف العملية لعدم اجتياز البصمة البيومترية.', isSuccess: false);
          return;
        }
      } catch (e) {
        EliteAlerts.show(context, title: 'تنبيه', message: 'إعدادات البصمة في هاتفك غير مفعلة، يرجى تفعيلها للحماية.', isSuccess: false);
        return; // نمنع التحويل إذا لم تنجح البصمة
      }
    } else {
       EliteAlerts.show(context, title: 'تنبيه أمني', message: 'جهازك لا يدعم البصمة البيومترية، العملية محظورة.', isSuccess: false);
       return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiEngine().dio.post(
        '/transfer',
        data: {
          'receiver_id': receiver,
          'amount': amount,
          'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : 'حوالة عبر التطبيق'
        },
      );

      if (response.statusCode == 200) {
        String receiverName = response.data['data']['receiver'] ?? receiver;
        EliteAlerts.show(context, title: 'حوالة صادرة ناجحة', message: 'تم إرسال $amount USDT إلى حساب $receiverName', isSuccess: true);
        
        _receiverCtrl.clear();
        _amountCtrl.clear();
        _descCtrl.clear();
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'فشل الاتصال بالخادم المركزي.';
      EliteAlerts.show(context, title: 'رفض العملية', message: errorMsg, isSuccess: false);
    } catch (e) {
      EliteAlerts.show(context, title: 'خطأ داخلي', message: 'حدث خطأ غير متوقع أثناء معالجة الطلب.', isSuccess: false);
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
        title: const Text('إرسال أموال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🟢 منطقة إدخال المبلغ (ضخمة ومركزية كالبنوك العالمية)
                  const Text('المبلغ المراد إرساله', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: EliteColors.goldPrimary, fontSize: 50, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: EliteColors.goldPrimary.withOpacity(0.3), fontSize: 50),
                      border: InputBorder.none,
                      prefixText: 'USDT ',
                      prefixStyle: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🟢 البطاقة الزجاجية لبيانات المستلم
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: EliteColors.surface.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تفاصيل المستفيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 15),
                            _buildInputRow(
                              controller: _receiverCtrl,
                              icon: Icons.account_circle_outlined,
                              hint: 'رقم حساب المهندس (AMP) أو الإيميل',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white12, height: 1),
                            ),
                            _buildInputRow(
                              controller: _descCtrl,
                              icon: Icons.edit_note_outlined,
                              hint: 'الغاية من التحويل (اختياري)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // 🟢 زر التحويل مع البصمة
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EliteColors.goldPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                        shadowColor: EliteColors.goldPrimary.withOpacity(0.4),
                      ),
                      onPressed: _isLoading ? null : _processTransfer,
                      child: _isLoading
                          ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint, size: 28),
                                SizedBox(width: 10),
                                Text('تأكيد وإرسال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield, color: EliteColors.success, size: 14),
                      SizedBox(width: 5),
                      Text('محمي بتشفير البصمة البيومترية', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({required TextEditingController controller, required IconData icon, required String hint}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: EliteColors.goldPrimary, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}