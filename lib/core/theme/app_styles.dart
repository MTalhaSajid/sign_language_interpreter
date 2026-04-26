import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  // ── Border radius ──────────────────────────────────────────────────────────
  static const radiusSm  = BorderRadius.all(Radius.circular(8));
  static const radiusMd  = BorderRadius.all(Radius.circular(12));
  static const radiusLg  = BorderRadius.all(Radius.circular(16));
  static const radiusXl  = BorderRadius.all(Radius.circular(24));
  static const radiusFull= BorderRadius.all(Radius.circular(100));

  // ── Padding ────────────────────────────────────────────────────────────────
  static const paddingPage     = EdgeInsets.symmetric(horizontal: 24);
  static const paddingCard     = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const paddingButton   = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
  static const paddingField    = EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  // ── Field decoration ───────────────────────────────────────────────────────
  static InputDecoration fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool focused = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: AppColors.textDim),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: focused ? AppColors.teal : AppColors.textSecondary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.bgSurface,
      contentPadding: paddingField,
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: AppColors.bgBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: AppColors.bgBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        color: AppColors.error,
        height: 1.4,
      ),
    );
  }

  // ── Card decoration ────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.bgSurface,
      borderRadius: borderRadius ?? radiusMd,
      border: Border.all(color: AppColors.bgBorder, width: 1),
    );
  }

  // ── Gradient button decoration ─────────────────────────────────────────────
  static BoxDecoration gradientButton({bool dimmed = false}) {
    return BoxDecoration(
      borderRadius: radiusMd,
      gradient: LinearGradient(
        colors: dimmed
            ? [
                AppColors.teal.withOpacity(0.5),
                AppColors.blue.withOpacity(0.5),
              ]
            : [AppColors.teal, AppColors.blue],
      ),
    );
  }

  // ── Logo mark decoration ───────────────────────────────────────────────────
  static BoxDecoration logoDecoration({double radius = 12}) {
    return BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      gradient: AppColors.brandGradient,
    );
  }

  // ── Glow circle ────────────────────────────────────────────────────────────
  static BoxDecoration glowDecoration(Color color, double opacity) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ),
    );
  }

  // ── Error container ────────────────────────────────────────────────────────
  static BoxDecoration errorDecoration() {
    return BoxDecoration(
      color: AppColors.errorBg,
      borderRadius: radiusMd,
      border: Border.all(color: AppColors.errorBorder, width: 1),
    );
  }
}