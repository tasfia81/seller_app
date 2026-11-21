import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Typography scale. Uses the system font, which on Android renders Bangla
/// with Noto Sans Bengali. To bundle a font, add it under assets/fonts and
/// set `fontFamily` in app_theme.dart.
abstract final class AppText {
  static TextStyle get headline => TextStyle(
      fontSize: 24.sp, fontWeight: FontWeight.w800, height: 1.35, color: AppColors.textPrimary);
  static TextStyle get pageTitle => TextStyle(
      fontSize: 18.sp, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.textPrimary);
  static TextStyle get section => TextStyle(
      fontSize: 15.sp, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary);
  static TextStyle get body => TextStyle(
      fontSize: 14.sp, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.textPrimary);
  static TextStyle get bodyStrong => TextStyle(
      fontSize: 14.sp, fontWeight: FontWeight.w600, height: 1.45, color: AppColors.textPrimary);
  static TextStyle get label => TextStyle(
      fontSize: 14.sp, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.textPrimary);
  static TextStyle get caption => TextStyle(
      fontSize: 13.sp, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static TextStyle get small => TextStyle(
      fontSize: 12.sp, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);
  static TextStyle get button => TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get input => TextStyle(fontSize: 15.sp, height: 1.4, color: AppColors.textPrimary);

  static TextStyle amount(double size, {Color color = AppColors.textPrimary}) =>
      TextStyle(fontSize: size.sp, fontWeight: FontWeight.w700, height: 1.25, color: color);
}
