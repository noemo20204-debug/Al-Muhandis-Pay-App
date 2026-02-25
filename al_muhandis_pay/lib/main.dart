import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/elite_theme.dart';
import 'services/api_engine.dart';
import 'screens/glass_login_screen.dart';
import 'screens/elite_dashboard.dart';

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
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  @override
  void initState() { super.initState(); _checkAuth(); }
  Future<void> _checkAuth() async {
    final token = await ApiEngine().storage.read(key: 'jwt_token');
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (token != null) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EliteDashboard()));
    else Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GlassLoginScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(color: EliteColors.goldPrimary)));
  }
}
