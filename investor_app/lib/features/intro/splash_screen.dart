import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import 'brand_mark.dart';

/// Loads the fonts first (so no screen ever flashes a fallback font), then
/// moves on. Never waits more than ~2.5 s, even offline.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      await GoogleFonts.pendingFonts(AppText.preload).timeout(const Duration(milliseconds: 2500));
    } catch (_) {
      // Offline or slow: continue with the system font rather than block.
    }
    await minDelay;
    if (mounted) context.go(AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 64),
                SizedBox(height: 16.h),
                const Text(
                  'স্ট্রিট সেলস',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                const Text('বিনিয়োগ', style: TextStyle(color: AppColors.onPrimaryMuted, fontSize: 14, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
