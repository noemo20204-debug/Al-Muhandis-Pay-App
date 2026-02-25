import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/elite_theme.dart';
import 'screens/splash_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlMuhandisEliteApp());
}

class AlMuhandisEliteApp extends StatelessWidget {
  const AlMuhandisEliteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
