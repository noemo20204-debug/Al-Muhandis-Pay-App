import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/elite_theme.dart';
import '../services/api_engine.dart';
import 'glass_login_screen.dart';

class EliteDashboard extends StatefulWidget {
  const EliteDashboard({super.key});
  @override
  State<EliteDashboard> createState() => _EliteDashboardState();
}
class _EliteDashboardState extends State<EliteDashboard> {
  String _name = '';
  String _balance = '0.00';
  List<dynamic> _txs = [];

  @override
  void initState() { super.initState(); _fetchData(); }

  Future<void> _fetchData() async {
    final name = await ApiEngine().storage.read(key: 'admin_name');
    if (mounted && name != null) setState(() => _name = name);
    try {
      final res = await ApiEngine().dio.get('/wallet');
      if (res.statusCode == 200) {
        setState(() {
          _balance = res.data['data']['wallet']['balance'].toString();
          _txs = res.data['data']['recent_transactions'] ?? [];
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: EliteBackgroundPainter(),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent, elevation: 0,
                title: Text('Al-Muhandis Elite', style: GoogleFonts.cairo(color: EliteColors.goldPrimary)),
                actions: [IconButton(icon: const Icon(Icons.exit_to_app, color: EliteColors.danger), onPressed: () async { await ApiEngine().storage.deleteAll(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GlassLoginScreen())); })],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('مرحباً، $_name', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey.shade400)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [EliteColors.goldPrimary, EliteColors.goldDark]), borderRadius: BorderRadius.circular(30)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الرصيد السيادي المتاح', style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
                          Text('$_balance USDT', style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
