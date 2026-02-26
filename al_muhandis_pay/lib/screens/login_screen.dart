import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart' show DioException;
import '../services/api_engine.dart';
import 'dashboard_screen.dart';

class _C {
  static const Color nightBg     = Color(0xFF030712);
  static const Color nightBg2    = Color(0xFF0B101E);
  static const Color cardBg      = Color(0xFF0D1321);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark    = Color(0xFFB8952C);
  static const Color goldLight   = Color(0xFFE8D48B);
  static const Color danger      = Color(0xFFEF4444);
  static const Color success     = Color(0xFF22C55E);
  static const Color glassBorder = Color(0xFF1E293B);
  static const Color inputBg     = Color(0xFF0F1524);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color textLight   = Color(0xFF94A3B8);
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

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _otpFocus      = FocusNode();
  final _googleFocus   = FocusNode();

  String _phase = 'credentials';
  String? _authTicket;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  Timer? _otpTimer;
  int _otpSeconds = 300;

  late AnimationController _pulseCtrl, _particleCtrl, _fadeCtrl, _shakeCtrl, _progressCtrl, _glowCtrl;
  late Animation<double> _pulseAnim, _fadeAnim, _shakeAnim, _glowAnim;
  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOutSine));
  }

  void _generateParticles() {
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(x: _rng.nextDouble(), y: _rng.nextDouble(), size: _rng.nextDouble() * 2.5 + 0.8, speed: _rng.nextDouble() * 0.25 + 0.08, opacity: _rng.nextDouble() * 0.35 + 0.05, angle: _rng.nextDouble() * 2 * pi));
    }
  }

  void _startOtpTimer() {
    _otpSeconds = 300;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_otpSeconds <= 0) t.cancel();
      else if (mounted) setState(() => _otpSeconds--);
    });
  }

  String get _otpTimerText => '${(_otpSeconds ~/ 60).toString().padLeft(2, '0')}:${(_otpSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _pulseCtrl.dispose(); _particleCtrl.dispose(); _fadeCtrl.dispose(); _shakeCtrl.dispose(); _progressCtrl.dispose(); _glowCtrl.dispose();
    _usernameCtrl.dispose(); _passwordCtrl.dispose(); _otpCtrl.dispose(); _googleCtrl.dispose();
    _usernameFocus.dispose(); _passwordFocus.dispose(); _otpFocus.dispose(); _googleFocus.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitCredentials() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) { _showError('الرجاء إدخال اسم المستخدم وكلمة المرور.'); return; }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await ApiEngine().login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        if (data['status'] == 'authenticated') { await _handleAuthenticated(data); return; }
        if (data['status'] == 'pending_email_otp') {
          _authTicket = data['auth_ticket']; _progressCtrl.animateTo(0.33); _startOtpTimer();
          setState(() { _phase = 'email_otp'; _isLoading = false; _successMessage = 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.'; _errorMessage = null; });
          _animatePhaseChange();
          Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _otpFocus.requestFocus(); });
          return;
        }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  Future<void> _submitEmailOtp() async {
    if (_otpCtrl.text.trim().length != 6) { _showError('الرجاء إدخال رمز التحقق المكوّن من 6 أرقام.'); return; }
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    try {
      final res = await ApiEngine().verifyEmail(_authTicket ?? '', _otpCtrl.text.trim());
      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        if (data['status'] == 'pending_google_2fa') {
          _progressCtrl.animateTo(0.66);
          setState(() { _phase = 'google_2fa'; _isLoading = false; _successMessage = 'تم التحقق. أدخل رمز Google Authenticator.'; _errorMessage = null; });
          _animatePhaseChange();
          Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _googleFocus.requestFocus(); });
          return;
        }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  Future<void> _submitGoogle2fa() async {
    if (_googleCtrl.text.trim().length != 6) { _showError('الرجاء إدخال رمز المصادقة المكوّن من 6 أرقام.'); return; }
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    try {
      final res = await ApiEngine().verifyGoogle(_authTicket ?? '', _googleCtrl.text.trim());
      if (res.statusCode == 200) {
        final data = res.data['data'] ?? res.data;
        if (data['status'] == 'authenticated') { _progressCtrl.animateTo(1.0); await _handleAuthenticated(data); return; }
      }
      _showError('حدث خطأ غير متوقع.');
    } catch (e) { _handleApiError(e); }
  }

  Future<void> _handleAuthenticated(Map<String, dynamic> data) async {
    HapticFeedback.heavyImpact();
    await ApiEngine().storage.write(key: 'jwt_token', value: data['token']);
    await ApiEngine().storage.write(key: 'admin_name', value: data['user']['name'] ?? '');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const DashboardScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic), child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child)),
      transitionDuration: const Duration(milliseconds: 700),
    ));
  }

  void _handleApiError(dynamic e) {
    String msg = 'خطأ في الاتصال بالسيرفر.';
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) msg = data['message']?.toString() ?? data['msg']?.toString() ?? msg;
    }
    _showError(msg);
  }

  void _showError(String msg) { HapticFeedback.heavyImpact(); _shakeCtrl.forward(from: 0); setState(() { _isLoading = false; _errorMessage = msg; _successMessage = null; }); }
  void _animatePhaseChange() { _fadeCtrl.reset(); _fadeCtrl.forward(); }
  void _onSubmit() { switch (_phase) { case 'credentials': _submitCredentials(); break; case 'email_otp': _submitEmailOtp(); break; case 'google_2fa': _submitGoogle2fa(); break; } }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _C.nightBg,
        body: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_C.nightBg, _C.nightBg2, Color(0xFF0D1321)]))),
            _buildGoldenAura(size, top: -size.height * 0.12, left: -size.width * 0.25, sizeFactor: 0.75),
            _buildGoldenAura(size, bottom: -size.height * 0.08, right: -size.width * 0.15, sizeFactor: 0.55),
            const _OrbitalBackground(),
            AnimatedBuilder(animation: _particleCtrl, builder: (_, __) => CustomPaint(size: size, painter: _ParticlePainter(_particles, _particleCtrl.value, _C.goldPrimary))),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(offset: Offset(sin(_shakeAnim.value * pi * 4) * 8 * (1 - _shakeAnim.value), 0), child: child),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(_fadeAnim),
                        child: Column(
                          children: [
                            const SizedBox(height: 24), _buildLogo(), const SizedBox(height: 18), _buildAppName(), const SizedBox(height: 6), _buildPhaseSubtitle(), const SizedBox(height: 30), _buildStepIndicator(), const SizedBox(height: 24),
                            if (_successMessage != null) ...[_buildBanner(_successMessage!, false), const SizedBox(height: 14)],
                            if (_errorMessage != null) ...[_buildBanner(_errorMessage!, true), const SizedBox(height: 14)],
                            _buildFormCard(), const SizedBox(height: 24), _buildSubmitButton(),
                            if (_phase != 'credentials') ...[const SizedBox(height: 12), _buildBackButton()],
                            const SizedBox(height: 36), _buildFooter(), const SizedBox(height: 16),
                          ],
                        ),
                      ),
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

  Widget _buildGoldenAura(Size size, {double? top, double? bottom, double? left, double? right, required double sizeFactor}) {
    return Positioned(top: top, bottom: bottom, left: left, right: right, child: AnimatedBuilder(animation: _glowAnim, builder: (_, __) => Container(width: size.width * sizeFactor, height: size.width * sizeFactor, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_C.goldPrimary.withOpacity(0.05 * _glowAnim.value), _C.goldPrimary.withOpacity(0.015 * _glowAnim.value), Colors.transparent])))));
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          width: 96, height: 96,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_C.goldPrimary, _C.goldDark]), boxShadow: [BoxShadow(color: _C.goldPrimary.withOpacity(0.2 + (_pulseAnim.value - 0.88) * 1.5), blurRadius: 30 + (_pulseAnim.value - 0.88) * 80, spreadRadius: 2)]),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.nightBg), child: Center(child: ClipOval(child: Image.asset('assets/logo.png', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [_C.goldPrimary, _C.goldLight, _C.goldPrimary]).createShader(bounds), child: const Icon(Icons.account_balance, size: 38, color: Colors.white)))))),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() => ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [_C.goldPrimary, _C.goldLight, _C.goldPrimary]).createShader(bounds), child: Text('Al-Muhandis Pay', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)));
  Widget _buildPhaseSubtitle() => AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: Text(_phase == 'email_otp' ? 'التحقق عبر البريد الإلكتروني' : _phase == 'google_2fa' ? 'المصادقة الثنائية' : 'بوابة الدخول الآمن للنظام المالي', key: ValueKey(_phase), style: GoogleFonts.cairo(fontSize: 13, color: _C.textMuted)));

  Widget _buildStepIndicator() {
    final steps = [{'icon': Icons.lock_outline, 'label': 'تسجيل'}, {'icon': Icons.mail_outline, 'label': 'البريد'}, {'icon': Icons.security, 'label': 'المصادقة'}];
    final idx = _phase == 'credentials' ? 0 : _phase == 'email_otp' ? 1 : 2;
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) => Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(steps.length, (i) {
            final completed = (i == 0 && _progressCtrl.value >= 0.33) || (i == 1 && _progressCtrl.value >= 0.66) || (i == 2 && _progressCtrl.value >= 1.0);
            final active = i == idx;
            return Row(children: [
              if (i > 0) AnimatedContainer(duration: const Duration(milliseconds: 400), width: 36, height: 2, decoration: BoxDecoration(color: completed || active ? _C.goldPrimary.withOpacity(0.6) : _C.glassBorder, borderRadius: BorderRadius.circular(1))),
              Column(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 400), width: active ? 40 : 32, height: active ? 40 : 32, decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? _C.goldPrimary : (active ? _C.goldPrimary.withOpacity(0.12) : _C.glassBorder.withOpacity(0.4)), border: Border.all(color: active ? _C.goldPrimary : (completed ? _C.goldPrimary : _C.glassBorder), width: active ? 2 : 1), boxShadow: active ? [BoxShadow(color: _C.goldPrimary.withOpacity(0.25), blurRadius: 14)] : []), child: Center(child: completed ? const Icon(Icons.check, color: Colors.black, size: 16) : Icon(steps[i]['icon'] as IconData, size: 16, color: active ? _C.goldPrimary : _C.textMuted))),
                const SizedBox(height: 6), Text(steps[i]['label'] as String, style: GoogleFonts.cairo(fontSize: 10, color: active ? _C.goldPrimary : _C.textMuted, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
              ]),
            ]);
          })),
          const SizedBox(height: 10),
          Container(height: 3, margin: const EdgeInsets.symmetric(horizontal: 50), decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: _C.glassBorder.withOpacity(0.3)), child: FractionallySizedBox(alignment: AlignmentDirectional.centerStart, widthFactor: _progressCtrl.value, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [_C.goldPrimary, _C.goldDark]), boxShadow: [BoxShadow(color: _C.goldPrimary.withOpacity(0.4), blurRadius: 8)])))),
        ],
      ),
    );
  }

  Widget _buildFormCard() => ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: _C.cardBg.withOpacity(0.65), borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.glassBorder.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))]), child: AnimatedSwitcher(duration: const Duration(milliseconds: 450), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(anim), child: child)), child: _buildCurrentPhaseFields()))));

  Widget _buildCurrentPhaseFields() {
    switch (_phase) {
      case 'credentials':
        return Column(key: const ValueKey('cred'), crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSectionHeader(Icons.login_rounded, 'تسجيل الدخول'), const SizedBox(height: 22), _buildInputField(controller: _usernameCtrl, focusNode: _usernameFocus, label: 'اسم المستخدم أو البريد الإلكتروني', icon: Icons.person_outline_rounded, action: TextInputAction.next, onSubmitted: (_) => _passwordFocus.requestFocus()), const SizedBox(height: 14), _buildInputField(controller: _passwordCtrl, focusNode: _passwordFocus, label: 'كلمة المرور', icon: Icons.lock_outline_rounded, isPassword: true, action: TextInputAction.done, onSubmitted: (_) => _submitCredentials())]);
      case 'email_otp':
        return Column(key: const ValueKey('otp'), children: [_buildPhaseIcon(Icons.mark_email_read_rounded), const SizedBox(height: 14), Text('تم إرسال رمز التحقق', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 6), _buildInfoBox(Icons.mail_outline, 'تحقق من صندوق الوارد (Inbox) أو المهملات (Spam)'), const SizedBox(height: 12), _buildCountdownBadge(), const SizedBox(height: 18), _buildInputField(controller: _otpCtrl, focusNode: _otpFocus, label: 'رمز التحقق (6 أرقام)', icon: Icons.pin_outlined, keyboardType: TextInputType.number, maxLength: 6, centered: true, action: TextInputAction.done, onSubmitted: (_) => _submitEmailOtp())]);
      case 'google_2fa':
        return Column(key: const ValueKey('2fa'), children: [_buildPhaseIcon(Icons.security_rounded), const SizedBox(height: 14), Text('المصادقة الثنائية', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 6), _buildInfoBox(Icons.security, 'افتح تطبيق Google Authenticator في هاتفك'), const SizedBox(height: 18), _buildInputField(controller: _googleCtrl, focusNode: _googleFocus, label: 'رمز المصادقة الثنائية', icon: Icons.shield_outlined, keyboardType: TextInputType.number, maxLength: 6, centered: true, action: TextInputAction.done, onSubmitted: (_) => _submitGoogle2fa())]);
      default: return const SizedBox();
    }
  }

  Widget _buildSectionHeader(IconData icon, String title) => Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _C.goldPrimary.withOpacity(0.1)), child: Icon(icon, color: _C.goldPrimary, size: 20)), const SizedBox(width: 12), Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]);
  Widget _buildPhaseIcon(IconData icon) => Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: _C.goldPrimary.withOpacity(0.1), border: Border.all(color: _C.goldPrimary.withOpacity(0.2))), child: Icon(icon, color: _C.goldPrimary, size: 28));
  Widget _buildInfoBox(IconData icon, String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _C.goldPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.goldPrimary.withOpacity(0.12))), child: Row(children: [Icon(icon, color: _C.goldPrimary, size: 18), const SizedBox(width: 10), Expanded(child: Text(text, style: GoogleFonts.cairo(fontSize: 11, color: _C.goldLight)))]));
  Widget _buildCountdownBadge() { final expired = _otpSeconds <= 0; return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: expired ? _C.danger.withOpacity(0.1) : _C.goldPrimary.withOpacity(0.07), border: Border.all(color: expired ? _C.danger.withOpacity(0.2) : _C.goldPrimary.withOpacity(0.15))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(expired ? Icons.warning_amber : Icons.timer_outlined, size: 15, color: expired ? _C.danger : _C.goldPrimary), const SizedBox(width: 6), Text(expired ? 'انتهت صلاحية الرمز' : 'صالح لمدة $_otpTimerText', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: expired ? _C.danger : _C.goldPrimary))])); }

  Widget _buildInputField({required TextEditingController controller, required FocusNode focusNode, required String label, required IconData icon, bool isPassword = false, TextInputType keyboardType = TextInputType.text, TextInputAction action = TextInputAction.next, int? maxLength, bool centered = false, ValueChanged<String>? onSubmitted}) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (_, __) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _C.inputBg, border: Border.all(color: focused ? _C.goldPrimary.withOpacity(0.6) : _C.glassBorder, width: focused ? 1.5 : 1), boxShadow: focused ? [BoxShadow(color: _C.goldPrimary.withOpacity(0.08), blurRadius: 14)] : []),
          child: TextField(
            controller: controller, focusNode: focusNode, obscureText: isPassword && _obscurePassword, keyboardType: keyboardType, textInputAction: action, maxLength: maxLength, textAlign: centered ? TextAlign.center : TextAlign.start, onSubmitted: onSubmitted,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: centered ? 8 : 0), cursorColor: _C.goldPrimary,
            decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo(fontSize: 12, color: focused ? _C.goldPrimary : _C.textMuted), floatingLabelStyle: GoogleFonts.cairo(fontSize: 12, color: _C.goldPrimary, fontWeight: FontWeight.w600), prefixIcon: Padding(padding: const EdgeInsetsDirectional.only(start: 14, end: 8), child: Icon(icon, size: 20, color: focused ? _C.goldPrimary : _C.textMuted)), prefixIconConstraints: const BoxConstraints(minWidth: 42), suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: _C.textMuted), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), counterText: ''),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    String label; IconData icon;
    switch (_phase) { case 'credentials': label = 'تسجيل الدخول'; icon = Icons.login_rounded; break; case 'email_otp': label = 'التحقق من الرمز'; icon = Icons.verified_outlined; break; case 'google_2fa': label = 'تأكيد الدخول'; icon = Icons.lock_open_rounded; break; default: label = 'متابعة'; icon = Icons.arrow_forward; }
    return SizedBox(width: double.infinity, height: 56, child: AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: _isLoading ? null : const LinearGradient(colors: [_C.goldPrimary, _C.goldDark]), color: _isLoading ? _C.goldPrimary.withOpacity(0.25) : null, boxShadow: _isLoading ? [] : [BoxShadow(color: _C.goldPrimary.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))]), child: Material(color: Colors.transparent, child: InkWell(onTap: _isLoading ? null : () { HapticFeedback.lightImpact(); _onSubmit(); }, borderRadius: BorderRadius.circular(16), child: Center(child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.goldPrimary)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0A0F18))), const SizedBox(width: 8), Icon(icon, size: 20, color: const Color(0xFF0A0F18))]))))));
  }

  Widget _buildBackButton() => TextButton.icon(onPressed: () { if (_phase == 'google_2fa') { _progressCtrl.animateTo(0.33); _googleCtrl.clear(); setState(() { _phase = 'email_otp'; _errorMessage = null; _successMessage = null; }); } else if (_phase == 'email_otp') { _progressCtrl.animateTo(0); _otpCtrl.clear(); _otpTimer?.cancel(); setState(() { _phase = 'credentials'; _errorMessage = null; _successMessage = null; }); } _animatePhaseChange(); }, icon: const Icon(Icons.arrow_back_rounded, size: 18, color: _C.textMuted), label: Text('رجوع', style: GoogleFonts.cairo(fontSize: 13, color: _C.textMuted)));
  Widget _buildBanner(String msg, bool isError) { final c = isError ? _C.danger : _C.success; return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.2))), child: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: c, size: 18), const SizedBox(width: 10), Expanded(child: Text(msg, style: GoogleFonts.cairo(fontSize: 12, color: c)))])); }
  Widget _buildFooter() => Column(children: [Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline, size: 11, color: _C.textMuted.withOpacity(0.5)), const SizedBox(width: 4), Text('محمي بتشفير AES-256 • مصادقة ثلاثية', style: GoogleFonts.cairo(fontSize: 10, color: _C.textMuted.withOpacity(0.5)))]), const SizedBox(height: 4), Text('© ${DateTime.now().year} Al-Muhandis Financial Systems', style: GoogleFonts.cairo(fontSize: 9, color: _C.textMuted.withOpacity(0.3)))]);
}

