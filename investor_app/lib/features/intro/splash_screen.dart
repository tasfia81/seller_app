import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../data/auth/auth_controller.dart';
import 'brand_mark.dart';

/// Loads the fonts (so no screen flashes a fallback font) and restores the
/// saved session at the same time, then opens the right screen. If the server
/// cannot be reached with a saved session, it offers a retry instead of
/// silently logging the investor out.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 700));
    final fonts = GoogleFonts.pendingFonts(AppText.preload)
        .timeout(const Duration(milliseconds: 2500))
        .then((_) {}, onError: (_) {}); // Offline or slow: use the system font rather than block.
    try {
      await ref.read(authControllerProvider.notifier).restore();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    await Future.wait([fonts, minDelay]);
    if (!mounted) return;
    // Signed in → home (the router sends applicants to their status screen).
    context.go(ref.read(authControllerProvider) is SignedIn ? AppRoutes.home : AppRoutes.intro);
  }

  void _retry() {
    setState(() => _error = null);
    _start();
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
                if (_error != null) ...[
                  SizedBox(height: 28.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  SizedBox(height: 12.h),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                    onPressed: _retry,
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
