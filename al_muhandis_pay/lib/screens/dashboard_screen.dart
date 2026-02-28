import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_engine.dart';
import 'transfer_screen.dart';
import 'statement_screen.dart';
import 'deposit_screen.dart';
import 'withdrawal_screen.dart';
import 'glass_login_screen.dart';
import 'profile_screen.dart'; // 🟢 الشاشة الجديدة التي سنصنعها
import '../core/elite_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _autoRefreshTimer;
  Timer? _inactivityTimer;

  bool _isLoading = true;
  double _balance = 0.0;
  String _userName = 'جاري التحميل...';
  String _walletId = 'AMP-PENDING';
  String? _avatarUrl;
  List<dynamic> _recentTransactions = [];
  
  // 🟢 التحكم بالشريط السفلي
  int _currentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initDashboard();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _initDashboard(isSilent: true));
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 20), () {
      _forceLogout(reason: 'انتهت الجلسة بسبب الخمول لحمايتك');
    });
  }

  Future<void> _forceLogout({String? reason}) async {
    _autoRefreshTimer?.cancel();
    _inactivityTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try { const storage = FlutterSecureStorage(); await storage.deleteAll(); } catch (e) {}

    if (mounted) {
      if (reason != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason), backgroundColor: EliteColors.danger));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const GlassLoginScreen()), (route) => false);
    }
  }

  Future<void> _initDashboard({bool isSilent = false}) async {
    if (!isSilent && mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiEngine().dio.get('/wallet');
      if (response.statusCode == 200 && mounted) {
        final resData = response.data['data'] ?? response.data;
        setState(() {
          if (resData['user'] != null) {
            _userName = resData['user']['name'] ?? 'عميل المهندس';
            _avatarUrl = resData['user']['avatar'];
          }
          if (resData['wallet'] != null) {
            _balance = double.tryParse(resData['wallet']['balance'].toString()) ?? 0.0;
            if (resData['wallet']['account_number'] != null) _walletId = resData['wallet']['account_number'];
          }
          if (resData['recent_transactions'] != null) _recentTransactions = resData['recent_transactions'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) => _initDashboard(isSilent: true));
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 مصفوفة الشاشات للشريط السفلي
    final List<Widget> pages = [
      _buildMainDashboard(),
      const Center(child: Text("شاشة الأخبار قريباً", style: TextStyle(color: EliteColors.goldPrimary, fontSize: 20))),
      const Center(child: Text("شاشة الخزنة المتقدمة قريباً", style: TextStyle(color: EliteColors.goldPrimary, fontSize: 20))),
      ProfileScreen(userName: _userName, walletId: _walletId, avatarUrl: _avatarUrl), // شاشة الإعدادات الجديدة
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (_) => _resetInactivityTimer(),
      onTap: _resetInactivityTimer,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: EliteColors.nightBg,
        extendBody: true, // للسماح للشريط العائم بالظهور فوق الخلفية
        // 🟢 ثورة التصميم: رسم خلفية سينمائية وراء كل شيء
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())),
            SafeArea(bottom: false, child: pages[_currentIndex]),
          ],
        ),
        
        // 🟢 الشريط السفلي الزجاجي العائم الفخم
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: EliteColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: EliteColors.goldPrimary.withOpacity(0.3), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: EliteColors.goldPrimary,
                  unselectedItemColor: Colors.white54,
                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), activeIcon: Icon(Icons.bar_chart_rounded, size: 28), label: 'المنصة'),
                    BottomNavigationBarItem(icon: Icon(Icons.newspaper), activeIcon: Icon(Icons.newspaper, size: 28), label: 'الأخبار'),
                    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet, size: 28), label: 'الخزنة'),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person, size: 28), label: 'حسابي'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 محتوى الداشبورد الرئيسي (تم فصله ليعمل مع القائمة السفلية)
  Widget _buildMainDashboard() {
    final String currentDate = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}";
    return RefreshIndicator(
      color: EliteColors.goldPrimary,
      backgroundColor: EliteColors.surface,
      onRefresh: () => _initDashboard(isSilent: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 15.0, bottom: 100.0), // مسافة سفلية للشريط العائم
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('أهلاً بك،', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    Text(_userName.split(' ').take(2).join(' '), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 3), // ينقلك لصفحة "حسابي"
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: EliteColors.goldPrimary, width: 2)),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: EliteColors.surface,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null ? const Icon(Icons.person, color: EliteColors.goldPrimary) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // البطاقة البنكية
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: EliteColors.goldPrimary.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: EliteColors.goldPrimary.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المحفظة السيادية', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(currentDate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text('إجمالي الرصيد:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _isLoading && _balance == 0.0
                                ? const SizedBox(height: 30, child: CircularProgressIndicator(color: EliteColors.goldPrimary))
                                : Text('USDT ${_balance.toStringAsFixed(2)}', style: const TextStyle(color: EliteColors.goldPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: EliteColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: const Row(children: [Icon(Icons.arrow_upward, color: EliteColors.success, size: 14), SizedBox(width: 4), Text('نشط', style: TextStyle(color: EliteColors.success, fontSize: 12, fontWeight: FontWeight.bold))]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_walletId, style: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAppBtn('إيداع', Icons.download, () => _goToScreen(const DepositScreen())),
                        _buildAppBtn('تحويل', Icons.swap_horiz, () => _goToScreen(const TransferScreen())),
                        _buildAppBtn('سحب', Icons.account_balance_wallet, () => _goToScreen(const WithdrawalScreen())),
                        _buildAppBtn('المزيد', Icons.keyboard_arrow_down, () => _goToScreen(const StatementScreen())),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // لافتة الأمان
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [EliteColors.goldPrimary.withOpacity(0.8), EliteColors.goldDark]), borderRadius: BorderRadius.circular(20), boxShadow: EliteShadows.neonGold),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.security, color: Colors.white, size: 20)),
                  const SizedBox(width: 15),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الخزنة المركزية محمية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), Text('اتصالك مشفر بالكامل وآمن بنسبة 100%', style: TextStyle(color: Colors.white70, fontSize: 12))])),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // النشاط الأخير
            _recentTransactions.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد حركات', style: TextStyle(color: Colors.white54))))
                : Column(
                    children: _recentTransactions.map((tx) {
                      final isCredit = tx['entry_type'] == 'CREDIT';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: EliteColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isCredit ? EliteColors.success.withOpacity(0.1) : EliteColors.danger.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? EliteColors.success : EliteColors.danger, size: 18)),
                          title: Text(tx['tx_category'] ?? 'عملية', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(tx['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${isCredit ? '+' : '-'} ${tx['amount']}', style: TextStyle(color: isCredit ? EliteColors.success : EliteColors.danger, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBtn(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: EliteColors.surface, size: 24)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}