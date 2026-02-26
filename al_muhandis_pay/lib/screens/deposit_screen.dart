import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart' show DioException;
import '../services/api_engine.dart';

class _C {
  static const Color nightBg     = Color(0xFF030712);
  static const Color cardBg      = Color(0xFF0D1321);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark    = Color(0xFFB8952C);
  static const Color goldLight   = Color(0xFFE8D48B);
  static const Color success     = Color(0xFF22C55E);
  static const Color danger      = Color(0xFFEF4444);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color glassBorder = Color(0xFF1E293B);
  static const Color inputBg     = Color(0xFF0F1524);
  static const Color textMuted   = Color(0xFF64748B);
}

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});
  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> with TickerProviderStateMixin {
  final _amountCtrl = TextEditingController();
  String _phase = 'input'; 
  bool _isLoading = false;
  String? _errorMsg;
  int? _depositId;
  String _payAddress = '';
  String _payAmount = '';
  String _status = '';
  int _expiresIn = 3600; 
  Timer? _pollTimer;
  Timer? _countdownTimer;
  late AnimationController _pulseCtrl, _fadeCtrl;
  late Animation<double> _pulseAnim, _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); _countdownTimer?.cancel();
    _pulseCtrl.dispose(); _fadeCtrl.dispose(); _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _createDeposit() async {
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 5) { setState(() => _errorMsg = 'الحد الأدنى للإيداع: 5 USDT'); return; }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final res = await ApiEngine().dio.post('/deposit/create', data: {'amount': amount});
      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        setState(() {
          _depositId = data['deposit_id']; _payAddress = data['pay_address'] ?? '';
          _payAmount = data['pay_amount']?.toString() ?? amountText; _status = data['status'] ?? 'waiting';
          _expiresIn = data['expires_in'] ?? 3600; _phase = 'waiting'; _isLoading = false;
        });
        _fadeCtrl.reset(); _fadeCtrl.forward(); _startPolling(); _startCountdown();
      }
    } catch (e) {
      String msg = 'فشل إنشاء طلب الإيداع. حاول مرة أخرى.';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) msg = data['message']?.toString() ?? msg;
      }
      setState(() { _isLoading = false; _errorMsg = msg; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStatus());
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_expiresIn <= 0) { _countdownTimer?.cancel(); if (_status == 'waiting') setState(() { _status = 'expired'; _phase = 'failed'; }); } 
      else { if (mounted) setState(() => _expiresIn--); }
    });
  }

  Future<void> _checkStatus() async {
    if (_depositId == null) return;
    try {
      final res = await ApiEngine().dio.get('/deposit/status?deposit_id=$_depositId');
      if (res.statusCode == 200) {
        final dep = res.data['data']['deposit'] ?? {};
        final newStatus = dep['status'] ?? _status;
        if (newStatus != _status) {
          setState(() => _status = newStatus);
          if (newStatus == 'finished' || newStatus == 'confirmed') {
            _pollTimer?.cancel(); _countdownTimer?.cancel(); HapticFeedback.heavyImpact();
            setState(() => _phase = 'success'); _fadeCtrl.reset(); _fadeCtrl.forward();
          } else if (newStatus == 'failed' || newStatus == 'expired' || newStatus == 'refunded') {
            _pollTimer?.cancel(); _countdownTimer?.cancel(); setState(() => _phase = 'failed');
          }
        }
      }
    } catch (_) {}
  }

  void _copyAddress() {
    if (_payAddress.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _payAddress)); HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 18), const SizedBox(width: 8), Text('تم نسخ العنوان', style: GoogleFonts.cairo(fontSize: 13))]), backgroundColor: _C.success.withOpacity(0.9), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2)));
    }
  }

  String get _countdownText => '${(_expiresIn ~/ 60).toString().padLeft(2, '0')}:${(_expiresIn % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(backgroundColor: _C.nightBg, appBar: AppBar(title: Text('إيداع USDT', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _C.goldPrimary)), backgroundColor: _C.nightBg, foregroundColor: _C.goldPrimary, elevation: 0), body: SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: _buildCurrentPhase())))));
  }

  Widget _buildCurrentPhase() {
    switch (_phase) { case 'waiting': return _buildWaitingPhase(); case 'success': return _buildSuccessPhase(); case 'failed': return _buildFailedPhase(); default: return _buildInputPhase(); }
  }

  Widget _buildInputPhase() {
    return Column(children: [
      const SizedBox(height: 20), Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: _C.goldPrimary.withOpacity(0.1), border: Border.all(color: _C.goldPrimary.withOpacity(0.2))), child: const Icon(Icons.account_balance_wallet_rounded, color: _C.goldPrimary, size: 36)), const SizedBox(height: 20), Text('تغذية الحساب', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 6), Text('أدخل المبلغ المراد إيداعه عبر شبكة Tron (TRC-20)', style: GoogleFonts.cairo(fontSize: 12, color: _C.textMuted), textAlign: TextAlign.center), const SizedBox(height: 32),
      _GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('مبلغ الإيداع', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: _C.goldLight)), const SizedBox(height: 12),
        Container(decoration: BoxDecoration(color: _C.inputBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.glassBorder)), child: TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center, decoration: InputDecoration(hintText: '0.00', hintStyle: GoogleFonts.cairo(color: _C.textMuted.withOpacity(0.3), fontSize: 24), suffixIcon: Padding(padding: const EdgeInsets.only(left: 14, top: 14), child: Text('USDT', style: GoogleFonts.cairo(color: _C.goldPrimary, fontWeight: FontWeight.bold, fontSize: 14))), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)))), const SizedBox(height: 10),
        Row(children: [50, 100, 500, 1000].map((v) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: GestureDetector(onTap: () => _amountCtrl.text = v.toString(), child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _C.goldPrimary.withOpacity(0.07), border: Border.all(color: _C.goldPrimary.withOpacity(0.15))), child: Center(child: Text('\$$v', style: GoogleFonts.cairo(fontSize: 12, color: _C.goldPrimary, fontWeight: FontWeight.w600)))))))).toList()),
        if (_errorMsg != null) ...[const SizedBox(height: 14), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _C.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.danger.withOpacity(0.15))), child: Row(children: [Icon(Icons.error_outline, color: _C.danger, size: 16), const SizedBox(width: 8), Expanded(child: Text(_errorMsg!, style: GoogleFonts.cairo(fontSize: 11, color: _C.danger)))]))],
      ])), const SizedBox(height: 12),
      _GlassCard(child: Column(children: [_infoRow(Icons.currency_bitcoin, 'الشبكة', 'Tron (TRC-20)'), const SizedBox(height: 10), _infoRow(Icons.timer_outlined, 'وقت التأكيد', '1 - 5 دقائق'), const SizedBox(height: 10), _infoRow(Icons.shield_outlined, 'الحد الأدنى', '5 USDT')])), const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 56, child: AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: _isLoading ? null : const LinearGradient(colors: [_C.goldPrimary, _C.goldDark]), color: _isLoading ? _C.goldPrimary.withOpacity(0.25) : null, boxShadow: _isLoading ? [] : [BoxShadow(color: _C.goldPrimary.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))]), child: Material(color: Colors.transparent, child: InkWell(onTap: _isLoading ? null : () { HapticFeedback.lightImpact(); _createDeposit(); }, borderRadius: BorderRadius.circular(16), child: Center(child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.goldPrimary)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('توليد عنوان الإيداع', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0A0F18))), const SizedBox(width: 8), const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFF0A0F18))])))))),
    ]);
  }

  Widget _buildWaitingPhase() {
    return Column(children: [
      const SizedBox(height: 10), AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Opacity(opacity: _pulseAnim.value, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _expiresIn < 300 ? _C.danger.withOpacity(0.1) : _C.goldPrimary.withOpacity(0.07), border: Border.all(color: _expiresIn < 300 ? _C.danger.withOpacity(0.2) : _C.goldPrimary.withOpacity(0.15))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.timer_outlined, size: 16, color: _expiresIn < 300 ? _C.danger : _C.goldPrimary), const SizedBox(width: 6), Text('صالح لمدة $_countdownText', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: _expiresIn < 300 ? _C.danger : _C.goldPrimary))])))), const SizedBox(height: 16), _buildStatusBadge(), const SizedBox(height: 20),
      _GlassCard(child: Column(children: [
        Text('امسح الرمز أو انسخ العنوان', style: GoogleFonts.cairo(fontSize: 13, color: _C.textMuted)), const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _C.goldPrimary.withOpacity(0.1), blurRadius: 20)]), child: QrImageView(data: _payAddress, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.roundedOuter, color: Color(0xFF0A0F18)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.roundedOutsideCorners, color: Color(0xFF0A0F18)))), const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.inputBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)), child: Row(children: [Expanded(child: Text(_payAddress, style: GoogleFonts.sourceCodePro(fontSize: 11, color: _C.goldLight, letterSpacing: 0.3), textAlign: TextAlign.center)), const SizedBox(width: 8), GestureDetector(onTap: _copyAddress, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _C.goldPrimary.withOpacity(0.1)), child: const Icon(Icons.copy_rounded, size: 18, color: _C.goldPrimary)))])), const SizedBox(height: 14),
        _infoRow(Icons.toll_rounded, 'المبلغ المطلوب', '$_payAmount USDT'), const SizedBox(height: 8), _infoRow(Icons.lan_outlined, 'الشبكة', 'Tron (TRC-20)'),
      ])), const SizedBox(height: 14),
      _GlassCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.warning_amber_rounded, color: _C.warning, size: 20), const SizedBox(width: 10), Expanded(child: Text('أرسل فقط USDT على شبكة TRC-20 إلى هذا العنوان. إرسال عملات أخرى أو استخدام شبكة مختلفة سيؤدي لفقدان الأموال نهائياً.', style: GoogleFonts.cairo(fontSize: 11, color: _C.warning, height: 1.6)))])), const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _C.goldPrimary.withOpacity(0.5))), const SizedBox(width: 10), Text('نحن في انتظار وصول الحوالة على شبكة Tron...', style: GoogleFonts.cairo(fontSize: 11, color: _C.textMuted))]),
    ]);
  }

  Widget _buildSuccessPhase() {
    return Column(children: [const SizedBox(height: 50), Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: _C.success.withOpacity(0.12), border: Border.all(color: _C.success.withOpacity(0.3), width: 2)), child: const Icon(Icons.check_rounded, color: _C.success, size: 52)), const SizedBox(height: 24), Text('تم الإيداع بنجاح!', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: _C.success)), const SizedBox(height: 8), Text('تم إضافة الرصيد إلى محفظتك', style: GoogleFonts.cairo(fontSize: 14, color: _C.textMuted)), const SizedBox(height: 32), _GlassCard(child: Column(children: [_infoRow(Icons.toll_rounded, 'المبلغ', '$_payAmount USDT'), const SizedBox(height: 10), _infoRow(Icons.check_circle_outline, 'الحالة', 'مكتمل')])), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, size: 20), label: Text('العودة للمحفظة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _C.goldPrimary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))]);
  }

  Widget _buildFailedPhase() {
    return Column(children: [const SizedBox(height: 50), Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: _C.danger.withOpacity(0.12), border: Border.all(color: _C.danger.withOpacity(0.3), width: 2)), child: const Icon(Icons.close_rounded, color: _C.danger, size: 52)), const SizedBox(height: 24), Text(_status == 'expired' ? 'انتهت صلاحية الطلب' : 'فشل الإيداع', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: _C.danger)), const SizedBox(height: 8), Text('يمكنك إنشاء طلب إيداع جديد', style: GoogleFonts.cairo(fontSize: 14, color: _C.textMuted)), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(onPressed: () { setState(() { _phase = 'input'; _errorMsg = null; _amountCtrl.clear(); }); _fadeCtrl.reset(); _fadeCtrl.forward(); }, icon: const Icon(Icons.refresh_rounded, size: 20), label: Text('محاولة جديدة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: _C.goldPrimary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))]);
  }

  Widget _buildStatusBadge() {
    IconData icon; String text; Color color;
    switch (_status) { case 'confirming': icon = Icons.hourglass_top; text = 'بانتظار تأكيدات الشبكة...'; color = _C.warning; break; case 'sending': icon = Icons.swap_horiz; text = 'جاري تحويل الأموال...'; color = _C.warning; break; case 'partially_paid': icon = Icons.warning_amber; text = 'تم دفع مبلغ جزئي'; color = _C.warning; break; default: icon = Icons.schedule; text = 'بانتظار الدفع...'; color = _C.goldPrimary; }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withOpacity(0.08), border: Border.all(color: color.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(text, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: color))]));
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(icon, size: 16, color: _C.textMuted), const SizedBox(width: 8), Text(label, style: GoogleFonts.cairo(fontSize: 12, color: _C.textMuted))]), Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))]);
}

class _GlassCard extends StatelessWidget {
  final Widget child; const _GlassCard({required this.child});
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _C.cardBg.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.glassBorder.withOpacity(0.5))), child: child)));
}
