import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/ui.dart';

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
      title: 'আমার চুক্তিপত্র',
      children: [
        ...agreementTermRows(),
        SizedBox(height: 16.h),
        OutlinedButton.icon(
          onPressed: () => showDemoNotice(context, 'ডেমো মোড: সই করা চুক্তির PDF সার্ভার যুক্ত হলে পাওয়া যাবে।'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('পুরো চুক্তিপত্র (PDF)'),
        ),
      ],
    );

Future<void> showInvestSheet(BuildContext context) => showInfoSheet(
      context,
      title: 'আরও বিনিয়োগ করুন',
      children: [
        for (final (i, s) in const [
          'অনুরোধ পাঠান — আমরা ফোন করে পরিমাণ ও প্রোডাক্ট ঠিক করব',
          'নতুন কিস্তির চুক্তি অ্যাপে আসবে, OTP দিয়ে সই করবেন',
          'শুধু অ্যাপে দেখানো কোম্পানির ব্যাংক অ্যাকাউন্টে টাকা পাঠাবেন',
          'টাকা পৌঁছালে রসিদ খাতায় যোগ হবে, তারপর কেনাকাটা',
        ].indexed)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13.r,
                  backgroundColor: AppColors.primary,
                  child: Text(_d(i + 1), style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 12.w),
                Expanded(child: Text(s, style: AppText.bodySmall)),
              ],
            ),
          ),
        SizedBox(height: 6.h),
        const InfoBox(
          tone: InfoTone.warn,
          icon: Icons.warning_amber_rounded,
          text: 'কেউ ফোন করে অন্য কোনো নম্বরে টাকা পাঠাতে বললে পাঠাবেন না।',
        ),
        SizedBox(height: 16.h),
        FilledButton(
          onPressed: () => showDemoNotice(context, 'ডেমো মোড: অনুরোধ এখনো সার্ভারে যায় না।'),
          child: const Text('বিনিয়োগের অনুরোধ পাঠান'),
        ),
      ],
    );

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
