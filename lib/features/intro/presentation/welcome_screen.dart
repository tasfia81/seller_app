import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/widgets/app_button.dart';
import 'widgets/intro_art.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          const Expanded(flex: 11, child: IntroHero(alt: true, child: WelcomeArt())),
          Expanded(
            flex: 10,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                child: Column(children: [
                  Text('স্ট্রিট সেলসে স্বাগতম', textAlign: TextAlign.center, style: AppText.headline),
                  SizedBox(height: 6.h),
                  Text('শিক্ষার্থীদের জন্য পার্টটাইম কাজ — নিজের সময়ে, নিজের গতিতে আয় করুন।',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  AppButton(
                    label: 'লগইন করুন',
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.login),
                  ),
                  SizedBox(height: 10.h),
                  AppButton(
                    label: 'পার্টটাইম কাজের জন্য আবেদন করুন',
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                  if (AppConfig.demoMode)
                    AppButton(
                      label: 'ডেমো: সরাসরি অ্যাপ দেখুন',
                      variant: AppButtonVariant.text,
                      compact: true,
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
