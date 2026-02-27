import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/elite_theme.dart';
import 'screens/splash_gate.dart';
import 'services/api_engine.dart';

// 🗝️ مفتاح الملاحة السيادي: يسمح لنا بالتحكم بالشاشات من أي مكان في التطبيق
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ربط المفتاح بمحرك الاتصال قبل بدء تشغيل التطبيق
  ApiEngine().setNavigatorKey(globalNavigatorKey);
  runApp(const AlMuhandisEliteApp());
}

class AlMuhandisEliteApp extends StatefulWidget {
  const AlMuhandisEliteApp({super.key});

  @override
  State<AlMuhandisEliteApp> createState() => _AlMuhandisEliteAppState();
}

// إضافة مراقب حالة الهاتف (WidgetsBindingObserver)
class _AlMuhandisEliteAppState extends State<AlMuhandisEliteApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 📡 رادار العودة: يعمل فوراً عندما يفتح العميل التطبيق من الخلفية
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ApiEngine().pingForVersionCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey, // زرع المفتاح هنا
      debugShowCheckedModeBanner: false,
      title: 'Al-Muhandis Pay Elite',
      theme: ThemeData(
        scaffoldBackgroundColor: EliteColors.nightBg,
        primaryColor: EliteColors.goldPrimary,
        textTheme: GoogleFonts.cairoTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const SplashGate(),
    );
  }
}
