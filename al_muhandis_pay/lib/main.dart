import 'dart:async'; // 🟢 ضروري للرادار (Timer)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/elite_theme.dart';
import 'screens/splash_screen.dart'; // الشاشة الجديدة
import 'services/api_engine.dart'; // 🟢 استدعاء محرك الـ API

// 🟢 1. إنشاء مفتاح التحكم المركزي (Global Navigator Key)
final GlobalKey<NavigatorState> globalAppNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // إضافة async هنا لتتمكن من تشغيل أي خدمات قبل الإقلاع
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت اتجاه الشاشة عمودياً
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // تلوين شريط المهام العلوي ليتناسب مع الثيم
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // 🟢 2. تسليم مفتاح التحكم لمحرك الـ API لكي يستطيع فتح شاشة التحديث الإجباري
  ApiEngine().setNavigatorKey(globalAppNavigatorKey);

  // 🔔 ملاحظة بخصوص الإشعارات:
  // إذا كان لديك كود لتهيئة الإشعارات (مثل flutter_local_notifications) 
  // يجب أن تضعه هنا قبل runApp لكي يعمل. مثلاً:
  // await NotificationService.initialize();

  runApp(const AlMuhandisApp());
}

// 🟢 3. تحويل التطبيق إلى StatefulWidget لدعم الرادار الخلفي
class AlMuhandisApp extends StatefulWidget {
  const AlMuhandisApp({super.key});

  @override
  State<AlMuhandisApp> createState() => _AlMuhandisAppState();
}

class _AlMuhandisAppState extends State<AlMuhandisApp> {
  Timer? _versionRadarTimer;

  @override
  void initState() {
    super.initState();
    
    // 🟢 4. تشغيل الرادار النابض: يفحص الإصدار كل 10 ثوانٍ بصمت تام في الخلفية
    _versionRadarTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // هذه الدالة تتصل بالسيرفر خفية، وإذا كان السيرفر في وضع صيانة أو تحديث،
      // الـ Interceptor الخاص بـ ApiEngine سيتدخل فوراً!
      ApiEngine().pingForVersionCheck();
    });
  }

  @override
  void dispose() {
    _versionRadarTimer?.cancel(); // إيقاف الرادار عند إغلاق التطبيق
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalAppNavigatorKey, // 🟢 5. ربط المفتاح بالتطبيق (أهم خطوة)
      title: 'Al-Muhandis Pay',
      debugShowCheckedModeBanner: false,
      theme: EliteTheme.getTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // فرض اللغة العربية من اليمين لليسار
          child: child!,
        );
      },
      home: const SplashScreen(), // الإقلاع من الشاشة الفخمة الجديدة
    );
  }
}