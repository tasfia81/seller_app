import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale using Noto Sans Bengali for authentic Bangla typography.
abstract final class AppText {
  static TextStyle get headline => GoogleFonts.notoSansBengali(
      fontSize: 24.sp, fontWeight: FontWeight.w800, height: 1.35, color: AppColors.textPrimary);
  static TextStyle get pageTitle => GoogleFonts.notoSansBengali(
      fontSize: 18.sp, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.textPrimary);
  static TextStyle get section => GoogleFonts.notoSansBengali(
      fontSize: 15.sp, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary);
  static TextStyle get body => GoogleFonts.notoSansBengali(
      fontSize: 14.sp, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.textPrimary);
  static TextStyle get bodyStrong => GoogleFonts.notoSansBengali(
      fontSize: 14.sp, fontWeight: FontWeight.w600, height: 1.45, color: AppColors.textPrimary);
  static TextStyle get label => GoogleFonts.notoSansBengali(
      fontSize: 14.sp, fontWeight: FontWeight.w500, height: 1.4, color: AppColors.textPrimary);
  static TextStyle get caption => GoogleFonts.notoSansBengali(
      fontSize: 13.sp, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textSecondary);
  static TextStyle get small => GoogleFonts.notoSansBengali(
      fontSize: 12.sp, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.textSecondary);
  static TextStyle get button => GoogleFonts.notoSansBengali(
      fontSize: 16.sp, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get input => GoogleFonts.notoSansBengali(
      fontSize: 15.sp, height: 1.4, color: AppColors.textPrimary);

  static TextStyle amount(double size, {Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSansBengali(
          fontSize: size.sp, fontWeight: FontWeight.w700, height: 1.25, color: color);
}
