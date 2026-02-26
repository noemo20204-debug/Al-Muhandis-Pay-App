import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_engine.dart';
import 'dashboard_screen.dart';

// ════════════════════════════════════════════════════════════════
//  Al-Muhandis Pay — شاشة الدخول السيادية v3.0
//  Premium Banking Login Screen
// ════════════════════════════════════════════════════════════════
//  ✅ Glassmorphism + Particle System
//  ✅ AnimatedSwitcher بين الخطوات الثلاث
//  ✅ Dark/Light Theme ديناميكي
//  ✅ RTL-first مع دعم LTR
//  ✅ Logo shimmer + breathing glow
//  ✅ Haptic feedback على الأزرار
//  ✅ OTP auto-focus + countdown timer
//  ✅ Step progress indicator مع أنيميشن
// ════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // ═══════════════════════════════════════════
  //  المتحكمات
  // ═══════════════════════════════════════════
  final _usernameCtrl   = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _otpCtrl        = TextEditingController();
  final _googleAuthCtrl = TextEditingController();

  final _usernameFocus   = FocusNode();
  final _passwordFocus   = FocusNode();
  final _otpFocus        = FocusNode();
  final _googleAuthFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _currentStep = 'login'; // login → otp → 2fa
  String _authTicket = '';

  // ═══════════════════════════════════════════
  //  أنيميشن Controllers
  // ═══════════════════════════════════════════
  late AnimationController _logoBreathCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _stepTransitionCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _bgGradientCtrl;

  late Animation<double> _logoBreathAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _bgGradientAnim;

  // ═══════════════════════════════════════════
  //  الجسيمات (Particle System)
  // ═══════════════════════════════════════════
  final List<_FloatingParticle> _particles = [];
  final Random _random = Random();

  // ═══════════════════════════════════════════
  //  OTP Countdown
  // ═══════════════════════════════════════════
  Timer? _otpTimer;
  int _otpCountdown = 300; // 5 دقائق
  bool _canResendOtp = false;

  // ═══════════════════════════════════════════
  //  ألوان الثيم
  // ═══════════════════════════════════════════
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgPrimary    => _isDark ? const Color(0xFF030712) : const Color(0xFFF8F9FC);
  Color get _bgSecondary  => _isDark ? const Color(0xFF0B101E) : const Color(0xFFFFFFFF);
  Color get _cardBg       => _isDark ? const Color(0xFF0D1321).withOpacity(0.6) : Colors.white.withOpacity(0.7);
  Color get _glassBorder  => _isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFE2E8F0).withOpacity(0.8);
  Color get _textPrimary  => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _textSecondary=> _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _goldPrimary  => const Color(0xFFD4AF37);
  Color get _goldDark     => const Color(0xFFB8952C);
  Color get _inputBg      => _isDark ? const Color(0xFF111827).withOpacity(0.5) : const Color(0xFFF1F5F9).withOpacity(0.8);
  Color get _inputBorder  => _isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1);
  Color get _dangerColor  => const Color(0xFFEF4444);
  Color get _successColor => const Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    // تنفس اللوجو
    _logoBreathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _logoBreathAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _logoBreathCtrl, curve: Curves.easeInOutSine));

    // جسيمات الخلفية
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    // انتقال الخطوات
    _stepTransitionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // اهتزاز عند الخطأ
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    // شريط التقدم
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // تدرج الخلفية
    _bgGradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _bgGradientAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bgGradientCtrl, curve: Curves.easeInOutSine));
  }

  void _generateParticles() {
    for (int i = 0; i < 35; i++) {
      _particles.add(_FloatingParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.3 + 0.1,
        opacity: _random.nextDouble() * 0.4 + 0.1,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _startOtpTimer() {
    _otpCountdown = 300;
    _canResendOtp = false;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResendOtp = true);
      } else {
        if (mounted) setState(() => _otpCountdown--);
      }
    });
  }

  String get _otpTimerText {
    final m = (_otpCountdown ~/ 60).toString().padLeft(2, '0');
    final s = (_otpCountdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _logoBreathCtrl.dispose();
    _particleCtrl.dispose();
    _stepTransitionCtrl.dispose();
    _shakeCtrl.dispose();
    _progressCtrl.dispose();
    _bgGradientCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _googleAuthCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _otpFocus.dispose();
    _googleAuthFocus.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  منطق الدخول (Business Logic — بدون تغيير)
  // ═══════════════════════════════════════════════════════════

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 13))),
          ],
        ),
        backgroundColor: _dangerColor.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 13))),
          ],
        ),
        backgroundColor: _successColor.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (res.statusCode == 200 && res.data['data']['status'] == 'pending_email_otp') {
        _authTicket = res.data['data']['auth_ticket'];
        _progressCtrl.animateTo(0.33);
        _showSuccess('تم إرسال رمز التحقق إلى بريدك الإلكتروني');
        _startOtpTimer();
        setState(() => _currentStep = 'otp');
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _otpFocus.requestFocus();
        });
      } else if (res.statusCode == 200 && res.data['data']['status'] == 'authenticated') {
        _progressCtrl.animateTo(1.0);
        _navigateToDashboard(res);
      }
    } catch (e) {
      _showError('بيانات الدخول غير صحيحة');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      _showError('الرجاء إدخال رمز التحقق');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyEmail(_authTicket, _otpCtrl.text.trim());
      if (res.statusCode == 200 && res.data['data']['status'] == 'pending_google_2fa') {
        _progressCtrl.animateTo(0.66);
        setState(() => _currentStep = '2fa');
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _googleAuthFocus.requestFocus();
        });
      }
    } catch (e) {
      _showError('رمز التحقق غير صحيح أو منتهي الصلاحية');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handle2FA() async {
    if (_googleAuthCtrl.text.trim().isEmpty) {
      _showError('الرجاء إدخال رمز المصادقة الثنائية');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().verifyGoogle(_authTicket, _googleAuthCtrl.text.trim());
      if (res.statusCode == 200 && res.data['data']['status'] == 'authenticated') {
        _progressCtrl.animateTo(1.0);
        _navigateToDashboard(res);
      }
    } catch (e) {
      _showError('رمز المصادقة الثنائية غير صحيح');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(dynamic res) async {
    HapticFeedback.heavyImpact();
    
    // حفظ بيانات المستخدم
    try {
      final data = res.data['data'];
      if (data['token'] != null) {
        await ApiEngine().storage.write(key: 'jwt_token', value: data['token']);
      }
      if (data['user'] != null && data['user']['name'] != null) {
        await ApiEngine().storage.write(key: 'admin_name', value: data['user']['name']);
      }
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  البناء الرئيسي
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ─── الخلفية المتدرجة المتحركة ────────────
            AnimatedBuilder(
              animation: _bgGradientAnim,
              builder: (context, _) {
                final v = _bgGradientAnim.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isDark ? [
                        Color.lerp(const Color(0xFF030712), const Color(0xFF0B0F1A), v)!,
                        Color.lerp(const Color(0xFF0B101E), const Color(0xFF050A15), v)!,
                        Color.lerp(const Color(0xFF0D1321), const Color(0xFF0B101E), v)!,
                      ] : [
                        Color.lerp(const Color(0xFFF8F9FC), const Color(0xFFF0F4F8), v)!,
                        Color.lerp(const Color(0xFFFFFFFF), const Color(0xFFF5F3EF), v)!,
                        Color.lerp(const Color(0xFFFAF8F5), const Color(0xFFF8F9FC), v)!,
                      ],
                    ),
                  ),
                );
              },
            ),

            // ─── الهالة الذهبية العلوية ───────────────
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.3,
              child: AnimatedBuilder(
                animation: _logoBreathAnim,
                builder: (context, _) {
                  return Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _goldPrimary.withOpacity(0.06 * _logoBreathAnim.value),
                          _goldPrimary.withOpacity(0.02 * _logoBreathAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── الهالة الذهبية السفلية ───────────────
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.2,
              child: AnimatedBuilder(
                animation: _logoBreathAnim,
                builder: (context, _) {
                  return Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _goldPrimary.withOpacity(0.04 * _logoBreathAnim.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ─── الجسيمات العائمة ─────────────────────
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                    color: _isDark ? _goldPrimary : _goldDark,
                  ),
                );
              },
            ),

            // ─── المحتوى الرئيسي ─────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final shakeOffset = sin(_shakeAnim.value * pi * 4) * 8 * (1 - _shakeAnim.value);
                      return Transform.translate(offset: Offset(shakeOffset, 0), child: child);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(),
                        const SizedBox(height: 12),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildSubtitle(),
                        const SizedBox(height: 32),
                        _buildProgressIndicator(),
                        const SizedBox(height: 28),
                        _buildStepContent(),
                        const SizedBox(height: 40),
                        _buildFooter(),
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

  // ═══════════════════════════════════════════════════════════
  //  اللوجو (مع تأثير التنفس والهالة)
  // ═══════════════════════════════════════════════════════════

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoBreathAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_logoBreathAnim.value * 0.05),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _goldPrimary.withOpacity(0.15 + (_logoBreathAnim.value * 0.1)),
                  blurRadius: 30 + (_logoBreathAnim.value * 15),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _goldPrimary.withOpacity(0.08),
                        _goldDark.withOpacity(0.04),
                      ],
                    ),
                    border: Border.all(
                      color: _goldPrimary.withOpacity(0.2 + (_logoBreathAnim.value * 0.1)),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 60, height: 60,
                      errorBuilder: (_, __, ___) => ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_goldPrimary, _goldDark, _goldPrimary],
                          stops: [0.0, 0.5 + (_logoBreathAnim.value * 0.2), 1.0],
                        ).createShader(bounds),
                        child: const Icon(Icons.account_balance, size: 44, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [_goldPrimary, const Color(0xFFE8D48B), _goldPrimary],
      ).createShader(bounds),
      child: Text(
        'Al-Muhandis Pay',
        style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSubtitle() {
    String subtitle;
    switch (_currentStep) {
      case 'otp':  subtitle = 'التحقق عبر البريد الإلكتروني'; break;
      case '2fa':  subtitle = 'المصادقة الثنائية'; break;
      default:     subtitle = 'بوابة تسجيل الدخول الآمن';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        subtitle,
        key: ValueKey(subtitle),
        style: GoogleFonts.cairo(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  شريط التقدم (Step Progress)
  // ═══════════════════════════════════════════════════════════

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (context, _) {
        return Column(
          children: [
            // النقاط
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepDot(0, 'تسجيل', _currentStep == 'login'),
                _buildStepLine(_progressCtrl.value >= 0.33),
                _buildStepDot(1, 'البريد', _currentStep == 'otp'),
                _buildStepLine(_progressCtrl.value >= 0.66),
                _buildStepDot(2, 'المصادقة', _currentStep == '2fa'),
              ],
            ),
            const SizedBox(height: 12),
            // الشريط
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _inputBorder.withOpacity(0.3),
              ),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _progressCtrl.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(colors: [_goldPrimary, _goldDark]),
                    boxShadow: [BoxShadow(color: _goldPrimary.withOpacity(0.4), blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepDot(int index, String label, bool isActive) {
    final double progress = _progressCtrl.value;
    final bool isCompleted = (index == 0 && progress >= 0.33) || (index == 1 && progress >= 0.66) || (index == 2 && progress >= 1.0);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: isActive ? 36 : 28,
          height: isActive ? 36 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? _goldPrimary : (isActive ? _goldPrimary.withOpacity(0.15) : _inputBg),
            border: Border.all(
              color: isActive ? _goldPrimary : (isCompleted ? _goldPrimary : _inputBorder),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: _goldPrimary.withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: Center(
            child: isCompleted
              ? const Icon(Icons.check, color: Colors.black, size: 16)
              : Text('${index + 1}', style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? _goldPrimary : _textSecondary,
                )),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.cairo(
          fontSize: 10,
          color: isActive ? _goldPrimary : _textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        )),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? _goldPrimary.withOpacity(0.6) : _inputBorder.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  محتوى الخطوات (مع AnimatedSwitcher)
  // ═══════════════════════════════════════════════════════════

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _currentStep == 'login'
          ? _buildLoginStep()
          : _currentStep == 'otp'
              ? _buildOtpStep()
              : _build2faStep(),
    );
  }

  // ═══════════════════════════════════════════
  //  خطوة 1: تسجيل الدخول
  // ═══════════════════════════════════════════

  Widget _buildLoginStep() {
    return _GlassCard(
      key: const ValueKey('login'),
      cardBg: _cardBg,
      glassBorder: _glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.login, 'تسجيل الدخول'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _usernameCtrl,
            focusNode: _usernameFocus,
            label: 'اسم المستخدم أو البريد الإلكتروني',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            label: 'كلمة المرور',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 28),
          _buildActionButton('تسجيل الدخول', Icons.arrow_forward_rounded, _handleLogin),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  خطوة 2: رمز البريد الإلكتروني (OTP)
  // ═══════════════════════════════════════════

  Widget _buildOtpStep() {
    return _GlassCard(
      key: const ValueKey('otp'),
      cardBg: _cardBg,
      glassBorder: _glassBorder,
      child: Column(
        children: [
          // أيقونة البريد الكبيرة
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _goldPrimary.withOpacity(0.1),
              border: Border.all(color: _goldPrimary.withOpacity(0.2)),
            ),
            child: Icon(Icons.mark_email_read_rounded, color: _goldPrimary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('تم إرسال رمز التحقق', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 6),
          Text('يرجى إدخال الرمز المرسل إلى بريدك الإلكتروني', style: GoogleFonts.cairo(fontSize: 12, color: _textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 8),

          // العداد التنازلي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _canResendOtp ? _dangerColor.withOpacity(0.1) : _goldPrimary.withOpacity(0.08),
              border: Border.all(color: _canResendOtp ? _dangerColor.withOpacity(0.2) : _goldPrimary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_canResendOtp ? Icons.warning_amber : Icons.timer_outlined, size: 16,
                    color: _canResendOtp ? _dangerColor : _goldPrimary),
                const SizedBox(width: 6),
                Text(
                  _canResendOtp ? 'انتهت صلاحية الرمز' : 'صالح لمدة $_otpTimerText',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600,
                      color: _canResendOtp ? _dangerColor : _goldPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _otpCtrl,
            focusNode: _otpFocus,
            label: 'رمز التحقق (OTP)',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleOtp(),
          ),
          const SizedBox(height: 24),
          _buildActionButton('تأكيد الرمز', Icons.verified_outlined, _handleOtp),
          const SizedBox(height: 12),
          _buildBackButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  خطوة 3: Google Authenticator
  // ═══════════════════════════════════════════

  Widget _build2faStep() {
    return _GlassCard(
      key: const ValueKey('2fa'),
      cardBg: _cardBg,
      glassBorder: _glassBorder,
      child: Column(
        children: [
          // أيقونة الحماية
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _goldPrimary.withOpacity(0.1),
              border: Border.all(color: _goldPrimary.withOpacity(0.2)),
            ),
            child: Icon(Icons.security_rounded, color: _goldPrimary, size: 30),
          ),
          const SizedBox(height: 16),
          Text('المصادقة الثنائية', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 6),
          Text('أدخل الرمز من تطبيق Google Authenticator', style: GoogleFonts.cairo(fontSize: 12, color: _textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _googleAuthCtrl,
            focusNode: _googleAuthFocus,
            label: 'رمز المصادقة الثنائية',
            icon: Icons.shield_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handle2FA(),
          ),
          const SizedBox(height: 24),
          _buildActionButton('دخول آمن', Icons.lock_open_rounded, _handle2FA),
          const SizedBox(height: 12),
          _buildBackButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  المكونات المشتركة
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _goldPrimary.withOpacity(0.1),
          ),
          child: Icon(icon, color: _goldPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLength,
    ValueChanged<String>? onSubmitted,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _inputBg,
            border: Border.all(
              color: isFocused ? _goldPrimary.withOpacity(0.6) : _inputBorder,
              width: isFocused ? 1.5 : 1,
            ),
            boxShadow: isFocused ? [
              BoxShadow(color: _goldPrimary.withOpacity(0.08), blurRadius: 12, spreadRadius: 0),
            ] : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && _obscurePassword,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLength: maxLength,
            onSubmitted: onSubmitted,
            style: GoogleFonts.cairo(fontSize: 15, color: _textPrimary, fontWeight: FontWeight.w500),
            cursorColor: _goldPrimary,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.cairo(fontSize: 13, color: isFocused ? _goldPrimary : _textSecondary),
              floatingLabelStyle: GoogleFonts.cairo(fontSize: 13, color: _goldPrimary, fontWeight: FontWeight.w600),
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                child: Icon(icon, size: 20, color: isFocused ? _goldPrimary : _textSecondary),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 42),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: _textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _isLoading ? null : LinearGradient(
            colors: [_goldPrimary, _goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: _isLoading ? _goldPrimary.withOpacity(0.3) : null,
          boxShadow: _isLoading ? [] : [
            BoxShadow(color: _goldPrimary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _isLoading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: _goldPrimary),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(text, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0A0F18))),
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: const Color(0xFF0A0F18)),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          if (_currentStep == '2fa') {
            _currentStep = 'otp';
            _progressCtrl.animateTo(0.33);
            _googleAuthCtrl.clear();
          } else if (_currentStep == 'otp') {
            _currentStep = 'login';
            _progressCtrl.animateTo(0);
            _otpCtrl.clear();
            _otpTimer?.cancel();
          }
        });
      },
      icon: Icon(Icons.arrow_back_rounded, size: 18, color: _textSecondary),
      label: Text('رجوع', style: GoogleFonts.cairo(fontSize: 13, color: _textSecondary)),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 12, color: _textSecondary.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text('محمي بتشفير AES-256 • مصادقة ثلاثية', style: GoogleFonts.cairo(fontSize: 10, color: _textSecondary.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 6),
        Text('© ${DateTime.now().year} Al-Muhandis Financial Systems',
          style: GoogleFonts.cairo(fontSize: 10, color: _textSecondary.withOpacity(0.3)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  بطاقة زجاجية (Glass Card)
// ═══════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color cardBg;
  final Color glassBorder;

  const _GlassCard({super.key, required this.child, required this.cardBg, required this.glassBorder});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: glassBorder, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  الجسيمات العائمة (Particle System)
// ═══════════════════════════════════════════════════════════════

class _FloatingParticle {
  double x, y, size, speed, opacity, angle;
  _FloatingParticle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.angle});
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width + sin(progress * 2 * pi * p.speed + p.angle) * 30;
      final dy = p.y * size.height + cos(progress * 2 * pi * p.speed * 0.7 + p.angle) * 20;

      final paint = Paint()
        ..color = color.withOpacity(p.opacity * (0.5 + 0.5 * sin(progress * 2 * pi + p.angle)))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8);

      canvas.drawCircle(Offset(dx % size.width, dy % size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
