import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _googleAuthCtrl = TextEditingController();
  
  bool _isLoading = false;
  String _currentStep = 'login'; // login, otp, 2fa
  String _authTicket = '';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: GoogleFonts.cairo()), backgroundColor: Colors.red.shade800));
  }

  Future<void> _handleLogin() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().login(_usernameCtrl.text, _passwordCtrl.text);
      if (res.statusCode == 200 && res.data['data']['status'] == 'pending_email_otp') {
        setState(() {
          _authTicket = res.data['data']['auth_ticket'];
          _currentStep = 'otp';
        });
      } else if (res.statusCode == 200 && res.data['data']['status'] == 'authenticated') {
        _navigateToDashboard();
      }
    } catch (e) {
      _showError('بيانات الدخول غير صحيحة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOtp() async {
    if (_otpCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyEmail(_authTicket, _otpCtrl.text);
      if (res.statusCode == 200 && res.data['data']['status'] == 'pending_google_2fa') {
        setState(() => _currentStep = '2fa');
      }
    } catch (e) {
      _showError('رمز التحقق غير صحيح أو منتهي الصلاحية');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handle2FA() async {
    if (_googleAuthCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyGoogle(_authTicket, _googleAuthCtrl.text);
      if (res.statusCode == 200 && res.data['data']['status'] == 'authenticated') {
        _navigateToDashboard();
      }
    } catch (e) {
      _showError('رمز المصادقة الثنائية غير صحيح');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B101E),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 100, height: 100, errorBuilder: (ctx, err, stack) => const Icon(Icons.account_balance, size: 80, color: Color(0xFFD4AF37))),
                  const SizedBox(height: 16),
                  Text('Al-Muhandis Pay', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                  const SizedBox(height: 8),
                  Text('بوابة تسجيل الدخول الآمن', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 48),

                  if (_currentStep == 'login') ...[
                    GlassInput(controller: _usernameCtrl, label: 'اسم المستخدم أو البريد الإلكتروني', icon: Icons.person_outline),
                    const SizedBox(height: 16),
                    GlassInput(controller: _passwordCtrl, label: 'كلمة المرور', icon: Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 32),
                    EliteButton(text: 'تسجيل الدخول', isLoading: _isLoading, onPressed: _handleLogin),
                  ],

                  if (_currentStep == 'otp') ...[
                    Text('التحقق عبر البريد الإلكتروني', style: GoogleFonts.cairo(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    GlassInput(controller: _otpCtrl, label: 'رمز التحقق (OTP)', icon: Icons.mark_email_read_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 32),
                    EliteButton(text: 'متابعة', isLoading: _isLoading, onPressed: _handleOtp),
                  ],

                  if (_currentStep == '2fa') ...[
                    Text('المصادقة الثنائية (Google Authenticator)', style: GoogleFonts.cairo(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    GlassInput(controller: _googleAuthCtrl, label: 'رمز المصادقة الثنائية', icon: Icons.security, keyboardType: TextInputType.number),
                    const SizedBox(height: 32),
                    EliteButton(text: 'دخول', isLoading: _isLoading, onPressed: _handle2FA),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
