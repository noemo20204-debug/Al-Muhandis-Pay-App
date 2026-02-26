import 'statement_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/elite_theme.dart';
import '../services/api_engine.dart';
import '../widgets/elite_button.dart';
import 'login_screen.dart';
import 'transfer_screen.dart';
import 'deposit_screen.dart'; // 👈 إضافة شاشة الإيداع السيادية

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  String _name = '';
  String _balance = '0.00';
  List<dynamic> _txs = [];
  bool _isLoading = true;
  bool _hideBalance = false;
  Timer? _inactivityTimer;

  late AnimationController _cardAnimCtrl;
  late Animation<Offset> _cardSlide;
  late AnimationController _listAnimCtrl;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _resetInactivityTimer();
    _fetchData();
  }

  void _setupAnimations() {
    _cardAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cardSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutCubic));
    _listAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 20), _autoLogout);
  }

  void _autoLogout() async {
    await ApiEngine().clearAuth();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنهاء الجلسة أمنياً لعدم النشاط', style: GoogleFonts.cairo()), backgroundColor: EliteColors.danger));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _fetchData() async {
    final name = await ApiEngine().storage.read(key: 'admin_name');
    if (mounted && name != null) setState(() => _name = name);
    try {
      final res = await ApiEngine().dio.get('/wallet');
      if (res.statusCode == 200) {
        setState(() {
          _balance = res.data['data']['wallet']['balance'].toString();
          _txs = res.data['data']['recent_transactions'] ?? [];
          _isLoading = false;
        });
        _cardAnimCtrl.forward();
        _listAnimCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _cardAnimCtrl.dispose();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        body: CustomPaint(
          painter: EliteBackgroundPainter(),
          child: SafeArea(
            child: RefreshIndicator(
              color: EliteColors.goldPrimary, backgroundColor: EliteColors.nightBg,
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent, elevation: 0, floating: true,
                    title: Text('Al-Muhandis Elite', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: EliteColors.goldPrimary)),
                    actions: [
                      IconButton(icon: Icon(_hideBalance ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _hideBalance = !_hideBalance)),
                      IconButton(icon: const Icon(Icons.power_settings_new, color: EliteColors.danger), onPressed: _autoLogout),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً، $_name', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey.shade400)),
                          const SizedBox(height: 20),
                          _isLoading ? const _BankShimmerCard() : _buildGoldCard(),
                          const SizedBox(height: 40),
                          Text('عمليات الخزنة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildActionBtn(Icons.send_rounded, 'تحويل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()))),
                              
                              // 👇 تم ربط زر الإيداع مع إضافة الاهتزاز البنكي 👇
                              _buildActionBtn(Icons.account_balance_wallet, 'تغذية', () {
                                HapticFeedback.mediumImpact();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen()));
                              }),

                              _buildActionBtn(Icons.history, 'السجل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatementScreen()))),
                              _buildActionBtn(Icons.qr_code_scanner, 'مسح', () {}),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text('سجل الحركات الأخير', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _isLoading ? const Center(child: CircularProgressIndicator(color: EliteColors.goldPrimary)) : _buildTxList(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldCard() {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardAnimCtrl,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: EliteColors.goldGradient, borderRadius: BorderRadius.circular(30),
            boxShadow: EliteShadows.neonGold,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الرصيد السيادي المتاح', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                  const Icon(Icons.security, color: Colors.black87),
                ],
              ),
              const SizedBox(height: 15),
              Text(_hideBalance ? '***.*** USDT' : '$_balance USDT', style: GoogleFonts.cairo(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 30),
              Text('**** **** **** 2026', style: GoogleFonts.cairo(fontSize: 18, color: Colors.black87, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: EliteColors.glassFill, borderRadius: BorderRadius.circular(20), border: Border.all(color: EliteColors.glassBorderLight)),
            child: Icon(icon, color: EliteColors.goldPrimary, size: 28),
          ),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTxList() {
    if (_txs.isEmpty) return Center(child: Text('لا توجد حركات مالية', style: GoogleFonts.cairo(color: Colors.grey)));
    return Column(
      children: List.generate(_txs.length, (index) {
        final tx = _txs[index];
        bool isCredit = tx['entry_type'] == 'credit';
        final Animation<double> anim = CurvedAnimation(parent: _listAnimCtrl, curve: Interval(index / _txs.length, 1.0, curve: Curves.easeOut));
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(anim),
            child: Container(
              margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: EliteColors.glassFill, borderRadius: BorderRadius.circular(20), border: Border.all(color: EliteColors.glassBorderDark)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isCredit ? EliteColors.success.withOpacity(0.1) : EliteColors.danger.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? EliteColors.success : EliteColors.danger),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['tx_category'] ?? 'عملية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text((tx['created_at'] ?? '').split(' ').first, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(_hideBalance ? '***' : '${isCredit ? "+" : "-"} ${tx['amount']}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? EliteColors.success : EliteColors.danger)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BankShimmerCard extends StatefulWidget {
  const _BankShimmerCard();
  @override
  State<_BankShimmerCard> createState() => _BankShimmerCardState();
}
class _BankShimmerCardState extends State<_BankShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_ctrl),
      child: Container(
        width: double.infinity, height: 200,
        decoration: BoxDecoration(color: EliteColors.glassFill, borderRadius: BorderRadius.circular(30), border: Border.all(color: EliteColors.glassBorderDark)),
      ),
    );
  }
}
