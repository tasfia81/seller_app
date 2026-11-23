import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import 'signup_draft.dart';

class SignupPayoutScreen extends ConsumerStatefulWidget {
  const SignupPayoutScreen({super.key});

  @override
  ConsumerState<SignupPayoutScreen> createState() => _SignupPayoutScreenState();
}

class _SignupPayoutScreenState extends ConsumerState<SignupPayoutScreen> {
  static const _methods = ['bank', 'bkash', 'nagad'];
  static const _names = ['ব্যাংক', 'বিকাশ', 'নগদ'];
  static const _relations = ['স্ত্রী/স্বামী', 'বাবা/মা', 'সন্তান', 'ভাই/বোন', 'অন্যান্য'];

  late final SignupDraft _d = ref.read(signupDraftProvider);
  late int _via = _methods.indexOf(_d.payoutMethod).clamp(0, 2);
  late final _accName = TextEditingController(text: _d.accountName.isEmpty ? _d.fullName : _d.accountName);
  late final _accNumber = TextEditingController(text: _d.accountNumber);
  late final _bank = TextEditingController(text: _d.bankName);
  late final _branch = TextEditingController(text: _d.branch);
  late final _nomName = TextEditingController(text: _d.nomineeName);
  late final _nomMobile = TextEditingController(text: _d.nomineeMobile);
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_accName, _accNumber, _bank, _branch, _nomName, _nomMobile]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    final e = <String, String>{};
    final bank = _via == 0;
    if (_accName.text.trim().length < 2) e['accName'] = 'অ্যাকাউন্টের নাম দিন';
    String number;
    if (bank) {
      number = Validators.digitsOnly(_accNumber.text);
      if (number.length < 6 || number.length > 34) e['accNumber'] = 'সঠিক অ্যাকাউন্ট নম্বর দিন';
      if (_bank.text.trim().length < 2) e['bank'] = 'ব্যাংকের নাম দিন';
    } else {
      number = Validators.mobile(_accNumber.text) ?? '';
      if (number.isEmpty) e['accNumber'] = 'সঠিক ১১ সংখ্যার ${_names[_via]} নম্বর দিন';
    }
    if (_nomName.text.trim().length < 2) e['nomName'] = 'নমিনির নাম দিন';
    if (_d.nomineeRelation.isEmpty) e['relation'] = 'সম্পর্ক বাছুন';
    final nomMobile = Validators.mobile(_nomMobile.text);
    if (nomMobile == null) {
      e['nomMobile'] = 'সঠিক মোবাইল নম্বর দিন';
    } else if (nomMobile == _d.mobile) {
      e['nomMobile'] = 'নমিনির নম্বর আপনার নিজের নম্বর হতে পারবে না';
    }

    setState(() => _errors = e);
    if (e.isNotEmpty) {
      showDemoNotice(context, 'লাল চিহ্নিত ঘরগুলো ঠিক করুন।');
      return;
    }
    _d
      ..payoutMethod = _methods[_via]
      ..accountName = _accName.text.trim()
      ..accountNumber = number
      ..bankName = bank ? _bank.text.trim() : ''
      ..branch = bank ? _branch.text.trim() : ''
      ..nomineeName = _nomName.text.trim()
      ..nomineeMobile = nomMobile!;
    context.push(AppRoutes.signupAgreement);
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: 12.h);
    final digits = [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))];
    return StepScaffold(
      step: 4,
      title: 'লাভ কোথায় পাঠাব?',
      buttonLabel: 'পরের ধাপ',
      onNext: _next,
      children: [
        SegmentedTabs(
          labels: _names,
          index: _via,
          onChanged: (i) => setState(() {
            if (i != _via) _accNumber.clear();
            _via = i;
            _errors = {};
          }),
        ),
        SizedBox(height: 14.h),
        LabeledField(label: 'অ্যাকাউন্টের নাম', hint: 'NID-এর নামের মতো', controller: _accName, errorText: _errors['accName']),
        gap,
        if (_via == 0) ...[
          LabeledField(label: 'ব্যাংকের নাম', hint: 'যেমন: ডাচ-বাংলা ব্যাংক', controller: _bank, errorText: _errors['bank']),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: 'অ্যাকাউন্ট নম্বর',
                  controller: _accNumber,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  maxLength: 34,
                  errorText: _errors['accNumber'],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(child: LabeledField(label: 'শাখা (ঐচ্ছিক)', controller: _branch)),
            ],
          ),
        ] else
          LabeledField(
            key: ValueKey('wallet$_via'),
            label: '${_names[_via]} নম্বর (নিজের নামে নিবন্ধিত)',
            hint: '01XXXXXXXXX',
            controller: _accNumber,
            keyboardType: TextInputType.phone,
            inputFormatters: digits,
            maxLength: 11,
            errorText: _errors['accNumber'],
          ),
        SizedBox(height: 14.h),
        const InfoBox(
          icon: Icons.verified_user_outlined,
          text: 'শুধু আপনার নিজের নামের অ্যাকাউন্টেই টাকা যাবে। পরে বদলাতে হলে অফিস যাচাই করে বদলাবে।',
        ),
        SizedBox(height: 18.h),
        const Divider(),
        SizedBox(height: 14.h),
        Text('নমিনি', style: AppText.section),
        Text('আপনার অবর্তমানে বিনিয়োগ যিনি পাবেন', style: AppText.caption),
        SizedBox(height: 12.h),
        LabeledField(label: 'নমিনির নাম', controller: _nomName, errorText: _errors['nomName']),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledDropdown(
                label: 'সম্পর্ক',
                options: _relations,
                hint: 'বাছুন',
                value: _d.nomineeRelation.isEmpty ? null : _d.nomineeRelation,
                errorText: _errors['relation'],
                onChanged: (v) => setState(() => _d.nomineeRelation = v),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: LabeledField(
                label: 'মোবাইল',
                controller: _nomMobile,
                keyboardType: TextInputType.phone,
                inputFormatters: digits,
                maxLength: 11,
                textInputAction: TextInputAction.done,
                errorText: _errors['nomMobile'],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
