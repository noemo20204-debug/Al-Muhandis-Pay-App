import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

void main() {
  runApp(const AlMuhandisEnterpriseApp());
}

class AlMuhandisEnterpriseApp extends StatelessWidget {
  const AlMuhandisEnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Al-Muhandis Pay',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFFD4AF37),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white, displayColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

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
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _animationController.forward();

    Timer(const Duration(seconds: 3), () {
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
          gradient: RadialGradient(colors: [Color(0xFF1E293B), Color(0xFF030712)], radius: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(opacity: _fadeAnimation, child: Image.asset('assets/logo.png', height: 160)),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text('Al-Muhandis Pay', style: GoogleFonts.cairo(fontSize: 34, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

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
      _showError('الرجاء إدخال بيانات الدخول');
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
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FunctionalDashboard()));
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _showError('بيانات الاعتماد غير صحيحة.');
      } else {
        _showError('فشل الاتصال بالخوادم.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)), backgroundColor: Colors.red.shade900),
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
                Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    filled: true, fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    filled: true, fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _processLogin,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. لوحة التحكم الوظيفية المتصلة بالـ API
// ==========================================
class FunctionalDashboard extends StatefulWidget {
  const FunctionalDashboard({super.key});
  @override
  State<FunctionalDashboard> createState() => _FunctionalDashboardState();
}

class _FunctionalDashboardState extends State<FunctionalDashboard> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  String _adminName = "";
  String _balance = "0.00";
  String _currency = "USDT";
  List<dynamic> _recentTransactions = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ⚡ المحرك الحقيقي لجلب البيانات من سيرفرك
  Future<void> _loadDashboardData() async {
    final name = await _secureStorage.read(key: 'admin_name');
    final token = await _secureStorage.read(key: 'jwt_token');
    
    if (name != null && mounted) setState(() => _adminName = name);

    if (token != null) {
      try {
        final response = await _dio.get(
          'https://al-muhandis.com/api/wallet',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        if (response.statusCode == 200) {
          final data = response.data['data'];
          setState(() {
            _balance = data['wallet']['balance'].toString();
            _currency = data['wallet']['currency'].toString();
            _recentTransactions = data['recent_transactions'] ?? [];
            _isLoadingData = false;
          });
        }
      } on DioException catch (e) {
        // معالجة حالة إذا كان المستخدم ليس لديه محفظة بعد (404)
        if (e.response?.statusCode == 404) {
          setState(() {
            _balance = "0.00";
            _isLoadingData = false;
          });
        } else {
          setState(() => _isLoadingData = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحباً بك،', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
            Text(_adminName, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
          ],
        ),
        actions: [
          CircleAvatar(backgroundColor: const Color(0xFF0F172A), child: Image.asset('assets/logo.png', height: 24)),
          const SizedBox(width: 20),
        ],
      ),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _buildHomeTab(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'المحفظة'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'التحويل'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF0F172A),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // البطاقة البنكية الوظيفية
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAA771C)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إجمالي الرصيد المتوفر', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('$_balance $_currency', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Al-Muhandis Pay Account', style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87)),
                      Image.asset('assets/logo.png', height: 24, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            Text('الخدمات المالية', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.send_rounded, 'إرسال أموال'),
                _buildActionButton(Icons.account_balance_wallet_rounded, 'شحن المحفظة'),
                _buildActionButton(Icons.receipt_long_rounded, 'كشف حساب'),
                _buildActionButton(Icons.more_horiz_rounded, 'المزيد'),
              ],
            ),
            const SizedBox(height: 30),

            Text('سجل العمليات الأخير', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // قراءة الحركات الحقيقية من السيرفر
            if (_recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('لا توجد حركات مالية حتى الآن.', style: GoogleFonts.cairo(color: Colors.grey)),
                ),
              )
            else
              ..._recentTransactions.map((tx) {
                // تحديد نوع الحركة ولونها
                bool isCredit = tx['entry_type'] == 'credit';
                return _buildTransactionTile(
                  title: tx['tx_category'] ?? 'عملية مالية',
                  amount: '${isCredit ? "+" : "-"} ${tx['amount']}',
                  date: tx['created_at'] ?? '',
                  isCredit: isCredit,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
        ),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionTile({required String title, required String amount, required String date, required bool isCredit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit ? Colors.green.shade900.withOpacity(0.3) : Colors.red.shade900.withOpacity(0.3),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                // اقتطاع الوقت من التاريخ القادم من السيرفر
                Text(date.split(' ').first, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('$amount $_currency', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}
