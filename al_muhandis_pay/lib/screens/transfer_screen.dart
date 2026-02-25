import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/elite_theme.dart';
import '../services/api_engine.dart';
import '../widgets/glass_input.dart';
import '../widgets/elite_button.dart';
import '../services/biometric_service.dart'; // 🛡️ استدعاء درع البصمة

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _receiverCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  void _confirmTransfer() {
    if (_receiverCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      _showToast('جميع الحقول الإلزامية مطلوبة', EliteColors.danger);
      return;
    }
    
    // 🛡️ حماية بنكية: طلب تأكيد أخير قبل الخصم
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EliteColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: EliteColors.goldPrimary)),
        title: Text('تأكيد الحوالة', style: GoogleFonts.cairo(color: EliteColors.goldPrimary, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من إرسال ${_amountCtrl.text} USDT إلى ${_receiverCtrl.text}؟\nلا يمكن التراجع عن هذه العملية.', style: GoogleFonts.cairo(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EliteColors.goldPrimary),
            onPressed: () {
              Navigator.pop(ctx);
              _executeTransfer(); // استدعاء التنفيذ الذي سيطلب البصمة
            },
            child: Text('تأكيد السحب', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeTransfer() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    // ═══════════════════════════════════════════════════
    //  🛡️ الدرع البيومتري — لا تحويل بدون بصمة!
    // ═══════════════════════════════════════════════════
    final bool authenticated = await BiometricService.authenticateForTransfer(
      amount: amount,
      recipientName: _receiverCtrl.text,
    );

    if (!authenticated) {
      if (mounted) {
        _showToast('تم إلغاء العملية: فشل التحقق البيومتري.', EliteColors.danger);
      }
      return; // ⛔ إيقاف التحويل فوراً ومنع الاتصال بالسيرفر
    }
    // ═══════════════════════════════════════════════════

    // ✅ البصمة نجحت — تابع التحويل الأصلي
    setState(() => _isLoading = true);
    
    final result = await ApiEngine().sendTransfer(_receiverCtrl.text, amount, _descCtrl.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      _showToast(result['message'], result['success'] ? EliteColors.success : EliteColors.danger);
      if (result['success']) {
        Navigator.pop(context); // العودة للوحة التحكم بعد النجاح
      }
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('إرسال أموال', style: GoogleFonts.cairo(color: EliteColors.goldPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: EliteColors.goldPrimary),
      ),
      body: CustomPaint(
        painter: EliteBackgroundPainter(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Icon(Icons.send_to_mobile, size: 80, color: EliteColors.goldPrimary.withOpacity(0.8))),
                const SizedBox(height: 30),
                Text('بيانات المستلم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                GlassInput(controller: _receiverCtrl, label: 'معرف النظام أو البريد', icon: Icons.person_search),
                const SizedBox(height: 20),
                Text('تفاصيل الحوالة', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                GlassInput(controller: _amountCtrl, label: 'المبلغ (USDT)', icon: Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                GlassInput(controller: _descCtrl, label: 'البيان (اختياري)', icon: Icons.description),
                const SizedBox(height: 40),
                EliteButton(text: 'تنفيذ الحوالة السيادية', isLoading: _isLoading, onPressed: _confirmTransfer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
