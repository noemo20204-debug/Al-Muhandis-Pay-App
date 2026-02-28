import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/elite_theme.dart';
import 'screens/splash_screen.dart'; // 🟢 الشاشة الجديدة

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت اتجاه الشاشة عمودياً
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // تلوين شريط المهام العلوي ليتناسب مع الثيم
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AlMuhandisApp());
}

class AlMuhandisApp extends StatelessWidget {
  const AlMuhandisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al-Muhandis Pay',
      debugShowCheckedModeBanner: false,
      theme: EliteTheme.getTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // 🟢 فرض اللغة العربية من اليمين لليسار
          child: child!,
        );
      },
      home: const SplashScreen(), // 🟢 الإقلاع من الشاشة الفخمة الجديدة
    );
  }
}