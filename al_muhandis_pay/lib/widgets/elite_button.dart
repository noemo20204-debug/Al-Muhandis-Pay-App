import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/elite_theme.dart';

class EliteButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDanger; // لتحويل لون الزر للأحمر في حالات الحظر/الخروج

  const EliteButton({
    super.key, required this.text, this.onPressed,
    this.isLoading = false, this.isDanger = false,
  });

  @override
  State<EliteButton> createState() => _EliteButtonState();
}

class _EliteButtonState extends State<EliteButton> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.0, upperBound: 0.05)..addListener(() { setState(() {}); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _tapDown(TapDownDetails details) => _controller.forward();
  void _tapUp(TapUpDetails details) => _controller.reverse();
  void _tapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    final Color mainColor = widget.isDanger ? EliteColors.danger : EliteColors.goldPrimary;
    final List<BoxShadow> glow = widget.isDanger ? EliteShadows.neonDanger : EliteShadows.neonGold;

    return GestureDetector(
      onTapDown: widget.isLoading || widget.onPressed == null ? null : _tapDown,
      onTapUp: widget.isLoading || widget.onPressed == null ? null : _tapUp,
      onTapCancel: widget.isLoading || widget.onPressed == null ? null : _tapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: Transform.scale(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isLoading || widget.onPressed == null 
                ? const LinearGradient(colors: [Colors.grey, Colors.black54])
                : widget.isDanger ? null : EliteColors.goldGradient,
            color: widget.isDanger ? mainColor : null,
            boxShadow: widget.isLoading || widget.onPressed == null ? [] : glow,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : Text(widget.text, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDanger ? Colors.white : Colors.black, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }
}
