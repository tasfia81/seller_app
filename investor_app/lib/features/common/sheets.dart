import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';

String _d(int n) => BnFormat.digits('$n');

/// Contract terms in plain Bangla (used in sign-up and from the menu).
List<Widget> agreementTermRows() => [
      KeyValueRow('লাভের ভাগ', 'নিট লাভের ${_d(AppConfig.profitSharePercent)}%'),
      KeyValueRow('লাভ দেওয়ার দিন', 'প্রতি মাসের ${_d(AppConfig.payoutDayOfMonth)} তারিখ'),
      const KeyValueRow('সর্বনিম্ন বিনিয়োগ', AppConfig.minimumInvestment),
      KeyValueRow('মূলধন ফেরত', '${_d(AppConfig.capitalNoticeDays)} দিনের নোটিশে'),
      const KeyValueRow('ক্ষতি হলে', 'একই অনুপাতে ভাগ'),
      const KeyValueRow('লুকানো ফি', 'নেই', valueColor: AppColors.primary),
    ];

Future<void> showAgreementSheet(BuildContext context) => showInfoSheet(
      context,
      title: 'আমার চুক্তির শর্ত',
      children: [
        Consumer(builder: (_, ref, __) {
          final profile = ref.watch(investorProfileProvider);
          return profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => TextButton(onPressed: () => ref.invalidate(investorProfileProvider),
              child: const Text('আবার চেষ্টা করুন')),
            data: (row) {
              final terms = row['terms'] as Map;
              return Column(children: [
                KeyValueRow('লাভের ভাগ', '${BnFormat.digits('${terms['share_percent']}')}%'),
                KeyValueRow('লাভের দিন', BnFormat.digits('${terms['payout_day']}')),
                KeyValueRow('মূলধন ফেরতের নোটিশ', '${BnFormat.digits('${terms['notice_days']}')} দিন'),
              ]);
            },
          );
        }),
      ],
    );

Future<void> showInvestSheet(BuildContext context) async {
  final router = GoRouter.of(context);
  final ready = await showModalBottomSheet<bool>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('আরও বিনিয়োগ করুন', style: AppText.cardTitle),
          const SizedBox(height: 8),
          const Text('প্রস্তাবিত পরিমাণ অফিস সাপোর্টে পাঠান। অফিস আপনার সঙ্গে যোগাযোগ করবে।'),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(sheet, true), child: const Text('বিনিয়োগের বার্তা লিখুন')),
        ]),
      ),
    ),
  );
  if (ready == true) router.push(AppRoutes.supportNew('investment', 'বিনিয়োগ ও মূলধন'));
}

Future<void> showHelpSheet(BuildContext context) => showInfoSheet(
      context,
      title: 'সাহায্য ও হেল্পলাইন',
      children: [
        const _HelpRow(icon: Icons.call_outlined, title: 'হেল্পলাইন', value: '${AppConfig.helpline} · সকাল ১০টা–সন্ধ্যা ৬টা'),
        const _HelpRow(icon: Icons.location_on_outlined, title: 'অফিস', value: AppConfig.officeAddress),
        const _HelpRow(icon: Icons.verified_outlined, title: 'ট্রেড লাইসেন্স', value: AppConfig.tradeLicense),
        SizedBox(height: 8.h),
        const InfoBox(
          icon: Icons.lock_outline_rounded,
          text: 'আমরা কখনো ফোন করে OTP বা পাসওয়ার্ড চাই না।',
        ),
      ],
    );

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          IconBox(icon: icon),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong),
                Text(value, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
