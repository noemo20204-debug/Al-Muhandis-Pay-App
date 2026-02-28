import 'dart:ui';
import 'dart:async'; // 🟢 للتحديث التلقائي
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_engine.dart';
import 'transfer_screen.dart';
import 'statement_screen.dart';
import 'deposit_screen.dart';
import 'withdrawal_screen.dart';
import '../core/elite_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // 🟢 للتحكم بالقائمة الجانبية
  Timer? _autoRefreshTimer; // 🟢 محرك التحديث اللحظي

  bool _isLoading = true;
  double _balance = 0.0;
  String _userName = 'جاري الاتصال بالسيرفر...';
  String _walletId = 'جاري التحميل...';
  String? _avatarUrl;
  List<dynamic> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _initDashboard();
    // 🟢 تشغيل الرادار: تحديث صامت كل 10 ثوانٍ (Real-time simulation)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _initDashboard(isSilent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel(); // إيقاف الرادار عند إغلاق الشاشة
    super.dispose();
  }

  // 🟢 دالة الجلب من السيرفر (مصدر الحقيقة الوحيد)
  Future<void> _initDashboard({bool isSilent = false}) async {
    if (!isSilent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await ApiEngine().dio.get('/wallet');
      if (response.statusCode == 200 && mounted) {
        final resData = response.data['data'] ?? response.data;
        setState(() {
          // 1. جلب الهوية من السيرفر مباشرة
          if (resData['user'] != null) {
            _userName = resData['user']['name'] ?? 'عميل المهندس';
            _avatarUrl = resData['user']['avatar'];
          }

          // 2. جلب الخزنة
          if (resData['wallet'] != null) {
            _balance = double.tryParse(resData['wallet']['balance'].toString()) ?? 0.0;
            if (resData['wallet']['account_number'] != null) {
              _walletId = resData['wallet']['account_number'];
            }
          }

          // 3. جلب النشاط
          if (resData['recent_transactions'] != null) {
            _recentTransactions = resData['recent_transactions'];
          }
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          if (e.response?.statusCode == 404) _balance = 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🟢 دوال الانتقال (مع تحديث فوري عند العودة)
  void _goToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _initDashboard(isSilent: true)); // تحديث فوري بدون شاشة تحميل عند الرجوع
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // 🟢 ربط المفتاح
      // 🟢 تصميم الخلفية الفخم الجديد (Neo-Bank Style)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070B19), // كحلي ملوكي داكن من الأعلى
              Color(0xFF02040A), // أسود عميق من الأسفل
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: EliteColors.goldPrimary,
            backgroundColor: EliteColors.surface,
            onRefresh: () => _initDashboard(isSilent: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 🟢 الهيدر التفاعلي ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _scaffoldKey.currentState?.openDrawer(), // فتح القائمة
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: EliteColors.goldPrimary.withOpacity(0.5), width: 2),
                                      boxShadow: EliteShadows.neonGold,
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: EliteColors.surface,
                                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                                      child: _avatarUrl == null
                                          ? const Icon(Icons.person, color: EliteColors.goldPrimary, size: 30)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('أهلاً بك', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.1)),
                                      Text(
                                        _userName,
                                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: EliteColors.goldPrimary),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),

                        // --- 🟢 البطاقة الزجاجية النخبوية ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    EliteColors.goldPrimary.withOpacity(0.15),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: EliteColors.goldPrimary.withOpacity(0.3), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: EliteColors.goldPrimary.withOpacity(0.05), blurRadius: 30, spreadRadius: 5),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('الرصيد الإجمالي', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
                                      Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.4), size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  _isLoading && _balance == 0.0
                                      ? const SizedBox(height: 40, child: CircularProgressIndicator(color: EliteColors.goldPrimary))
                                      : Text(
                                          'USDT ${_balance.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                  const SizedBox(height: 30),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _walletId,
                                          style: const TextStyle(color: EliteColors.goldPrimary, letterSpacing: 2.5, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        const Icon(Icons.copy, color: Colors.white54, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),

                        // --- الأزرار الأربعة ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton('تحويل', Icons.send, () => _goToScreen(const TransferScreen()), EliteColors.goldPrimary),
                            _buildActionButton('إيداع', Icons.download, () => _goToScreen(const DepositScreen()), EliteColors.success),
                            _buildActionButton('سحب', Icons.upload, () => _goToScreen(const WithdrawalScreen()), EliteColors.danger),
                            _buildActionButton('كشف', Icons.receipt_long, () => _goToScreen(const StatementScreen()), Colors.blueAccent),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // --- النشاط الأخير ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('أحدث الحركات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: () => _goToScreen(const StatementScreen()), child: const Text('عرض الكل', style: TextStyle(color: EliteColors.goldPrimary))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _isLoading && _recentTransactions.isEmpty
                            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: EliteColors.goldPrimary)))
                            : _recentTransactions.isEmpty
                                ? Center(
                                    child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        Icon(Icons.history_toggle_off, size: 50, color: Colors.white.withOpacity(0.2)),
                                        const SizedBox(height: 10),
                                        const Text('لا توجد حركات مالية بعد', style: TextStyle(color: Colors.white54)),
                                      ],
                                    ),
                                  ))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _recentTransactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = _recentTransactions[index];
                                      final isCredit = tx['entry_type'] == 'CREDIT';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 15),
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isCredit ? EliteColors.success.withOpacity(0.1) : EliteColors.danger.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? EliteColors.success : EliteColors.danger, size: 20),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(tx['tx_category'] ?? 'عملية مالية', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(tx['created_at']?.toString() ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${isCredit ? '+' : '-'} ${tx['amount']}',
                                              style: TextStyle(color: isCredit ? EliteColors.success : EliteColors.danger, fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // 🟢 القائمة الجانبية (Drawer)
      drawer: Drawer(
        backgroundColor: EliteColors.nightBg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'), // ضع أي خلفية للدرج أو اتركها متدرجة
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              ),
              accountName: Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text(_walletId, style: const TextStyle(color: EliteColors.goldPrimary)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: EliteColors.surface,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person, color: EliteColors.goldPrimary, size: 40) : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text('الإعدادات (تغيير الصورة)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // إغلاق القائمة
                // 🟢 استبدل هذا المسار بشاشة الإعدادات الخاصة بك
                // _goToScreen(const SettingsScreen()); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم ربطها بشاشة الإعدادات قريباً')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.white70),
              title: const Text('الأمان والحماية', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: EliteColors.danger),
              title: const Text('تسجيل الخروج', style: TextStyle(color: EliteColors.danger)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // توجيه لشاشة الدخول
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: color == EliteColors.danger ? EliteShadows.neonDanger : EliteShadows.neonGold,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}