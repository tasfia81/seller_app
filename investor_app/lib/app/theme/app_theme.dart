import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    // InkRipple is cheaper than the default sparkle shader (no first-tap jank).
    splashFactory: InkRipple.splashFactory,
  );
  final font = GoogleFonts.hindSiliguri().fontFamily;
  final radius = BorderRadius.circular(12.r);

  OutlineInputBorder border(Color c, [double w = 1.5]) =>
      OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      hintStyle: TextStyle(fontFamily: font, color: AppColors.textSecondary, fontSize: 15.sp),
      border: border(AppColors.borderStrong),
      enabledBorder: border(AppColors.borderStrong),
      focusedBorder: border(AppColors.primary, 2),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.borderStrong,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: Size.fromHeight(54.h.clamp(50, 60).toDouble()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        textStyle: TextStyle(fontFamily: font, fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.white,
        minimumSize: Size.fromHeight(54.h.clamp(50, 60).toDouble()),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        textStyle: TextStyle(fontFamily: font, fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, 44),
        textStyle: TextStyle(fontFamily: font, fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : Colors.white),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dark,
      contentTextStyle: TextStyle(fontFamily: font, fontSize: 14.sp, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.glassSurface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.glassSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.softGreen,
      height: 68.h.clamp(64, 76).toDouble(),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: font,
            fontSize: 12.sp,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          )),
    ),
  );
}
