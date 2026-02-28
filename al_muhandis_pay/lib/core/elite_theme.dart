import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 🎨 1. نظام الألوان والتدرجات السيادية
// ==========================================
class EliteColors {
  // درجات الذهب الملكي (Metallic Gold)
  static const Color goldLight = Color(0xFFFFDF73);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF996515);

  // درجات الليل والعمق (Deep Space)
  static const Color nightBg = Color(0xFF02040A); // أسود كحلي عميق جداً
  static const Color surface = Color(0xFF0F172A); // كحلي الواجهات

  // ألوان الحالات (Status)
  static const Color danger = Color(0xFFE11D48); // أحمر ليزري
  static const Color success = Color(0xFF10B981); // أخضر نيون

  // خامات الزجاج (Glass Materials)
  static const Color glassFill = Color(0x0DFFFFFF); // شفافية 5%
  static const Color glassGlow = Color(0x1AFFFFFF); // شفافية 10%
  static const Color glassBorderLight = Color(0x4DFFFFFF); // حافة مضيئة
  static const Color glassBorderDark = Color(0x1AFFFFFF); // حافة داكنة
  
  // 🟢 الإصلاح الجراحي: إضافة الألوان التي يطلبها ملف glass_login_screen
  static const Color glassSurface = Color(0x0AFFFFFF); 
  static const Color glassBorder = Color(0x33FFFFFF);

  // تدرجات جاهزة (Premium Gradients)
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, goldPrimary, goldDark],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassGlow, glassFill],
  );
}

// ==========================================
// 💡 2. هندسة الظلال والوهج (Neon & Shadows)
// ==========================================
class EliteShadows {
  static List<BoxShadow> get neonGold => [
    BoxShadow(color: EliteColors.goldPrimary.withOpacity(0.3), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 8)),
    BoxShadow(color: EliteColors.goldLight.withOpacity(0.1), blurRadius: 40, spreadRadius: 5, offset: const Offset(0, 0)),
  ];

  static List<BoxShadow> get neonDanger => [
    BoxShadow(color: EliteColors.danger.withOpacity(0.4), blurRadius: 25, spreadRadius: -5, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get deepSoft => [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15)),
  ];
}

// ==========================================
// 🔮 3. محرك رسم الخلفية السينمائية
// ==========================================
class EliteBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()..color = EliteColors.nightBg;
    canvas.drawRect(rect, bgPaint);

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    double step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final Paint orb1 = Paint()..color = EliteColors.goldPrimary.withOpacity(0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    final Paint orb2 = Paint()..color = const Color(0xFF1E3A8A).withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150);
    final Paint orb3 = Paint()..color = EliteColors.goldLight.withOpacity(0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 180, orb1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 220, orb2);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 150, orb3);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 📱 4. تطبيق الهوية على مستوى النظام
// ==========================================
class EliteTheme {
  static ThemeData get getTheme {
    return ThemeData(
      scaffoldBackgroundColor: EliteColors.nightBg,
      primaryColor: EliteColors.goldPrimary,
      colorScheme: const ColorScheme.dark(
        primary: EliteColors.goldPrimary,
        secondary: EliteColors.surface,
        error: EliteColors.danger,
      ),
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: Colors.white, 
        displayColor: Colors.white,
      ).copyWith(
        displayLarge: GoogleFonts.cairo(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        labelLarge: GoogleFonts.cairo(fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    );
  }
}