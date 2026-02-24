import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

void main() {
  runApp(const AlMuhandisEnterpriseApp());
}

// ==========================================
// 1. القلب النابض والإعدادات السيادية (Theme)
// ==========================================
class AlMuhandisEnterpriseApp extends StatelessWidget {
  const AlMuhandisEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Al-Muhandis Pay Enterprise',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF030712), // كحلي ليلي عميق
        primaryColor: const Color(0xFFD4AF37), // ذهبي سيادي
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFF1E293B),
          surface: Color(0xFF0F172A),
        ),
      ),
      home: const SplashScreen(), // البداية من الشاشة الافتتاحية
    );
  }
}

// ==========================================
// 2. الشاشة الافتتاحية المتحركة (Splash Screen)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد حركات الأنيميشن البنكية الفاخرة
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();

    // التحقق المسبق من وجود توكن، ثم النقل لشاشة الدخول
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const SecureLoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), Color(0xFF030712)],
            radius: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 50, spreadRadius: 10),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', height: 160),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Al-Muhandis Pay',
                style: GoogleFonts.cairo(fontSize: 34, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37), letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'ENTERPRISE BANKING CORE',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. بوابة الدخول المشفرة (Secure Login Screen)
// ==========================================
class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({super.key});

  @override
  State<SecureLoginScreen> createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends State<SecureLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _processLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('⚠️ جميع الحقول الأمنية مطلوبة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post(
        'https://al-muhandis.com/api/login',
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        final adminName = response.data['data']['user']['name'];
        await _secureStorage.write(key: 'jwt_token', value: token);
        await _secureStorage.write(key: 'admin_name', value: adminName);

        if (mounted) {
          // النقل السيادي إلى لوحة التحكم الرئيسية
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MasterDashboard()),
          );
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _showError('❌ عملية دخول غير مصرح بها. تم تسجيل محاولتك.');
      } else {
        _showError('🌐 فشل الاتصال بالخوادم المركزية.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 40),
                Text('تسجيل الدخول السيادي', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('الرجاء إدخال بيانات التشفير للوصول للخزنة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),
                
                // حقل اسم المستخدم المتطور
                _buildSecureField(
                  controller: _usernameController,
                  label: 'المعرف العسكري (ID)',
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: 20),
                
                // حقل كلمة المرور المتطور
                _buildSecureField(
                  controller: _passwordController,
                  label: 'مفتاح التشفير السري',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 40),
                
                // زر الدخول التفاعلي
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      elevation: 10,
                      shadowColor: const Color(0xFFD4AF37).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _processLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('فـك الـتـشـفـيـر', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecureField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey.shade600),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade800)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2)),
      ),
    );
  }
}

// ==========================================
// 4. لوحة التحكم المركزية (Master Dashboard)
// ==========================================
class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard> {
  int _currentIndex = 0;
  String _adminName = "جاري التحميل...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'admin_name');
    if (name != null && mounted) {
      setState(() => _adminName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أهلاً بك يا،', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
            Text(_adminName, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD4AF37)),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF0F172A),
            child: Image.asset('assets/logo.png', height: 24),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: _buildHomeTab(), // حالياً نعرض تبويب الرئيسية فقط لتبسيط العرض
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'الخزنة'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_outlined), label: 'الحوالات'),
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), label: 'النظام'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // البطاقة البنكية الفاخرة
          Container(
            width: double.infinity,
            height: 220,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الرصيد السيادي المتاح', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                    const Icon(Icons.wifi, color: Colors.black87),
                  ],
                ),
                Text('\$ 1,500,000.00', style: GoogleFonts.cairo(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('**** **** **** 2026', style: GoogleFonts.cairo(fontSize: 18, color: Colors.black87, letterSpacing: 2)),
                    Image.asset('assets/logo.png', height: 30, color: Colors.black),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // أزرار العمليات السريعة
          Text('العمليات المركزية', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(Icons.send, 'إرسال حوالة'),
              _buildActionButton(Icons.account_balance_wallet, 'تغذية وكيل'),
              _buildActionButton(Icons.history, 'سجل كامل'),
              _buildActionButton(Icons.block, 'تجميد حساب'),
            ],
          ),
          const SizedBox(height: 30),

          // قائمة الحركات الأخيرة
          Text('أحدث الحركات المشفرة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildTransactionTile('تغذية محفظة الوكيل أحمد', '+ 50,000 USDT', true),
          _buildTransactionTile('سحب من الخزنة الرئيسية', '- 12,500 USDT', false),
          _buildTransactionTile('استلام عمولات شبكة', '+ 3,200 USDT', true),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildTransactionTile(String title, String amount, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit ? Colors.green.shade900.withOpacity(0.3) : Colors.red.shade900.withOpacity(0.3),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('اليوم, 10:30 AM', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}

