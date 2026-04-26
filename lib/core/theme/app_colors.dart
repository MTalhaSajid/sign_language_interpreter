import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const teal       = Color(0xFF0ABFA3);
  static const blue       = Color(0xFF3D6BFF);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const bgDark     = Color(0xFF080E1C); // main scaffold bg
  static const bgSurface  = Color(0xFF0F1623); // cards, fields
  static const bgBorder   = Color(0xFF1E2A40); // borders, dividers
  static const bgLoader   = Color(0xFF1A2236); // loader track

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFE8EDF5); // headings, input text
  static const textSecondary = Color(0xFF4A5880); // labels, hints
  static const textDim       = Color(0xFF2E3D5A); // very muted text, placeholders

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const error      = Colors.redAccent;
  static const errorBg    = Color(0x14FF5252); // red with 8% opacity
  static const errorBorder= Color(0x40FF5252); // red with 25% opacity
  static const success    = Color(0xFF0ABFA3); // reuse teal
  static const warning    = Colors.orangeAccent;

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, blue],
  );

  static const brandGradientHorizontal = LinearGradient(
    colors: [teal, blue],
  );
}