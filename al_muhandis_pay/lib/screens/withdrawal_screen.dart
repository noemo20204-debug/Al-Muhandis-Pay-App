import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart' show DioException;
import '../services/api_engine.dart';

class _C {
  static const Color nightBg = Color(0xFF030712);
  static const Color cardBg = Color(0xFF0D1321);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8952C);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color glassBorder = Color(0xFF1E293B);
  static const Color inputBg = Color(0xFF0F1524);
  static const Color textMuted = Color(0xFF64748B);
}

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});
  @override State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> with SingleTickerProviderStateMixin {
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  String _phase = 'input';
  Map<String, dynamic>? _result;
  late AnimationController _fadeCtrl;

  @override void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _amountCtrl.addListener(() => setState(() {}));
    _addressCtrl.addListener(() => setState(() {}));
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _netAmount => (_amount - 1.50).clamp(0, double.infinity);
  bool get _isValidAddress => RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$').hasMatch(_addressCtrl.text.trim());
  bool get _isValidAmount => _amount >= 5.00;

  Future<void> _submitWithdrawal() async {
    if (!_isValidAddress || !_isValidAmount) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final res = await ApiEngine().dio.post('/withdrawal/request', data: {'address': _addressCtrl.text.trim(), 'amount': _amount});
      if (res.statusCode == 200) {
        HapticFeedback.heavyImpact();
        setState(() { _result = res.data['data'] ?? res.data; _phase = 'success'; _isLoading = false; });
      }
    } catch (e) {
      String msg = 'فشل تقديم طلب السحب.';
      if (e is DioException && e.response?.data != null) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      setState(() { _isLoading = false; _errorMsg = msg; });
    }
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: _C.nightBg, appBar: AppBar(title: Text('سحب USDT', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _C.goldPrimary)), backgroundColor: _C.nightBg, elevation: 0),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _phase == 'input' ? _buildInput() : _buildSuccess()))),
    );
  }

  Widget _buildInput() {
    return Column(children: [
      Icon(Icons.arrow_circle_up_rounded, color: _C.goldPrimary, size: 64),
      Text('سحب الأرباح', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 30),
      TextField(controller: _addressCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'عنوان TRC-20 الوجهة (يبدأ بـ T)', hintStyle: const TextStyle(color: _C.textMuted), filled: true, fillColor: _C.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
      const SizedBox(height: 15),
      TextField(controller: _amountCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'المبلغ (الحد الأدنى 5 USDT)', hintStyle: const TextStyle(color: _C.textMuted), filled: true, fillColor: _C.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
      if (_amount > 0) ...[
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _C.cardBg, borderRadius: BorderRadius.circular(15)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('رسوم الشبكة', style: GoogleFonts.cairo(color: _C.danger)), Text('1.50 USDT', style: GoogleFonts.cairo(color: _C.danger))]),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الصافي الذي سيصلك', style: GoogleFonts.cairo(color: _C.success)), Text('${_netAmount.toStringAsFixed(2)} USDT', style: GoogleFonts.cairo(color: _C.success, fontWeight: FontWeight.bold))]),
        ]))
      ],
      if (_errorMsg != null) Padding(padding: const EdgeInsets.only(top: 15), child: Text(_errorMsg!, style: GoogleFonts.cairo(color: _C.danger))),
      const SizedBox(height: 30),
      SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: (_isValidAddress && _isValidAmount && !_isLoading) ? _submitWithdrawal : null, style: ElevatedButton.styleFrom(backgroundColor: _C.goldPrimary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _isLoading ? const CircularProgressIndicator() : Text('تأكيد السحب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)))),
    ]);
  }

  Widget _buildSuccess() {
    return Column(children: [
      const SizedBox(height: 50),
      const Icon(Icons.check_circle, color: _C.success, size: 80),
      const SizedBox(height: 20),
      Text('تم تسجيل الطلب بنجاح', style: GoogleFonts.cairo(color: _C.success, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('العودة'))
    ]);
  }
}
