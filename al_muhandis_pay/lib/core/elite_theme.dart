import 'package:flutter/material.dart';

class EliteColors {
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFAA771C);
  static const Color nightBg = Color(0xFF030712);
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);
}

class EliteBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF0F172A), Color(0xFF030712)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    final Paint glowPaint = Paint()..color = EliteColors.goldPrimary.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 150, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 200, glowPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
