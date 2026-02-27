import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String updateUrl;
  final bool isMaintenance;

  const ForceUpdateScreen({super.key, required this.updateUrl, this.isMaintenance = false});

  Future<void> _launchUpdate() async {
    final uri = Uri.parse(updateUrl);
    // 🚀 تجاوز حماية أندرويد 11 (canLaunchUrl) وفتح الرابط بالقوة
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF030712),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isMaintenance ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                    ),
                    child: Icon(
                      isMaintenance ? Icons.handyman_rounded : Icons.system_update_rounded,
                      size: 80,
                      color: isMaintenance ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isMaintenance ? 'النظام تحت الصيانة' : 'تحديث إجباري مطلوب',
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMaintenance 
                        ? 'نقوم حالياً بتحديث الخوادم السيادية لـ Al-Muhandis Pay لتقديم خدمة أفضل. سنعود للعمل قريباً.'
                        : 'لضمان أعلى معايير الأمان البنكي، يجب عليك تحديث التطبيق الآن للنسخة الأحدث لتتمكن من المتابعة.',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade400, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (!isMaintenance)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _launchUpdate,
                        icon: const Icon(Icons.download_rounded, color: Colors.black),
                        label: Text('تحديث التطبيق الآن', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => exit(0),
                    child: Text('إغلاق التطبيق', style: GoogleFonts.cairo(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
