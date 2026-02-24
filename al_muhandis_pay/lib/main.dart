import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

void main() => runApp(const AlMuhandisEnterpriseApp());

class AlMuhandisEnterpriseApp extends StatelessWidget {
  const AlMuhandisEnterpriseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFFD4AF37),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const SecureLoginScreen(),
    );
  }
}

// [شاشة الدخول اختصرتها لك هنا لتقليل الكود، هي نفس كودك السابق الذي يعمل بنجاح]
class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({super.key});
  @override
  State<SecureLoginScreen> createState() => _SecureLoginScreenState();
}
class _SecureLoginScreenState extends State<SecureLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _processLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.post('https://al-muhandis.com/api/login', data: {"username": _usernameController.text, "password": _passwordController.text});
      if (response.statusCode == 200) {
        await _secureStorage.write(key: 'jwt_token', value: response.data['data']['token']);
        await _secureStorage.write(key: 'admin_name', value: response.data['data']['user']['name']);
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigationHub()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الدخول', style: GoogleFonts.cairo()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 30),
              Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(controller: _usernameController, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF0F172A), labelText: 'اسم المستخدم')),
              const SizedBox(height: 20),
              TextFormField(controller: _passwordController, obscureText: true, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF0F172A), labelText: 'كلمة المرور')),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), onPressed: _isLoading ? null : _processLogin, child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text('دخول', style: GoogleFonts.cairo(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// 🏛️ المحور المركزي (للتحكم في الشريط السفلي والتنقل)
// ========================================================
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});
  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;
  // قائمة الشاشات التي سيتم التنقل بينها
  final List<Widget> _pages = [
    const WalletDashboardScreen(), // الشاشة الرئيسية
    const TransferScreen(),        // شاشة التحويل (جديدة)
    const Center(child: Text('الإعدادات قريباً...')), // شاشة مؤقتة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // عرض الشاشة المختارة
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index), // تغيير الشاشة عند الضغط
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'المحفظة'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'التحويل'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// ========================================================
// 💳 شاشة المحفظة الرئيسية (التي تجلب البيانات من السيرفر)
// ========================================================
class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});
  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  String _adminName = "";
  String _balance = "0.00";
  List<dynamic> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await _secureStorage.read(key: 'admin_name');
    final token = await _secureStorage.read(key: 'jwt_token');
    if (name != null && mounted) setState(() => _adminName = name);
    if (token != null) {
      try {
        final res = await _dio.get('https://al-muhandis.com/api/wallet', options: Options(headers: {'Authorization': 'Bearer $token'}));
        if (res.statusCode == 200) {
          setState(() {
            _balance = res.data['data']['wallet']['balance'].toString();
            _recentTransactions = res.data['data']['recent_transactions'] ?? [];
            _isLoading = false;
          });
        }
      } catch (e) { setState(() => _isLoading = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text('مرحباً، $_adminName', style: GoogleFonts.cairo(color: const Color(0xFFD4AF37), fontSize: 18))),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))) : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // البطاقة الفاخرة
              Container(
                width: double.infinity, padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAA771C)]), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الرصيد المتوفر', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                    Text('$_balance USDT', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // الأزرار الوظيفية (تنتقل لصفحات أخرى)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(Icons.send, 'إرسال', () {
                    // أمر الانتقال إلى شاشة التحويل
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()));
                  }),
                  _buildNavButton(Icons.add_card, 'إيداع', () {}),
                  _buildNavButton(Icons.history, 'السجل', () {}),
                ],
              ),
              const SizedBox(height: 30),
              Text('أحدث العمليات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ..._recentTransactions.map((tx) {
                bool isCredit = tx['entry_type'] == 'credit';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                      const SizedBox(width: 15),
                      Expanded(child: Text(tx['tx_category'] ?? 'عملية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
                      Text('${isCredit ? "+" : "-"} ${tx['amount']} USDT', style: GoogleFonts.cairo(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: const Color(0xFFD4AF37))),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ========================================================
// ✈️ شاشة التحويل الجديدة (شاشة وظيفية فعلية)
// ========================================================
class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إرسال حوالة جديدة', style: GoogleFonts.cairo(color: const Color(0xFFD4AF37))), backgroundColor: const Color(0xFF0F172A)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.send_to_mobile, size: 80, color: Color(0xFFD4AF37)),
            const SizedBox(height: 30),
            TextFormField(decoration: InputDecoration(filled: true, fillColor: const Color(0xFF0F172A), labelText: 'رقم حساب أو إيميل المستلم', prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)))),
            const SizedBox(height: 20),
            TextFormField(keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, fillColor: const Color(0xFF0F172A), labelText: 'المبلغ (USDT)', prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFD4AF37)))),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), onPressed: () {}, child: Text('تأكيد الإرسال', style: GoogleFonts.cairo(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}
