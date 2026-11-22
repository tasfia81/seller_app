import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';

class SignupPayoutScreen extends StatefulWidget {
  const SignupPayoutScreen({super.key});

  @override
  State<SignupPayoutScreen> createState() => _SignupPayoutScreenState();
}

class _SignupPayoutScreenState extends State<SignupPayoutScreen> {
  int _via = 0; // 0 ব্যাংক, 1 বিকাশ, 2 নগদ
  static const _names = ['ব্যাংক', 'বিকাশ', 'নগদ'];

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: 12.h);
    return StepScaffold(
      step: 4,
      title: 'লাভ কোথায় পাঠাব?',
      buttonLabel: 'পরের ধাপ',
      onNext: () => context.push(AppRoutes.signupAgreement),
      children: [
        SegmentedTabs(labels: _names, index: _via, onChanged: (i) => setState(() => _via = i)),
        SizedBox(height: 14.h),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _via == 0
              ? Column(
                  key: const ValueKey('bank'),
                  children: [
                    const LabeledDropdown(label: 'ব্যাংক', options: ['[ব্যাংক বাছুন]']),
                    gap,
                    const LabeledField(label: 'অ্যাকাউন্টের নাম', hint: 'NID-এর নামের মতো'),
                    gap,
                    Row(
                      children: [
                        const Expanded(
                          child: LabeledField(label: 'অ্যাকাউন্ট নম্বর', keyboardType: TextInputType.number),
                        ),
                        SizedBox(width: 10.w),
                        const Expanded(child: LabeledField(label: 'শাখা')),
                      ],
                    ),
                  ],
                )
              : LabeledField(
                  key: ValueKey('wallet$_via'),
                  label: '${_names[_via]} নম্বর (নিজের নামে নিবন্ধিত)',
                  hint: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                ),
        ),
        SizedBox(height: 14.h),
        const InfoBox(
          icon: Icons.verified_user_outlined,
          text: 'শুধু আপনার নিজের নামের অ্যাকাউন্টেই টাকা যাবে। মাধ্যম বদলাতে আবার OTP লাগবে।',
        ),
        SizedBox(height: 18.h),
        const Divider(),
        SizedBox(height: 14.h),
        Text('নমিনি', style: AppText.section),
        Text('আপনার অবর্তমানে বিনিয়োগ যিনি পাবেন', style: AppText.caption),
        SizedBox(height: 12.h),
        const LabeledField(label: 'নমিনির নাম'),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: LabeledDropdown(label: 'সম্পর্ক', options: ['স্ত্রী/স্বামী', 'বাবা/মা', 'সন্তান', 'ভাই/বোন']),
            ),
            SizedBox(width: 10.w),
            const Expanded(child: LabeledField(label: 'মোবাইল', keyboardType: TextInputType.phone)),
          ],
        ),
      ],
    );
  }
}
