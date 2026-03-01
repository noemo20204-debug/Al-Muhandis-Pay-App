import 'dart:ui';
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
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // 🟢 هندسة الحركة (Animation) لدخول فخم ومتقدم
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));
    
    _controller.forward();
    _checkAuthAndProceed();
  }

  Future<void> _checkAuthAndProceed() async {
    // إعطاء وقت كافٍ للمستخدم لرؤية الشعار الفخم
    await Future.delayed(const Duration(milliseconds: 3500)); 
    
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ));
    } else {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ));
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
          Positioned.fill(child: CustomPaint(painter: EliteBackgroundPainter())), // الخلفية السينمائية
          
          // 🟢 تأثير الوهج خلف الشعار
          Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: EliteColors.goldPrimary.withOpacity(0.15), blurRadius: 100, spreadRadius: 30),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🟢 استدعاء شعار شركتك الرسمي
                        Image.asset(
                          'assets/logo.png', // تأكد أن الشعار موجود بهذا الاسم
                          width: 150,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.account_balance, size: 100, color: EliteColors.goldPrimary);
                          },
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'AL-MUHANDIS PAY',
                          style: TextStyle(
                            color: EliteColors.goldPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sovereign Financial System',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: EliteColors.goldPrimary,
                            strokeWidth: 2,
                            backgroundColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}