import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ForceUpdateScreen extends StatefulWidget {
  final String updateUrl;
  final bool isMaintenance;

  const ForceUpdateScreen({
    super.key,
    required this.updateUrl,
    this.isMaintenance = false,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _downloadStatus = '';

  // 🚀 الخطة (ب): فتح الرابط خارجياً إذا فشل التحميل الداخلي
  Future<void> _launchUpdateExternal() async {
    final uri = Uri.parse(widget.updateUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  // 🚀 الخطة (أ): التحميل الداخلي الفخم (In-App OTA)
  Future<void> _startInternalDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _downloadStatus = 'جاري تهيئة التحميل...';
    });

    try {
      // 1. تحديد مكان الحفظ الآمن داخل الهاتف
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      final String savePath = '${dir.path}/almuhandis_update.apk';

      // 2. بدء التحميل عبر Dio
      final dio = Dio();
      await dio.download(
        widget.updateUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              // حساب النسبة المئوية
              String percent = (_progress * 100).toStringAsFixed(0);
              // حساب الحجم بالميجا بايت
              String mbReceived = (received / 1024 / 1024).toStringAsFixed(1);
              String mbTotal = (total / 1024 / 1024).toStringAsFixed(1);
              
              _downloadStatus = 'جاري التحميل... $percent% ($mbReceived MB / $mbTotal MB)';
            });
          }
        },
      );

      setState(() {
        _downloadStatus = 'اكتمل التحميل. جاري بدء التثبيت...';
      });

      // 3. 🚨 تسليم الملف لمثبت حزم الأندرويد (تحديث التطبيق)
      // ملاحظة: استبدل 'com.example.al_muhandis_pay' باسم الحزمة (Package Name) الفعلي لتطبيقك
      // 3. 🚨 فتح الملف لتبدأ عملية التثبيت السيادية
   final result = await OpenFilex.open(savePath);

   // إذا حدث أي خطأ في فتح الملف (مثلاً النظام رفضه)، نعود للخطة البديلة (المتصفح)
   if (result.type != ResultType.done) {
     setState(() => _isDownloading = false);
     _launchUpdateExternal();
   }

    } catch (e) {
      // إذا فشل التحميل لأي سبب، نلغي حالة التحميل ونفتح المتصفح
      setState(() {
        _isDownloading = false;
      });
      _launchUpdateExternal();
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
            bottom: false, // 🚀 إغلاق الشق السفلي
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isMaintenance 
                          ? const Color(0xFFF59E0B).withOpacity(0.1) 
                          : const Color(0xFFEF4444).withOpacity(0.1),
                    ),
                    child: Icon(
                      widget.isMaintenance ? Icons.handyman_rounded : Icons.system_update_rounded,
                      size: 80,
                      color: widget.isMaintenance ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.isMaintenance ? 'النظام تحت الصيانة' : 'تحديث إجباري مطلوب',
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isMaintenance 
                        ? 'نقوم حالياً بتحديث الخوادم السيادية لـ Al-Muhandis Pay لتقديم خدمة أفضل. سنعود للعمل قريباً.'
                        : 'لضمان أعلى معايير الأمان البنكي، يجب عليك تحديث التطبيق الآن للنسخة الأحدث لتتمكن من المتابعة.',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade400, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // 🟢 عرض زر التحديث أو شريط التحميل بناءً على الحالة
                  if (!widget.isMaintenance)
                    _isDownloading 
                      ? _buildProgressIndicator() // شريط التحميل الفخم
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _startInternalDownload, // 🚀 تشغيل المحرك الداخلي
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

  // 🟢 ويدجت شريط التحميل (Progress Bar)
  Widget _buildProgressIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _downloadStatus,
            style: GoogleFonts.cairo(
              color: const Color(0xFFD4AF37), 
              fontWeight: FontWeight.bold, 
              fontSize: 14
            ),
            textDirection: TextDirection.ltr, // لضمان ظهور الأرقام (MB) بشكل صحيح
          ),
        ],
      ),
    );
  }
}