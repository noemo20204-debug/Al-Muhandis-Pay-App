import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/elite_theme.dart';

class GlassInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const GlassInput({
    super.key, required this.controller, required this.label,
    required this.icon, this.isPassword = false, this.keyboardType = TextInputType.text,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // التوهج الذهبي يظهر فقط عند الضغط على الحقل
        boxShadow: _isFocused ? EliteShadows.neonGold : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: GoogleFonts.cairo(color: _isFocused ? EliteColors.goldLight : Colors.grey.shade400, fontWeight: _isFocused ? FontWeight.bold : FontWeight.normal),
              prefixIcon: Icon(widget.icon, color: _isFocused ? EliteColors.goldLight : EliteColors.goldPrimary),
              suffixIcon: widget.isPassword ? IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => setState(() => _obscure = !_obscure),
              ) : null,
              filled: true,
              fillColor: EliteColors.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: EliteColors.goldLight, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: EliteColors.glassBorderDark, width: 1)),
            ),
          ),
        ),
      ),
    );
  }
}
