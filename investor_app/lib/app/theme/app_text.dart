import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography — Hind Siliguri, as in the design.
abstract final class AppText {
  static TextStyle _f(double size, FontWeight w, {double height = 1.45, Color color = AppColors.textPrimary}) =>
      GoogleFonts.hindSiliguri(fontSize: size.sp, fontWeight: w, height: height, color: color);

  static TextStyle get display => _f(30, FontWeight.w700, height: 1.25);
  static TextStyle get headline => _f(26, FontWeight.w700, height: 1.3);
  static TextStyle get title => _f(22, FontWeight.w700, height: 1.3);
  static TextStyle get section => _f(18, FontWeight.w700, height: 1.35);
  static TextStyle get cardTitle => _f(16, FontWeight.w700, height: 1.35);
  static TextStyle get bodyStrong => _f(15, FontWeight.w600);
  static TextStyle get body => _f(15, FontWeight.w400, height: 1.55);
  static TextStyle get label => _f(14, FontWeight.w600);
  static TextStyle get bodySmall => _f(14, FontWeight.w400, height: 1.5);
  static TextStyle get caption => _f(13, FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static TextStyle get small => _f(12, FontWeight.w400, height: 1.4, color: AppColors.textSecondary);
  static TextStyle get button => _f(16, FontWeight.w600, height: 1.3);

  static TextStyle amount(double size, {Color color = AppColors.textPrimary}) =>
      _f(size, FontWeight.w700, height: 1.2, color: color);

  /// Fonts used by the app, pre-loaded on the splash screen so the first
  /// frames never flash a fallback font.
  static List<TextStyle> get preload => [
        GoogleFonts.hindSiliguri(fontWeight: FontWeight.w400),
        GoogleFonts.hindSiliguri(fontWeight: FontWeight.w500),
        GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
        GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
      ];
}
