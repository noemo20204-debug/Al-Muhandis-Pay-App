import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'elite_theme.dart';

class EliteAlerts {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // 1. تهيئة محرك إشعارات النظام
  static Future<void> _initNotifications() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  // 2. إرسال إشعار للنظام (Status Bar)
  static Future<void> _showSystemNotification(String title, String body, bool isSuccess) async {
    await _initNotifications();
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'almuhandis_sec_channel',
      'تنبيهات الأمان السيادية',
      channelDescription: 'إشعارات العمليات المالية والأمنية',
      importance: Importance.max,
      priority: Priority.high,
      color: isSuccess ? EliteColors.success : EliteColors.danger,
      icon: '@mipmap/ic_launcher',
    );
    NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(DateTime.now().millisecond ~/ 1000, title, body, details);
  }

  // 3. الواجهة المرئية داخل التطبيق (In-App Floating Alert)
  static void show(BuildContext context, {required String title, required String message, bool isSuccess = true}) {
    // تشغيل إشعار النظام فوراً
    _showSystemNotification(title, message, isSuccess);

    // إظهار الرسالة الزجاجية الفخمة داخل التطبيق
    final color = isSuccess ? EliteColors.success : EliteColors.danger;
    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}