import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../core/elite_theme.dart';
import '../services/api_engine.dart';
import '../widgets/glass_input.dart';
import '../widgets/elite_button.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 0 = Credentials, 1 = Email OTP, 2 = Google 2FA
  int _authPhase = 0; 
  String _authTicket = '';
  bool _isLoading = false;
  bool _obscure = true;

  // Controllers
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();
  final _googleOtpCtrl = TextEditingController();

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo()), backgroundColor: color));
  }

  // 🛡️ المرحلة الأولى: الباسورد
  Future<void> _processPhase1() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().login(_userCtrl.text, _passCtrl.text);
      if (res.statusCode == 200) {
        if (res.data['status'] == 'pending_email_otp') {
          _authTicket = res.data['auth_ticket'];
          _showToast(res.data['message'], EliteColors.success);
          setState(() => _authPhase = 1); // التحول لشاشة الإيميل
        } else if (res.data['status'] == 'authenticated') {
          // تخطي سيادي (Master Admin)
          await _saveTokenAndEnter(res.data);
        }
      }
    } on DioException catch (e) {
      _showToast(e.response?.data['message'] ?? 'بيانات غير صحيحة', EliteColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📧 المرحلة الثانية: كود الإيميل
  Future<void> _processPhase2() async {
    if (_emailOtpCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyEmail(_authTicket, _emailOtpCtrl.text);
      if (res.statusCode == 200 && res.data['status'] == 'pending_google_2fa') {
        _authTicket = res.data['auth_ticket']; // تحديث التذكرة
        _showToast(res.data['message'], EliteColors.success);
        setState(() => _authPhase = 2); // التحول لشاشة جوجل
      }
    } on DioException catch (e) {
      _showToast(e.response?.data['message'] ?? 'كود الإيميل غير صحيح', EliteColors.danger);
      if (e.response?.statusCode == 401) setState(() => _authPhase = 0); // العودة للبداية إذا انتهت الجلسة
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔐 المرحلة الثالثة: كود جوجل 2FA
  Future<void> _processPhase3() async {
    if (_googleOtpCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyGoogle(_authTicket, _googleOtpCtrl.text);
      if (res.statusCode == 200 && res.data['status'] == 'authenticated') {
        _showToast(res.data['message'], EliteColors.success);
        await _saveTokenAndEnter(res.data);
      }
    } on DioException catch (e) {
      _showToast(e.response?.data['message'] ?? 'كود جوجل غير صحيح', EliteColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTokenAndEnter(Map<String, dynamic> data) async {
    await ApiEngine().storage.write(key: 'jwt_token', value: data['data']['token']);
    await ApiEngine().storage.write(key: 'admin_name', value: data['data']['user']['name']);
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  // بناء النوافذ المتغيرة
  Widget _buildPhase1() {
    return Column(
      key: const ValueKey(0),
      children: [
        const Icon(Icons.shield, size: 60, color: EliteColors.goldPrimary),
        const SizedBox(height: 20),
        Text('البوابة السيادية', style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        GlassInput(controller: _userCtrl, label: 'معرف النظام', icon: Icons.person),
        const SizedBox(height: 20),
        GlassInput(controller: _passCtrl, label: 'مفتاح التشفير', icon: Icons.vpn_key, isPassword: true, obscureText: _obscure, onTogglePassword: () => setState(() => _obscure = !_obscure)),
        const SizedBox(height: 40),
        EliteButton(text: 'فحص البيانات', isLoading: _isLoading, onPressed: _processPhase1),
      ],
    );
  }

  Widget _buildPhase2() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Icon(Icons.mark_email_read, size: 60, color: EliteColors.goldPrimary),
        const SizedBox(height: 20),
        Text('المصادقة البريدية', style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold)),
        Text('تم إرسال كود OTP إلى بريدك', style: GoogleFonts.cairo(color: Colors.grey)),
        const SizedBox(height: 30),
        GlassInput(controller: _emailOtpCtrl, label: 'كود الإيميل (6 أرقام)', icon: Icons.dialpad, keyboardType: TextInputType.number),
        const SizedBox(height: 40),
        EliteButton(text: 'تأكيد الإيميل', isLoading: _isLoading, onPressed: _processPhase2),
        const SizedBox(height: 20),
        TextButton(onPressed: () => setState(() => _authPhase = 0), child: Text('إلغاء والعودة', style: GoogleFonts.cairo(color: EliteColors.danger))),
      ],
    );
  }

  Widget _buildPhase3() {
    return Column(
      key: const ValueKey(2),
      children: [
        const Icon(Icons.security_update_good, size: 60, color: EliteColors.goldPrimary),
        const SizedBox(height: 20),
        Text('المصادقة النهائية', style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold)),
        Text('أدخل كود Google Authenticator', style: GoogleFonts.cairo(color: Colors.grey)),
        const SizedBox(height: 30),
        GlassInput(controller: _googleOtpCtrl, label: 'كود التطبيق (6 أرقام)', icon: Icons.lock_clock, keyboardType: TextInputType.number),
        const SizedBox(height: 40),
        EliteButton(text: 'فـك الـتـشـفـيـر', isLoading: _isLoading, onPressed: _processPhase3),
        const SizedBox(height: 20),
        TextButton(onPressed: () => setState(() => _authPhase = 0), child: Text('إلغاء والعودة', style: GoogleFonts.cairo(color: EliteColors.danger))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: EliteBackgroundPainter(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: EliteColors.glassFill, border: Border.all(color: EliteColors.glassBorderLight), borderRadius: BorderRadius.circular(30)),
                  // 🪄 الحركة السحرية لتغيير الشاشات في نفس المكان
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: _authPhase == 0 
                        ? _buildPhase1() 
                        : _authPhase == 1 
                            ? _buildPhase2() 
                            : _buildPhase3(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
