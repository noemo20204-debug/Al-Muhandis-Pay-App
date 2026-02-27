import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/elite_theme.dart';
import 'screens/splash_gate.dart';
import 'services/api_engine.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiEngine().setNavigatorKey(globalNavigatorKey);
  runApp(const AlMuhandisEliteApp());
}

class AlMuhandisEliteApp extends StatefulWidget {
  const AlMuhandisEliteApp({super.key});
  @override
  State<AlMuhandisEliteApp> createState() => _AlMuhandisEliteAppState();
}

class _AlMuhandisEliteAppState extends State<AlMuhandisEliteApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 🚀 الضربة الاستباقية: فحص الإصدار فور تشغيل التطبيق (بدون أي تدخل من العميل)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiEngine().pingForVersionCheck();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ApiEngine().pingForVersionCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
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
