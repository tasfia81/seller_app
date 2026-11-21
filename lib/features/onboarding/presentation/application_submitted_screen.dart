import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      width: 88.r,
                      height: 88.r,
                      decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 44, color: AppColors.primary),
                    ),
                    SizedBox(height: 18.h),
                    Text('আবেদন জমা হয়েছে', style: AppText.headline.copyWith(fontSize: 22.sp)),
                    SizedBox(height: 10.h),
                    Text(
                      'আপনার আবেদন সফলভাবে জমা হয়েছে। অ্যাডমিন যাচাই করার পর আপনার অ্যাকাউন্ট চালু করা হবে।',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(fontSize: 15.sp, color: AppColors.textBody, height: 1.7),
                    ),
                    SizedBox(height: 18.h),
                    Text('যাচাই শেষ হলে নোটিফিকেশনে জানানো হবে। এর আগে বিক্রি শুরু করা যাবে না।',
                        textAlign: TextAlign.center, style: AppText.caption),
                  ]),
                ),
              ),
            ),
            AppButton(label: 'আবেদনের অবস্থা দেখুন', onPressed: () => context.go(AppRoutes.applicationStatus)),
            SizedBox(height: 8.h),
            const _DemoHint(),
          ]),
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint();

  @override
  Widget build(BuildContext context) {
    return const InfoBanner(
      tone: BannerTone.warning,
      icon: Icons.visibility_outlined,
      text: 'প্রিভিউ: সার্ভার চালু না হওয়ায় আবেদনটি আসলে কোথাও পাঠানো হয়নি।',
    );
  }
}
