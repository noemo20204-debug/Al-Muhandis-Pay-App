import '../core/app_version_guard.dart';
import 'package:flutter/material.dart';
import '../services/api_engine.dart';
import '../core/elite_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}
class _SplashGateState extends State<SplashGate> {
  @override
  void initState() { super.initState(); _checkAuth(); }
  
  Future<void> _checkAuth() async {
    final token = await ApiEngine().storage.read(key: 'jwt_token');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (token != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: EliteBackgroundPainter(),
        child: const Center(child: CircularProgressIndicator(color: EliteColors.goldPrimary)),
      ),
    );
  }
}
