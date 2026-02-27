import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../core/elite_theme.dart';
import '../services/api_engine.dart';
import 'elite_dashboard.dart';

class GlassLoginScreen extends StatefulWidget {
  const GlassLoginScreen({super.key});
  @override
  State<GlassLoginScreen> createState() => _GlassLoginScreenState();
}
class _GlassLoginScreenState extends State<GlassLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiEngine().dio.post('/login', data: {"username": _userCtrl.text, "password": _passCtrl.text});
      if (res.statusCode == 200) {
        await ApiEngine().storage.write(key: 'jwt_token', value: res.data['data']['token']);
        await ApiEngine().storage.write(key: 'admin_name', value: res.data['data']['user']['name']);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EliteDashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في البيانات')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: EliteBackgroundPainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: EliteColors.glassSurface, border: Border.all(color: EliteColors.glassBorder), borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security, size: 60, color: EliteColors.goldPrimary),
                      const SizedBox(height: 30),
                      TextFormField(controller: _userCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'معرف النظام', filled: true, fillColor: Colors.black26)),
                      const SizedBox(height: 20),
                      TextFormField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'مفتاح التشفير', filled: true, fillColor: Colors.black26)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: EliteColors.goldPrimary, minimumSize: const Size(double.infinity, 50)),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('فـك الـتـشـفـيـر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
