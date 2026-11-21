import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';

/// Clean, modern, human-centric hero wrapper for onboarding slides.
class IntroHero extends StatelessWidget {
  const IntroHero({super.key, required this.child, this.alt = false});

  final Widget child;
  final bool alt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: alt
              ? const [Color(0xFFE8F5E9), Color(0xFFF4FAF6), Colors.white]
              : const [Color(0xFFE0F2E9), Color(0xFFF1F8F4), Colors.white],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Slide 1 — Earning alongside studies.
/// Clean, professional seller dashboard showcase.
class IntroArtOne extends StatelessWidget {
  const IntroArtOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFD6EAE0)),
        boxShadow: const [
          BoxShadow(color: Color(0x140B3D2E), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'শিক্ষার্থী বিক্রেতা',
                            style: AppText.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                      ],
                    ),
                    Text('পার্টটাইম কাজ · নিজের সময়', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F4),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFC7E8D6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('আজকের আয়', style: AppText.small.copyWith(color: AppColors.textSecondary)),
                      SizedBox(height: 2.h),
                      Text('৳৮৫০', style: AppText.amount(22, color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4.w),
                      Text('৩ ঘণ্টায় অর্জিত', style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _benefitChip(Icons.access_time_rounded, 'ফ্লেক্সিবল সময়'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _benefitChip(Icons.auto_graph_rounded, 'দৈনিক কমিশন'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                text,
                style: AppText.small.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

/// Slide 2 — 3-step workflow.
/// Clean, structured progress steps.
class IntroArtTwo extends StatelessWidget {
  const IntroArtTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFD6EAE0)),
        boxShadow: const [
          BoxShadow(color: Color(0x140B3D2E), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.touch_app_rounded, color: AppColors.successText, size: 20),
              ),
              SizedBox(width: 10.w),
              Text('সহজ ৩টি ধাপে শুরু করুন', style: AppText.label.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 14.h),
          _stepRow('১', Icons.inventory_2_outlined, 'কোম্পানি পণ্য দেবে', 'বিনা পুঁজিতে পণ্য গ্রহণ করুন'),
          SizedBox(height: 10.h),
          _stepRow('২', Icons.phone_android_rounded, 'মোবাইলে ৩ ট্যাপে বিক্রি', 'সহজে বিক্রি লিখুন ও রসিদ দিন'),
          SizedBox(height: 10.h),
          _stepRow('৩', Icons.payments_outlined, 'কমিশন নিজের কাছে রাখুন', 'বিক্রির সাথে সাথে লাভ নিশ্চিত'),
        ],
      ),
    );
  }

  Widget _stepRow(String num, IconData icon, String title, String subtitle) => Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 26.r,
              height: 26.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                num,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 10.w),
            Icon(icon, color: AppColors.primaryDark, size: 20),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.label.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Slide 3 — Transparent commission and payouts.
class IntroArtThree extends StatelessWidget {
  const IntroArtThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: const Color(0xFFD6EAE0)),
        boxShadow: const [
          BoxShadow(color: Color(0x140B3D2E), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50.r,
                height: 50.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFFC7E8D6)),
                ),
                child: Text('৫০%', style: AppText.headline.copyWith(color: AppColors.successText, fontSize: 18.sp)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('লাভের ৫০% সরাসরি কমিশন',
                        style: AppText.label.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('স্বচ্ছ ও তাৎক্ষণিক হিসাব',
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _bullet(Icons.check_circle_outline_rounded, 'প্রতিটি বিক্রির হিসাব অ্যাপেই আপডেট হয়'),
          SizedBox(height: 8.h),
          _bullet(Icons.check_circle_outline_rounded, 'বিকাশ, নগদ বা ক্যাশে পেমেন্ট সুবিধা'),
          SizedBox(height: 8.h),
          _bullet(Icons.check_circle_outline_rounded, 'কোনো গোপন চার্জ বা জামানত নেই'),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text, style: AppText.body.copyWith(fontSize: 13.sp, height: 1.4)),
          ),
        ],
      );
}

/// Welcome Screen Art — Friendly brand badge with value points.
class WelcomeArt extends StatelessWidget {
  const WelcomeArt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x1A1B5E20), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, size: 40, color: AppColors.primary),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F5),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'শিক্ষার্থীদের নির্ভরযোগ্য পার্টটাইম কাজ',
                  style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
