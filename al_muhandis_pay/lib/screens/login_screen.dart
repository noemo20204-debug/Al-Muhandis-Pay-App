import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart' show DioException;
import '../services/api_engine.dart';
import 'dashboard_screen.dart';

/// ════════════════════════════════════════════════════════════════
///  Al-Muhandis Pay — شاشة الدخول السيادية المظلمة (معدلة)
/// ════════════════════════════════════════════════════════════════

class _C {
  static const Color nightBg     = Color(0xFF0B101E);
  static const Color cardBg      = Color(0xFF161C2D);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark    = Color(0xFFB8952C);
  static const Color goldLight   = Color(0xFFE8D48B);
  static const Color danger      = Color(0xFFE74C3C);
  static const Color success     = Color(0xFF2ECC71);
  static const Color glassBorder = Color(0xFF1E2740);
  static const Color inputBg     = Color(0xFF0F1524);
  static const Color textMuted   = Color(0xFF64748B);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl      = TextEditingController();
  final _googleCtrl   = TextEditingController();

  String _phase = 'credentials';
  String? _authTicket;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _passwordCtrl.dispose(); _otpCtrl.dispose(); _googleCtrl.dispose();
    _fadeCtrl.dispose(); _pulseCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  المرحلة 1: تسجيل الدخول
  // ═══════════════════════════════════════════════════════════
  Future<void> _submitCredentials() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('الرجاء إدخال اسم المستخدم وكلمة المرور.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // ⚠️ استخدام المحرك الأصلي بدلاً من الطلب المباشر
      final res = await ApiEngine().login(username, password);

      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;

        if (data['status'] == 'authenticated') {
          await _handleAuthenticated(data);
          return;
        }

        if (data['status'] == 'pending_email_otp') {
          setState(() {
            _authTicket = data['auth_ticket'];
            _phase = 'email_otp';
            _isLoading = false;
            _successMessage = 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.';
          });
          _animatePhaseChange();
          return;
        }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  // ═══════════════════════════════════════════════════════════
  //  المرحلة 2: كود الإيميل
  // ═══════════════════════════════════════════════════════════
  Future<void> _submitEmailOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showError('الرجاء إدخال رمز التحقق المكوّن من 6 أرقام.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      // ⚠️ استخدام المحرك الأصلي
      final res = await ApiEngine().verifyEmail(_authTicket ?? '', otp);

      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        if (data['status'] == 'pending_google_2fa') {
          setState(() {
            _phase = 'google_2fa'; _isLoading = false;
            _successMessage = 'تم التحقق من البريد. أدخل رمز Google Authenticator.';
          });
          _animatePhaseChange();
          return;
        }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  // ═══════════════════════════════════════════════════════════
  //  المرحلة 3: Google Authenticator
  // ═══════════════════════════════════════════════════════════
  Future<void> _submitGoogle2fa() async {
    final code = _googleCtrl.text.trim();
    if (code.isEmpty || code.length != 6) {
      _showError('الرجاء إدخال رمز المصادقة المكوّن من 6 أرقام.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      // ⚠️ استخدام المحرك الأصلي
      final res = await ApiEngine().verifyGoogle(_authTicket ?? '', code);

      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        if (data['status'] == 'authenticated') {
          await _handleAuthenticated(data);
          return;
        }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  // ═══════════════════════════════════════════════════════════
  //  دوال مساعدة
  // ═══════════════════════════════════════════════════════════
  Future<void> _handleAuthenticated(Map<String, dynamic> data) async {
    final token = data['token'];
    final user = data['user'];
    await ApiEngine().storage.write(key: 'jwt_token', value: token);
    await ApiEngine().storage.write(key: 'admin_name', value: user['name'] ?? '');
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
  }

  void _handleApiError(dynamic e) {
    String msg = 'خطأ في الاتصال بالسيرفر.';
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) msg = data['message']?.toString() ?? data['msg']?.toString() ?? msg;
    }
    _showError(msg);
  }

  void _showError(String msg) => setState(() { _isLoading = false; _errorMessage = msg; _successMessage = null; });

  void _animatePhaseChange() { _fadeCtrl.reset(); _fadeCtrl.forward(); }

  void _onSubmit() {
    switch (_phase) {
      case 'credentials': _submitCredentials(); break;
      case 'email_otp':   _submitEmailOtp(); break;
      case 'google_2fa':  _submitGoogle2fa(); break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  🎨 البناء الرئيسي
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.nightBg,
        body: Stack(
          children: [
            const _OrbitalBackground(),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),

                        // ═══ الشعار النابض (اللوجو الخاص بك) ═══
                        _buildPulsingLogo(),
                        const SizedBox(height: 20),

                        Text('Al-Muhandis Pay', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: _C.goldPrimary, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(_phaseSubtitle, style: GoogleFonts.cairo(fontSize: 13, color: _C.textMuted)),
                        const SizedBox(height: 36),

                        // ═══ مؤشر المراحل بالأيقونات ═══
                        _buildPhaseStepper(),
                        const SizedBox(height: 28),

                        // ═══ رسائل ═══
                        if (_successMessage != null) _buildBanner(_successMessage!, false),
                        if (_errorMessage != null) _buildBanner(_errorMessage!, true),
                        if (_successMessage != null || _errorMessage != null) const SizedBox(height: 16),

                        // ═══ بطاقة الإدخال ═══
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _C.cardBg, borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _C.glassBorder),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: _buildPhaseFields(),
                        ),
                        const SizedBox(height: 24),

                        // ═══ زر الإرسال ═══
                        _buildSubmitButton(),
                        const SizedBox(height: 40),

                        // ═══ التذييل ═══
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.lock_outline, size: 12, color: _C.textMuted),
                          const SizedBox(width: 6),
                          Text('نظام محمي بتشفير AES-256', style: GoogleFonts.cairo(fontSize: 11, color: _C.textMuted)),
                        ]),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingLogo() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Opacity(opacity: _pulseAnim.value, child: child),
      child: Container(
        width: 85, height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_C.goldPrimary, _C.goldDark]),
          boxShadow: [BoxShadow(color: _C.goldPrimary.withOpacity(0.25), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.nightBg),
            child: Center(
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  width: 55, height: 55, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.account_balance, color: _C.goldPrimary, size: 36),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _phaseSubtitle {
    switch (_phase) {
      case 'credentials': return 'بوابة الدخول الآمن للنظام المالي';
      case 'email_otp':   return 'تم إرسال رمز التحقق إلى بريدك الإلكتروني';
      case 'google_2fa':  return 'أدخل الرمز من تطبيق المصادقة الثنائية';
      default: return '';
    }
  }

  Widget _buildPhaseStepper() {
    final phases = [
      {'icon': Icons.lock_outline},
      {'icon': Icons.mail_outline},
      {'icon': Icons.security},
    ];
    final idx = _phase == 'credentials' ? 0 : _phase == 'email_otp' ? 1 : 2;

    return Row(
      children: List.generate(phases.length, (i) {
        final bool active = i <= idx;
        final bool current = i == idx;
        final iconData = phases[i]['icon'] as IconData;

        return Expanded(
          child: Row(children: [
            if (i > 0) Expanded(child: Container(height: 1.5, color: active ? _C.goldPrimary : _C.glassBorder)),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current ? _C.goldPrimary : active ? _C.goldPrimary.withOpacity(0.3) : _C.glassBorder,
                border: current ? Border.all(color: _C.goldLight, width: 2) : null,
              ),
              child: Center(
                child: Icon(
                  active && !current ? Icons.check : iconData,
                  size: 16,
                  color: current ? Colors.black : active ? _C.goldPrimary : _C.textMuted,
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildPhaseFields() {
    switch (_phase) {
      case 'credentials':
        return Column(children: [
          _field(_usernameCtrl, 'اسم المستخدم', Icons.person_outline, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field(_passwordCtrl, 'كلمة المرور', Icons.lock_outline, obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: _C.textMuted, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )),
        ]);

      case 'email_otp':
        return Column(children: [
          _infoBox(Icons.mail_outline, 'تحقق من صندوق الوارد (Inbox) أو المهملات (Spam)'),
          const SizedBox(height: 16),
          _field(_otpCtrl, 'رمز التحقق (6 أرقام)', Icons.pin_outlined, keyboardType: TextInputType.number, maxLength: 6, centered: true),
        ]);

      case 'google_2fa':
        return Column(children: [
          _infoBox(Icons.security, 'افتح تطبيق المصادقة الثنائية في هاتفك'),
          const SizedBox(height: 16),
          _field(_googleCtrl, 'رمز المصادقة', Icons.shield_outlined, keyboardType: TextInputType.number, maxLength: 6, centered: true),
        ]);

      default: return const SizedBox();
    }
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.goldPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.goldPrimary.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: _C.goldPrimary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.cairo(fontSize: 12, color: _C.goldLight))),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType keyboardType = TextInputType.text, bool obscure = false,
    Widget? suffixIcon, int? maxLength, bool centered = false,
  }) {
    return TextField(
      controller: ctrl, keyboardType: keyboardType, obscureText: obscure, maxLength: maxLength,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, letterSpacing: centered ? 8 : 0),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.cairo(color: _C.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: _C.goldPrimary, size: 20), suffixIcon: suffixIcon,
        counterText: '', filled: true, fillColor: _C.inputBg,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _C.goldPrimary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onSubmitted: (_) => _onSubmit(),
    );
  }

  Widget _buildSubmitButton() {
    String label; IconData icon;
    switch (_phase) {
      case 'credentials': label = 'تسجيل الدخول'; icon = Icons.login_rounded; break;
      case 'email_otp':   label = 'التحقق من الرمز'; icon = Icons.verified_outlined; break;
      case 'google_2fa':  label = 'تأكيد الدخول'; icon = Icons.security; break;
      default: label = 'متابعة'; icon = Icons.arrow_forward;
    }

    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.goldPrimary, foregroundColor: Colors.black,
          disabledBackgroundColor: _C.goldPrimary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 20), const SizedBox(width: 10),
                Text(label, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
      ),
    );
  }

  Widget _buildBanner(String msg, bool isError) {
    final c = isError ? _C.danger : _C.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.25))),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: c, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.cairo(fontSize: 12, color: c))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  الخلفية المدارية
// ═══════════════════════════════════════════════════════════════
class _OrbitalBackground extends StatefulWidget {
  const _OrbitalBackground();
  @override
  State<_OrbitalBackground> createState() => _OrbitalBackgroundState();
}

class _OrbitalBackgroundState extends State<_OrbitalBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(painter: _OrbitalPainter(_ctrl.value), size: Size.infinite),
    );
  }
}

class _OrbitalPainter extends CustomPainter {
  final double progress;
  _OrbitalPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.15;
    final cy = size.height * 0.25;
    final paint = Paint()..color = _C.goldPrimary.withOpacity(0.04)..style = PaintingStyle.stroke..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final r = 80.0 * i;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(progress * 2 * pi * (i.isEven ? 1 : -1) * 0.3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.2));
      canvas.restore();
    }

    final a = progress * 2 * pi;
    canvas.drawCircle(
      Offset(cx + cos(a) * 200, cy + sin(a) * 120), 6,
      Paint()..color = _C.goldPrimary.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter old) => old.progress != progress;
}
