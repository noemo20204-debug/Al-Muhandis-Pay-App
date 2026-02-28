import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_engine.dart';
import '../core/elite_theme.dart';
import '../core/elite_alerts.dart'; // 🟢 الإشعارات الجديدة

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
      EliteAlerts.show(context, title: 'حقول مطلوبة', message: 'الرجاء إدخال حساب المستلم والمبلغ.', isSuccess: false);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      EliteAlerts.show(context, title: 'مبلغ غير صالح', message: 'الرجاء إدخال مبلغ صحيح أكبر من الصفر.', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiEngine().dio.post(
        '/transfer',
        data: {
          'receiver_id': receiver,
          'amount': amount,
          'description': _descCtrl.text.isNotEmpty ? _descCtrl.text : 'حوالة من التطبيق'
        },
      );

      if (response.statusCode == 200) {
        // 🟢 إطلاق إشعار النجاح الخرافي!
        EliteAlerts.show(context, title: 'تم التحويل بنجاح', message: 'تم إرسال $amount USDT إلى حساب $receiver', isSuccess: true);
        
        _receiverCtrl.clear();
        _amountCtrl.clear();
        _descCtrl.clear();
        
        // العودة للداشبورد بعد ثانيتين
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['message'] ?? 'فشل الاتصال بالخادم الرئيسي.';
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
        title: const Text('تحويل سيادي', style: TextStyle(color: EliteColors.goldPrimary, fontWeight: FontWeight.bold)),
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
                const Text('بيانات المستفيد', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInputField(controller: _receiverCtrl, label: 'رقم حساب المهندس (AMP) أو الإيميل', icon: Icons.account_box),
                const SizedBox(height: 20),
                _buildInputField(controller: _amountCtrl, label: 'المبلغ (USDT)', icon: Icons.attach_money, isNumber: true),
                const SizedBox(height: 20),
                _buildInputField(controller: _descCtrl, label: 'ملاحظات (اختياري)', icon: Icons.notes),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EliteColors.goldPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: EliteColors.goldPrimary.withOpacity(0.5),
                    ),
                    onPressed: _isLoading ? null : _submitTransfer,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('تنفيذ التحويل الفوري', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
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
        color: EliteColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: EliteColors.goldPrimary),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}