class _OrbitalBackground extends StatefulWidget { const _OrbitalBackground(); @override State<_OrbitalBackground> createState() => _OrbitalBackgroundState(); }
class _OrbitalBackgroundState extends State<_OrbitalBackground> with SingleTickerProviderStateMixin { late AnimationController _ctrl; @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(); } @override void dispose() { _ctrl.dispose(); super.dispose(); } @override Widget build(BuildContext context) => AnimatedBuilder(animation: _ctrl, builder: (_, __) => CustomPaint(painter: _OrbitalPainter(_ctrl.value), size: Size.infinite)); }

class _OrbitalPainter extends CustomPainter {
  final double t;
  _OrbitalPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.15;
    final cy = size.height * 0.26;
    final paint = Paint()..color = _C.goldPrimary.withOpacity(0.03)..style = PaintingStyle.stroke..strokeWidth = 0.8;

    for (int i = 1; i <= 5; i++) {
      final r = 70.0 * i;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(t * 2 * pi * (i.isEven ? 1 : -1) * 0.25);
      // 🟢 هنا تم إصلاح خطأ الريشة (paint) المفقودة 🟢
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.15), paint);
      canvas.restore();
    }

    final a = t * 2 * pi;
    canvas.drawCircle(Offset(cx + cos(a) * 220, cy + sin(a) * 130), 5, Paint()..color = _C.goldPrimary.withOpacity(0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(Offset(cx + cos(a + pi) * 160, cy + sin(a + pi) * 95), 3.5, Paint()..color = _C.goldPrimary.withOpacity(0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter old) => true;
}

class _Particle { final double x, y, size, speed, opacity, angle; _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.angle}); }
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles; final double progress; final Color color;
  _ParticlePainter(this.particles, this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width + sin(progress * 2 * pi * p.speed + p.angle) * 25;
      final dy = p.y * size.height + cos(progress * 2 * pi * p.speed * 0.6 + p.angle) * 18;
      final op = p.opacity * (0.5 + 0.5 * sin(progress * 2 * pi + p.angle));
      canvas.drawCircle(Offset(dx % size.width, dy % size.height), p.size, Paint()..color = color.withOpacity(op)..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.7));
    }
  }
  @override bool shouldRepaint(covariant _ParticlePainter old) => true;
}
