import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import '../common/sheets.dart';

class SignupAgreementScreen extends StatefulWidget {
  const SignupAgreementScreen({super.key});

  @override
  State<SignupAgreementScreen> createState() => _SignupAgreementScreenState();
}

class _SignupAgreementScreenState extends State<SignupAgreementScreen> {
  static const _texts = [
    'আমি বুঝেছি এটা ব্যবসায় বিনিয়োগ — লাভ নিশ্চিত নয়, ক্ষতিও হতে পারে।',
    'আমার দেওয়া তথ্য ও টাকার উৎস সত্য ও বৈধ।',
    'আমি চুক্তিপত্র ও গোপনীয়তা নীতি পড়েছি এবং মেনে নিচ্ছি।',
  ];
  final _checked = [false, false, false];

  @override
  Widget build(BuildContext context) {
    final done = _checked.where((c) => c).length;
    final ready = done == _texts.length;
    return StepScaffold(
      step: 5,
      title: 'চুক্তির মূল কথা',
      subtitle: 'সহজ ভাষায় — সই করার আগে একবার পড়ে নিন।',
      buttonLabel: ready
          ? 'OTP দিয়ে সই করুন ও জমা দিন'
          : 'সবগুলো টিক দিন (${BnFormat.digits('$done')}/${BnFormat.digits('${_texts.length}')})',
      onNext: ready ? () => context.go(AppRoutes.signupStatus) : null,
      children: [
        AppCard(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(children: agreementTermRows()),
        ),
        SizedBox(height: 12.h),
        OutlinedButton.icon(
          onPressed: () => showDemoNotice(context, 'ডেমো মোড: চুক্তিপত্রের PDF সার্ভার যুক্ত হলে দেখা যাবে।'),
          icon: const Icon(Icons.description_outlined),
          label: const Text('পুরো চুক্তিপত্র পড়ুন (PDF)'),
        ),
        SizedBox(height: 8.h),
        for (var i = 0; i < _texts.length; i++)
          CheckboxListTile(
            value: _checked[i],
            onChanged: (v) => setState(() => _checked[i] = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(_texts[i], style: AppText.bodySmall),
          ),
      ],
    );
  }
}
