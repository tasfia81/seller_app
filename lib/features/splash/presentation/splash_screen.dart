import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/seller_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/widgets/brand_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (AppConfig.previewAuth) {
      if (mounted) context.go(AppRoutes.intro);
      return;
    }
    final session = ref.read(sellerSessionProvider);
    try {
      await session.restore();
    } catch (_) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }
    if (!mounted) return;
    context.go(session.user == null
        ? AppRoutes.intro
        : session.active ? AppRoutes.home : AppRoutes.applicationStatus);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkGreen,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const BrandLogo(size: 76, inverted: true),
              SizedBox(height: 16.h),
              Text(AppConfig.appName,
                  style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 4.h),
              Text('সেলার অ্যাপ', style: TextStyle(color: AppColors.onDarkMuted, fontSize: 14.sp)),
              const Spacer(flex: 2),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
              SizedBox(height: 10.h),
              Text('লোড হচ্ছে…', style: TextStyle(color: AppColors.onDarkMuted, fontSize: 13.sp)),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
