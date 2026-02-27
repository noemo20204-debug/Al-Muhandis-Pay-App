import 'package:flutter/material.dart';
import 'screens/splash_gate.dart';

void main() {
  runApp(const AlMuhandisPay());
}

class AlMuhandisPay extends StatelessWidget {
  const AlMuhandisPay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Muhandis Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 🖋️ تفعيل خط Cairo السيادي أوفلاين
        fontFamily: 'Cairo',
        primaryColor: const Color(0xFF00101D),
        scaffoldBackgroundColor: const Color(0xFF00101D),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFd4af37),
          primary: const Color(0xFFd4af37),
        ),
        // تخصيص النصوص لتستخدم الخط الجديد تلقائياً
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
      ),
      home: const SplashGate(),
    );
  }
}
