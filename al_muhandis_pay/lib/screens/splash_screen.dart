import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../core/elite_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3)); // عرض الشعار لـ 3 ثوانٍ
    
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EliteColors.nightBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // يمكنك وضع مسار الشعار الخاص بك هنا بدلاً من الأيقونة
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: EliteShadows.neonGold,
                    ),
                    child: const Icon(Icons.security, size: 80, color: EliteColors.goldPrimary),
                  ),
                  const SizedBox(height: 30),
                  const Text('Al-Muhandis Pay', style: TextStyle(color: EliteColors.goldPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  const Text('بوابة الدخول الآمن للنظام المالي', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(color: EliteColors.goldPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}