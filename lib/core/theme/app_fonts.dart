import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppFonts {
  AppFonts._();

  // ── Base font: DM Sans ─────────────────────────────────────────────────────
  // Clean, modern, great for accessibility apps

  static TextStyle get _base => GoogleFonts.dmSans(
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  // ── Display / Hero ─────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  // ── Headings ───────────────────────────────────────────────────────────────
  static TextStyle get headingLarge => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get headingMedium => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headingSmall => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  // ── Body ───────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Labels ─────────────────────────────────────────────────────────────────
  static TextStyle get labelCaps => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Button ─────────────────────────────────────────────────────────────────
  static TextStyle get button => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  // ── Input ──────────────────────────────────────────────────────────────────
  static TextStyle get input => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get inputHint => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDim,
      );

  // ── Link ───────────────────────────────────────────────────────────────────
  static TextStyle get link => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.teal,
      );

  // ── Version / Caption ──────────────────────────────────────────────────────
  static TextStyle get caption => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textDim,
        letterSpacing: 2.5,
      );
}