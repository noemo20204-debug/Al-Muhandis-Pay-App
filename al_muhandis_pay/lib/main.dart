import 'package:flutter/material.dart';
import 'screens/splash_gate.dart';
import 'services/api_engine.dart';

void main() {
  // 🔑 إنشاء المفتاح المركزي للتحكم في مسارات التطبيق
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // 🔌 ربط المفتاح بمحرك الـ ApiEngine السيادي
  ApiEngine().setNavigatorKey(navigatorKey);
  
  runApp(AlMuhandisPay(navKey: navigatorKey));
}

class AlMuhandisPay extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;
  const AlMuhandisPay({super.key, required this.navKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Muhandis Pay',
      debugShowCheckedModeBanner: false,
      // 🛡️ تفعيل الربط لكي تعمل شاشة التحديث الإجباري من أي مكان
      navigatorKey: navKey,
      theme: ThemeData(
        fontFamily: 'Cairo',
        primaryColor: const Color(0xFF00101D),
        scaffoldBackgroundColor: const Color(0xFF00101D),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFd4af37),
          primary: const Color(0xFFd4af37),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
      ),
      home: const SplashGate(),
    );
  }
}
