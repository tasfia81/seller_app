import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/widgets/ui.dart';

/// Three trust-building onboarding pages.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pager = PageController();
  int _page = 0;

  static const _count = 3;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _count - 1) {
      context.go(AppRoutes.welcome);
    } else {
      _pager.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 12.w, 0),
                child: Row(
                  children: [
                    if (_page > 0)
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'আগের পাতা',
                        size: 44,
                        iconColor: AppColors.primary,
                        onTap: () => _pager.previousPage(
                            duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic),
                      )
                    else
                      Text('স্ট্রিট সেলস · বিনিয়োগ', style: AppText.bodyStrong),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.welcome),
                      child: Text('এড়িয়ে যান', style: AppText.label.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pager,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [_TrackPage(), _HowPage(), _TrustPage()],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
                child: Row(
                  children: [
                    Semantics(
                      label: 'পাতা ${_page + 1}, মোট $_count',
                      child: Row(
                        children: [
                          for (var i = 0; i < _count; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(right: 6),
                              width: i == _page ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _page ? AppColors.primary : AppColors.borderStrong,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 150.w,
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(_page == _count - 1 ? 'শুরু করি' : 'পরের ধাপ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.top, required this.title, required this.text, this.bottom});

  final Widget top;
  final String title;
  final String text;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      children: [
        top,
        SizedBox(height: 24.h),
        Text(title, style: AppText.headline.copyWith(fontSize: 28.sp)),
        SizedBox(height: 8.h),
        Text(text, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        if (bottom != null) ...[SizedBox(height: 18.h), bottom!],
      ],
    );
  }
}

class _TrackPage extends StatelessWidget {
  const _TrackPage();

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String label, String value, String? meta, {bool last = false, Color? bg, Color? fg}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              IconBox(icon: icon, background: bg ?? AppColors.softGreen, color: fg ?? AppColors.primary, size: 40),
              if (!last) Container(width: 2, height: 22.h, color: AppColors.borderStrong),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.small),
                  Text(value, style: AppText.cardTitle),
                ],
              ),
            ),
          ),
          if (meta != null) Padding(padding: EdgeInsets.only(top: 10.h), child: Text(meta, style: AppText.small)),
        ],
      );
    }

    return _PageBody(
      top: AppCard(
        radius: 24,
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            step(Icons.payments_outlined, 'আপনার বিনিয়োগ', '৳১০,০০০', '১২ অক্টো',
                bg: AppColors.primary, fg: Colors.white),
            step(Icons.checkroom_outlined, 'কেনা হলো', '২৮ পিস জার্সি', 'ব্যাচ-৮৮'),
            step(Icons.person_outline_rounded, 'সেলারের হাতে', 'রাকিব · মিরপুর', '১৩ অক্টো',
                bg: AppColors.amberSoft, fg: AppColors.amber),
            step(Icons.check_rounded, 'বিক্রি হলো', '২৮ পিস · আপনার লাভ ৳৭৮০', null, last: true),
          ],
        ),
      ),
      title: 'প্রতিটি টাকার হিসাব আপনার চোখের সামনে',
      text: 'টাকা দিয়ে অপেক্ষা নয় — কোন প্রোডাক্ট কেনা হলো, কার হাতে গেল, কবে বিক্রি হলো, সবকিছু অ্যাপে দেখবেন।',
    );
  }
}

class _HowPage extends StatelessWidget {
  const _HowPage();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('আপনি বিনিয়োগ করেন', 'কোম্পানির ব্যাংক অ্যাকাউন্টে — রসিদসহ'),
      ('আমরা পাইকারি দামে কাপড় কিনি', 'কেনার দাম ও সাপ্লায়ার আপনি দেখতে পাবেন'),
      ('যাচাই করা সেলাররা বিক্রি করে', 'NID যাচাই করা, প্রতিদিন হিসাব মেলানো হয়'),
      ('লাভ ভাগ হয়, মাসে মাসে পান', 'প্রতি মাসের ৫ তারিখে, আপনার বিকাশ বা ব্যাংকে'),
    ];
    return _PageBody(
      top: AppCard(
        radius: 24,
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 17.r,
                      backgroundColor: i == steps.length - 1 ? AppColors.amber : AppColors.primary,
                      child: Text('১২৩৪'[i], style: AppText.label.copyWith(color: Colors.white)),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$1, style: AppText.bodyStrong),
                          Text(steps[i].$2, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      title: 'আপনার টাকা যেভাবে কাজ করে',
      text: 'সহজ ৪টি ধাপ — কোনো লুকানো খরচ নেই।',
      bottom: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('উদাহরণ: ৳১০০ মোট লাভ হলে', style: AppText.label),
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                height: 30.h,
                child: Row(
                  children: [
                    _bar(40, 'সেলার ৳৪০', AppColors.amberSoft, AppColors.amber),
                    const SizedBox(width: 2),
                    _bar(30, 'আপনি ৳৩০', AppColors.primary, Colors.white),
                    const SizedBox(width: 2),
                    _bar(30, 'কোম্পানি ৳৩০', const Color(0xFFE6EBE8), AppColors.textPrimary),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text('অন্যান্য খরচ বাদে নিট লাভের ৫০% আপনার। হিসাব প্রতিটি প্রোডাক্টে দেখা যাবে।', style: AppText.small),
          ],
        ),
      ),
    );
  }

  static Widget _bar(int flex, String label, Color bg, Color fg) => Expanded(
        flex: flex,
        child: ColoredBox(
          color: bg,
          child: Center(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppText.small.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

class _TrustPage extends StatelessWidget {
  const _TrustPage();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (Icons.description_outlined, 'লিখিত বিনিয়োগ চুক্তি', 'দুই পক্ষের স্বাক্ষরসহ, অ্যাপে সংরক্ষিত'),
      (Icons.apartment_rounded, 'নিবন্ধিত প্রতিষ্ঠান', 'ট্রেড লাইসেন্স ${AppConfig.tradeLicense}'),
      (Icons.receipt_long_outlined, 'প্রতিটি লেনদেনের রসিদ', 'টাকা দেওয়া-নেওয়া সব খাতায় লেখা থাকে'),
      (Icons.shield_outlined, 'আপনার তথ্য গোপন', 'NID ও ব্যাংক তথ্য শুধু যাচাইয়ের জন্য'),
      (Icons.location_on_outlined, 'অফিসে এসে দেখা করুন', '${AppConfig.officeAddress} · ${AppConfig.helpline}'),
    ];
    return _PageBody(
      top: AppCard(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  children: [
                    Icon(rows[i].$1, color: AppColors.primary, size: 22.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].$2, style: AppText.bodyStrong),
                          Text(rows[i].$3, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1) const Divider(),
            ],
          ],
        ),
      ),
      title: 'বিশ্বাস কাগজে-কলমে',
      text: 'মুখের কথা নয় — চুক্তি, রসিদ আর ঠিকানা দিয়ে।',
      bottom: const InfoBox(
        tone: InfoTone.warn,
        icon: Icons.warning_amber_rounded,
        text: 'সৎভাবে বলছি: এটা ব্যবসায় অংশীদারি, ব্যাংক ডিপোজিট নয়। বিক্রি কম হলে লাভ কমতে পারে, তাই যে টাকা জরুরি দরকার, সেটা বিনিয়োগ করবেন না।',
      ),
    );
  }
}
