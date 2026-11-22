import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/widgets/ui.dart';

class SignupStatusScreen extends StatelessWidget {
  const SignupStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
            children: [
              Center(
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: const BoxDecoration(color: AppColors.softGreen, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: AppColors.primary, size: 40.r),
                ),
              ),
              SizedBox(height: 14.h),
              Text('আবেদন জমা হয়েছে', textAlign: TextAlign.center, style: AppText.headline),
              SizedBox(height: 4.h),
              Text('যাচাই হলেই SMS পাবেন', textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 15.sp)),
              SizedBox(height: 22.h),
              const AppCard(
                child: Column(
                  children: [
                    _Step(state: _S.done, title: 'আবেদন জমা', note: 'এইমাত্র'),
                    _Step(state: _S.active, title: 'পরিচয় ও তথ্য যাচাই', note: 'সাধারণত ১ কার্যদিবস লাগে'),
                    _Step(state: _S.todo, title: 'চুক্তিতে কোম্পানির সই', note: 'সই করা কপি অ্যাপে পাবেন'),
                    _Step(
                      state: _S.todo,
                      title: 'প্রথম বিনিয়োগ',
                      note: 'কোম্পানির ব্যাংক তথ্য তখন অ্যাপে দেখানো হবে — অন্য কোথাও টাকা পাঠাবেন না',
                      last: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              AppCard(
                onTap: () => showDemoNotice(context, 'হেল্পলাইন নম্বর এখনো বসানো হয়নি: ${AppConfig.helpline}'),
                child: Row(
                  children: [
                    const IconBox(icon: Icons.call_outlined),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('কোনো প্রশ্ন আছে?', style: AppText.bodyStrong),
                          Text('হেল্পলাইন ${AppConfig.helpline} · সকাল ১০টা–সন্ধ্যা ৬টা', style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),
              FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text('ঠিক আছে')),
              SizedBox(height: 8.h),
              Text('ডেমো: অনুমোদনের পরের হোম স্ক্রিন দেখাবে', textAlign: TextAlign.center, style: AppText.small),
            ],
          ),
        ),
      ),
    );
  }
}

enum _S { done, active, todo }

class _Step extends StatelessWidget {
  const _Step({required this.state, required this.title, required this.note, this.last = false});

  final _S state;
  final String title;
  final String note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final dot = switch (state) {
      _S.done => Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
      _S.active => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.amber, width: 3)),
        ),
      _S.todo => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderStrong, width: 2)),
        ),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              dot,
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _S.done ? AppColors.primary : const Color(0xFFDDE3E0),
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16.h, top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppText.bodyStrong.copyWith(
                            color: state == _S.todo ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (state == _S.active) ...[
                        SizedBox(width: 8.w),
                        const Pill('চলছে', background: AppColors.amberSoft, color: AppColors.amber),
                      ],
                    ],
                  ),
                  Text(note, style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
