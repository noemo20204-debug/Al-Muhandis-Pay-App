import "package:shared_preferences/shared_preferences.dart";
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'advanced_transfer_screen.dart';

class _S {
  static const Color bg = Color(0xFF00101D);
  static const Color bgCard = Color(0xFF001428);
  static const Color bgSurface = Color(0xFF001A33);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8952C);
  static const Color goldFaint = Color(0x15D4AF37);
  static const Color glassBorder = Color(0xFF0A2A4A);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color textSub = Color(0xFF3A5A7A);
  static const Color green = Color(0xFF00E676);
  static const Color red = Color(0xFFFF5252);
  static const Color blue = Color(0xFF448AFF);
  static const Color purple = Color(0xFFAB47BC);
  static const Color orange = Color(0xFFFF9800);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  bool _balanceVisible = true;
  bool _isLoading = true; // 👈 مؤشر التحميل الحقيقي

  // المتغيرات التي ستستقبل البيانات الحية من السيرفر
  String _userName = 'جاري التحميل...';
  String _accountNumber = 'AMP-XXXX-XXXX';
  double _balance = 0.00;
  String _currency = 'USDT';
  List<Map<String, dynamic>> _recentActivity = [];

  late AnimationController _particleCtrl, _shimmerCtrl, _pulseCtrl, _entranceCtrl;
  late Animation<double> _shimmerAnim, _pulseAnim, _entranceAnim;
  final List<_GoldParticle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _entranceCtrl.forward();
    
    // 🚀 إطلاق صاروخ جلب البيانات فور فتح التطبيق
    _fetchSovereignData();
  }

  // 📡 محرك التزامن السيادي (Sovereign Sync Engine)
  Future<void> _fetchSovereignData() async {
    setState(() => _isLoading = true);
    try {
      // ⚠️ ضع التوكن الخاص بالمستخدم هنا (يتم جلبه من التخزين المحلي عادة)
      final prefs = await SharedPreferences.getInstance();
      String userToken = prefs.getString('token') ?? prefs.getString('auth_token') ?? ''; 

      final response = await http.get(
        // الرابط الذي يربطنا بملف MobileApiController.php
        Uri.parse('https://al-muhandis.com/api/dashboard'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken', // الحارس الأمني
          'X-App-Version': '1.0.0', // تصريح الدخول السيادي
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          // ربط المفاتيح القادمة من JSON بالواجهة
          _userName = data['user_name'] ?? 'المهندس';
          _accountNumber = data['account_number'] ?? 'AMP-0000-0000';
          _balance = double.tryParse(data['balance'].toString()) ?? 0.00;
          
          // تنظيف وتجهيز العمليات الأخيرة
          if (data['recent_transactions'] != null) {
            _recentActivity = List<Map<String, dynamic>>.from(
              data['recent_transactions'].map((tx) => {
                'type': tx['type'],
                'title': tx['title'],
                'subtitle': tx['subtitle'],
                'amount': double.tryParse(tx['amount'].toString()) ?? 0.0,
                'date': tx['date'],
                'icon': tx['type'] == 'CREDIT' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              })
            );
          }
          _isLoading = false;
        });
      } else {
        throw Exception("فشل في المصادقة أو جلب البيانات");
      }
    } catch (e) {
      // في حال فشل الاتصال، نظهر رسالة خطأ ونضع بيانات احتياطية لكي لا ينهار التصميم
      print("Error Syncing Data: $e");
      setState(() {
        _userName = 'غير متصل';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر الاتصال بالخزنة المركزية", style: TextStyle(fontFamily: 'Cairo'))),
      );
    }
  }

  void _initAnimations() {
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOutSine));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine));
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entranceAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(_GoldParticle(x: _rng.nextDouble(), y: _rng.nextDouble(), size: _rng.nextDouble() * 2.0 + 0.5, speed: _rng.nextDouble() * 0.2 + 0.05, opacity: _rng.nextDouble() * 0.25 + 0.05, angle: _rng.nextDouble() * 2 * pi));
    }
  }

  @override
  void dispose() {
    _particleCtrl.dispose(); _shimmerCtrl.dispose(); _pulseCtrl.dispose(); _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _S.bg,
        body: Stack(
          children: [
            AnimatedBuilder(animation: _particleCtrl, builder: (_, __) => CustomPaint(size: MediaQuery.of(context).size, painter: _ParticlePainter(_particles, _particleCtrl.value))),
            RefreshIndicator(
              onRefresh: _fetchSovereignData, // 👈 السحب للأسفل يجلب البيانات الحقيقية من السيرفر
              color: _S.gold, backgroundColor: _S.bgCard,
              child: AnimatedBuilder(
                animation: _entranceAnim,
                builder: (_, child) => Opacity(opacity: _entranceAnim.value, child: child),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 16)),
                    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildSovereignHeader())),
                    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), child: _buildVaultCard())),
                    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 0), child: _buildQuickActions())),
                    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('النشاط الأخير', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.bold, color: _S.textWhite)), GestureDetector(onTap: () {}, child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _S.gold, fontWeight: FontWeight.w600)))]))),
                    
                    // إظهار اللودينج أو العمليات
                    _isLoading 
                      ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: _S.gold)))
                      : _recentActivity.isEmpty 
                        ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("لا توجد حركات مالية", style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)))))
                        : SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => _buildActivityItem(_recentActivity[i], i), childCount: _recentActivity.length))),
                    
                    SliverToBoxAdapter(child: _buildSecurityFooter()),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSovereignHeader() {
    return Row(
      children: [
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_S.gold, _S.goldDark]), boxShadow: [BoxShadow(color: _S.gold.withOpacity(0.15 * _pulseAnim.value), blurRadius: 16, spreadRadius: 1)]), child: Padding(padding: const EdgeInsets.all(2.5), child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: _S.bg), child: const Center(child: Icon(Icons.person_rounded, color: _S.gold, size: 26)))))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('أهلاً بك', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: _S.textMuted)), Text(_userName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold, color: _S.textWhite))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _S.green.withOpacity(0.08), border: Border.all(color: _S.green.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: _S.green, boxShadow: [BoxShadow(color: _S.green.withOpacity(0.5), blurRadius: 6)])), const SizedBox(width: 6), const Text('مشفّر', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _S.green, fontWeight: FontWeight.w600))])),
        const SizedBox(width: 10),
        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) => GestureDetector(onTap: () { HapticFeedback.lightImpact(); }, child: Stack(children: [Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: _S.bgSurface, border: Border.all(color: _S.glassBorder)), child: const Icon(Icons.notifications_outlined, color: _S.textMuted, size: 22)), Positioned(top: 8, right: 10, child: Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: _S.gold, boxShadow: [BoxShadow(color: _S.gold.withOpacity(0.4 * _pulseAnim.value), blurRadius: 8)])))]))),
      ],
    );
  }

  Widget _buildVaultCard() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_S.bgSurface.withOpacity(0.7), _S.bgCard.withOpacity(0.5), _S.bgSurface.withOpacity(0.6)]), border: Border.all(color: _S.gold.withOpacity(0.12), width: 1), boxShadow: [BoxShadow(color: _S.gold.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10)), BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))]),
            child: Stack(
              children: [
                Positioned.fill(child: ShaderMask(shaderCallback: (bounds) => LinearGradient(begin: Alignment(_shimmerAnim.value - 0.5, -0.3), end: Alignment(_shimmerAnim.value + 0.5, 0.3), colors: [Colors.transparent, _S.gold.withOpacity(0.04), _S.gold.withOpacity(0.08), _S.gold.withOpacity(0.04), Colors.transparent], stops: const [0.0, 0.35, 0.5, 0.65, 1.0]).createShader(bounds), blendMode: BlendMode.srcATop, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), color: Colors.white)))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: _S.goldFaint), child: const Icon(Icons.account_balance_rounded, size: 16, color: _S.gold)), const SizedBox(width: 10), const Text('الرصيد الإجمالي', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: _S.textMuted, fontWeight: FontWeight.w500))]), GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() => _balanceVisible = !_balanceVisible); }, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(shape: BoxShape.circle, color: _S.goldFaint), child: Icon(_balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: _S.gold)))]),
                    const SizedBox(height: 18),
                    
                    // 💸 عرض الرصيد الحقيقي أو اللودينج
                    _isLoading 
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator(color: _S.gold, backgroundColor: Colors.transparent))
                    : AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _balanceVisible ? Row(key: const ValueKey('visible'), crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_formatBalance(_balance), style: const TextStyle(fontFamily: 'Cairo', fontSize: 36, fontWeight: FontWeight.w800, color: _S.textWhite, height: 1)), Padding(padding: const EdgeInsets.only(bottom: 4, right: 8), child: Text(_currency, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600, color: _S.gold)))]) : Row(key: const ValueKey('hidden'), children: List.generate(6, (_) => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: _S.gold.withOpacity(0.3))))))),
                    
                    const SizedBox(height: 22),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: _S.bg.withOpacity(0.4), border: Border.all(color: _S.glassBorder.withOpacity(0.5))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.credit_card_rounded, size: 14, color: _S.textSub), const SizedBox(width: 8), Text(_accountNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: _S.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w500)), const SizedBox(width: 8), GestureDetector(onTap: () { Clipboard.setData(ClipboardData(text: _accountNumber)); HapticFeedback.lightImpact(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم نسخ رقم الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)), backgroundColor: _S.bgCard, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 1))); }, child: const Icon(Icons.copy_rounded, size: 14, color: _S.gold))])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBalance(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  Widget _buildQuickActions() {
    final actions = [{'icon': Icons.send_rounded, 'label': 'تحويل', 'color': _S.blue, 'route': 'transfer'}, {'icon': Icons.arrow_downward_rounded, 'label': 'إيداع', 'color': _S.green, 'route': 'deposit'}, {'icon': Icons.arrow_upward_rounded, 'label': 'سحب', 'color': _S.orange, 'route': 'withdrawal'}, {'icon': Icons.receipt_long_rounded, 'label': 'كشف حساب', 'color': _S.purple, 'route': 'statement'}];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: actions.map((a) => _buildActionOrb(icon: a['icon'] as IconData, label: a['label'] as String, color: a['color'] as Color, route: a['route'] as String)).toList());
  }

  Widget _buildActionOrb({required IconData icon, required String label, required Color color, required String route}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (route == 'transfer') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedTransferScreen())).then((_) {
            // 🔄 تحديث الرصيد تلقائياً عند العودة من شاشة التحويل!
            _fetchSovereignData();
          });
        }
      },
      child: Column(children: [ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(width: 66, height: 66, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.06), border: Border.all(color: color.withOpacity(0.15), width: 1.5), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16)]), child: Center(child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.2), color.withOpacity(0.05)])), child: Icon(icon, color: color, size: 22)))))), const SizedBox(height: 10), Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: _S.textMuted))]),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item, int index) {
    final isCredit = item['type'] == 'CREDIT';
    final amount = item['amount'] as double;
    final color = isCredit ? _S.green : _S.red;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: _S.bgCard.withOpacity(0.5), border: Border.all(color: _S.glassBorder.withOpacity(0.4))), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.08), border: Border.all(color: color.withOpacity(0.15))), child: Icon(item['icon'] as IconData, color: color, size: 20)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title'] as String, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: _S.textWhite)), const SizedBox(height: 2), Text(item['subtitle'] as String, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _S.textSub))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${isCredit ? "+" : "-"} ${amount.toStringAsFixed(2)}', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 2), Text(item['date'] as String, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _S.textSub))])]));
  }

  Widget _buildSecurityFooter() {
    return Padding(padding: const EdgeInsets.fromLTRB(24, 30, 24, 0), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _S.bgCard.withOpacity(0.3), border: Border.all(color: _S.glassBorder.withOpacity(0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildSecurityBadge(Icons.lock_outline, 'AES-256'), _buildSecurityDot(), _buildSecurityBadge(Icons.fingerprint, '3FA'), _buildSecurityDot(), _buildSecurityBadge(Icons.verified_user_outlined, 'SSL'), _buildSecurityDot(), _buildSecurityBadge(Icons.shield_outlined, 'HMAC')])));
  }

  Widget _buildSecurityBadge(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: _S.textSub), const SizedBox(width: 4), Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _S.textSub, fontWeight: FontWeight.w500))]);
  }

  Widget _buildSecurityDot() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Container(width: 3, height: 3, decoration: BoxDecoration(shape: BoxShape.circle, color: _S.textSub.withOpacity(0.5))));
  }
}

class _GoldParticle {
  final double x, y, size, speed, opacity, angle;
  _GoldParticle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.angle});
}

class _ParticlePainter extends CustomPainter {
  final List<_GoldParticle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width + sin(t * 2 * pi * p.speed + p.angle) * 20;
      final dy = p.y * size.height + cos(t * 2 * pi * p.speed * 0.6 + p.angle) * 15;
      final op = p.opacity * (0.5 + 0.5 * sin(t * 2 * pi + p.angle));
      canvas.drawCircle(Offset(dx % size.width, dy % size.height), p.size, Paint()..color = _S.gold.withOpacity(op)..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8));
    }
  }
  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
