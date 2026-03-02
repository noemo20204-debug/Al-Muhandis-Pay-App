import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
// 🟢 تأكد من استدعاء مكتبة الإشعارات (إذا كنت تستخدمها)
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 

import 'core/elite_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/force_update_screen.dart'; // 🟢 استدعاء شاشة التحديث
import 'services/api_engine.dart';

// مفتاح التحكم المركزي
final GlobalKey<NavigatorState> globalAppNavigatorKey = GlobalKey<NavigatorState>();

// 🟢 إذا كنت تستخدم flutter_local_notifications، عرّف المحرك هنا
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 تهيئة الإشعارات (أزل التعليق إذا كنت تستخدم الحزمة)

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // طلب صلاحية الإشعارات لأندرويد 13+
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  ApiEngine().setNavigatorKey(globalAppNavigatorKey);

  runApp(const AlMuhandisApp());
}

class AlMuhandisApp extends StatefulWidget {
  const AlMuhandisApp({super.key});

  @override
  State<AlMuhandisApp> createState() => _AlMuhandisAppState();
}

class _AlMuhandisAppState extends State<AlMuhandisApp> {
  Timer? _versionRadarTimer;
  bool _isBlockScreenShowing = false; // 🟢 رادار: هل شاشة الحظر معروضة الآن؟

  @override
  void initState() {
    super.initState();
    _startRemoteControlRadar();
  }

  void _startRemoteControlRadar() {
    // يفحص السيرفر كل 5 ثوانٍ ليكون الريموت كنترول سريعاً جداً!
    _versionRadarTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        // نضرب السيرفر في نقطة خفيفة لمعرفة حالة النظام
        await ApiEngine().dio.get('/app-config'); 
        
        // 🟢 إذا وصلنا هنا يعني السيرفر رد بـ 200 (الأمور ممتازة!)
        if (_isBlockScreenShowing) {
          // إذا كانت شاشة الحظر مفتوحة، اسحبها فوراً! (إلغاء وضع الصيانة)
          if (globalAppNavigatorKey.currentState != null) {
            globalAppNavigatorKey.currentState!.pop();
            _isBlockScreenShowing = false;
          }
        }
      } on DioException catch (e) {
        // 🚨 السيرفر رد بخطأ! هل هو تحديث/صيانة (426)؟
        if (e.response?.statusCode == 426) {
          if (!_isBlockScreenShowing && globalAppNavigatorKey.currentContext != null) {
            _isBlockScreenShowing = true;
            
            final data = e.response?.data;
            final updateUrl = (data is Map) ? (data['update_url'] ?? '') : '';
            final isMaintenance = (data is Map) ? (data['maintenance'] == true) : false;

            // عرض الشاشة "فوق" التطبيق بدون تدمير الشاشات السابقة
            showDialog(
              context: globalAppNavigatorKey.currentContext!,
              barrierDismissible: false, // يمنع إغلاقها بالنقر خارجها
              useSafeArea: false, // 🚀
              builder: (context) => PopScope(
                canPop: false, // 🟢 يمنع إغلاقها بزر الرجوع في الأندرويد
                child: ForceUpdateScreen(
                  updateUrl: updateUrl,
                  isMaintenance: isMaintenance,
                ),
              ),
            ).then((_) {
              // عندما تُغلق برمجياً (عند عودة السيرفر لـ 200)
              _isBlockScreenShowing = false; 
            });
          }
        }
      } catch (_) {
        // أخطاء أخرى مثل انقطاع الإنترنت، نتجاهلها هنا
      }
    });
  }

  @override
  void dispose() {
    _versionRadarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalAppNavigatorKey,
      title: 'Al-Muhandis Pay',
      debugShowCheckedModeBanner: false,
      theme: EliteTheme.getTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, 
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}