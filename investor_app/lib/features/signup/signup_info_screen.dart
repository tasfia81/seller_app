import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';

class SignupInfoScreen extends StatelessWidget {
  const SignupInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: 14.h);
    return StepScaffold(
      step: 2,
      title: 'আপনার পরিচয়',
      subtitle: 'NID-তে যেভাবে লেখা আছে, ঠিক সেভাবে দিন — চুক্তিতে এটাই যাবে।',
      buttonLabel: 'পরের ধাপ',
      onNext: () => context.push(AppRoutes.signupKyc),
      children: [
        const LabeledField(label: 'পুরো নাম', hint: 'NID অনুযায়ী নাম'),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: LabeledField(label: 'জন্মতারিখ', hint: 'দিন/মাস/বছর', keyboardType: TextInputType.datetime),
            ),
            SizedBox(width: 10.w),
            const Expanded(
              child: LabeledDropdown(label: 'পেশা', options: ['চাকরিজীবী', 'ব্যবসায়ী', 'প্রবাসী', 'অন্যান্য']),
            ),
          ],
        ),
        gap,
        const LabeledField(
          label: 'ইমেইল (ঐচ্ছিক — মাসিক রিপোর্টের জন্য)',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        gap,
        const LabeledDropdown(
          label: 'বিনিয়োগের টাকার উৎস',
          options: ['বেতন / সঞ্চয়', 'ব্যবসার আয়', 'রেমিট্যান্স', 'অন্যান্য'],
        ),
        gap,
        Text('বর্তমান ঠিকানা', style: AppText.label),
        SizedBox(height: 6.h),
        Row(
          children: [
            const Expanded(child: LabeledDropdown(label: '', options: ['ঢাকা', 'চট্টগ্রাম', 'গাজীপুর', 'নারায়ণগঞ্জ'])),
            SizedBox(width: 10.w),
            const Expanded(child: LabeledDropdown(label: '', options: ['মোহাম্মদপুর', 'মিরপুর', 'ধানমন্ডি', 'উত্তরা'])),
          ],
        ),
        SizedBox(height: 10.h),
        const LabeledField(label: 'বাড়ি ও রাস্তা', hint: 'বাড়ি, রোড, ব্লক'),
        gap,
        const LabeledField(
          label: 'পাসওয়ার্ড দিন',
          obscure: true,
          helper: 'কমপক্ষে ৮ অক্ষর ও একটি সংখ্যা',
        ),
      ],
    );
  }
}
