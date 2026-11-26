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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 20.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 36.h),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 12.h),
                        const WelcomeArt(),
                        SizedBox(height: 20.h),
                        Text(
                          'স্ট্রিট সেলসে স্বাগতম',
                          textAlign: TextAlign.center,
                          style: AppText.headline,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'শিক্ষার্থীদের জন্য পার্টটাইম কাজ — নিজের সময়ে, নিজের গতিতে আয় করুন।',
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 20.h),
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: const Color(0xFFE2EFE7)),
                          ),
                          child: Column(
                            children: [
                              _perkRow('বিনা পুঁজিতে কাজ শুরু করুন'),
                              SizedBox(height: 10.h),
                              _perkRow('ক্লাসের ফাঁকে সুবিধাজনক সময়ে কাজ'),
                              SizedBox(height: 10.h),
                              _perkRow('প্রতি বিক্রিতে নিশ্চিত ও স্বচ্ছ কমিশন'),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(height: 20.h),
                        AppButton(
                          label: 'লগইন করুন',
                          onPressed: () => context.push(AppRoutes.login),
                        ),
                        SizedBox(height: 10.h),
                        AppButton(
                          label: 'পার্টটাইম কাজের জন্য আবেদন করুন',
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.push(AppRoutes.register),
                        ),
                        if (AppConfig.previewAuth) ...[
                          SizedBox(height: 6.h),
                          AppButton(
                            label: 'ডেমো: সরাসরি অ্যাপ দেখুন',
                            variant: AppButtonVariant.text,
                            compact: true,
                            onPressed: () => context.go(AppRoutes.home),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _perkRow(String text) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: AppColors.successText),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppText.bodyStrong.copyWith(fontSize: 13.sp),
            ),
          ),
        ],
      );
}
