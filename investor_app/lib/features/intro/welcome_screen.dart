import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import 'brand_mark.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _paper = Color(0xFFF9F8F3);
  static const _rule = Color(0xFFDDDFD5);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: BrandMark(size: 31, outlined: false),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('স্ট্রিট সেলস', style: AppText.cardTitle),
                                    Text('বিনিয়োগ', style: AppText.small),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 17),
                          const Divider(color: _rule),
                          const SizedBox(height: 30),
                          Text(
                            'আপনার বিনিয়োগের হিসাব',
                            style: AppText.display.copyWith(color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'স্ট্রিট সেলস আপনার বিনিয়োগে পোশাক কেনে। সেলাররা সেগুলো বিক্রি করেন।',
                            style: AppText.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 26),
                          const Divider(color: _rule),
                          const _DetailRow(
                            icon: Icons.inventory_2_outlined,
                            label: 'পণ্য ও স্টক',
                            detail: 'কোন পণ্যে কত টাকা খাটছে',
                          ),
                          const Divider(color: _rule),
                          const _DetailRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'লেনদেন',
                            detail: 'জমা, পরিশোধ ও মূলধন ফেরত',
                          ),
                          const Divider(color: _rule),
                          const _DetailRow(
                            icon: Icons.bar_chart_rounded,
                            label: 'মাসিক রিপোর্ট',
                            detail: 'বিক্রি ও লাভের হিসাব',
                          ),
                          const Divider(color: _rule),
                          const Spacer(),
                          const SizedBox(height: 28),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => context.push(AppRoutes.signupMobile),
                            child: const Text('বিনিয়োগের জন্য আবেদন করুন'),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.login),
                            child: Text('অ্যাকাউন্ট আছে? লগইন করুন', style: AppText.label.copyWith(color: AppColors.primaryDark)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'বিনিয়োগে ঝুঁকি আছে। লাভ নিশ্চিত নয়।',
                            style: AppText.small,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.detail});

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.primary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.bodyStrong),
                Text(detail, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
