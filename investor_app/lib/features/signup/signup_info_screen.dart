import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/bd_locations.dart';
import '../../core/utils/bn_format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import 'signup_draft.dart';

class SignupInfoScreen extends ConsumerStatefulWidget {
  const SignupInfoScreen({super.key});

  @override
  ConsumerState<SignupInfoScreen> createState() => _SignupInfoScreenState();
}

class _SignupInfoScreenState extends ConsumerState<SignupInfoScreen> {
  static const _occupations = ['চাকরিজীবী', 'ব্যবসায়ী', 'প্রবাসী', 'অন্যান্য'];
  static const _sources = ['বেতন / সঞ্চয়', 'ব্যবসার আয়', 'রেমিট্যান্স', 'অন্যান্য'];

  late final SignupDraft _d = ref.read(signupDraftProvider);
  late final _name = TextEditingController(text: _d.fullName);
  late final _email = TextEditingController(text: _d.email);
  late final _upazila = TextEditingController(text: _d.upazila);
  late final _detail = TextEditingController(text: _d.addressDetail);
  late final _amount = TextEditingController(text: _d.proposedAmount);
  late final _password = TextEditingController(text: _d.password);
  final _confirm = TextEditingController();
  bool _showPassword = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _upazila, _detail, _amount, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _d.dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'জন্মতারিখ বাছুন',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _d.dateOfBirth = picked;
        _errors.remove('dob');
      });
    }
  }

  void _next() {
    final e = <String, String>{};
    final name = _name.text.trim();
    if (name.length < 2) e['name'] = 'NID অনুযায়ী পুরো নাম দিন';
    final dob = _d.dateOfBirth;
    if (dob == null) {
      e['dob'] = 'জন্মতারিখ দিন';
    } else if (Validators.age(dob, DateTime.now()) < 18) {
      e['dob'] = 'বিনিয়োগ করতে বয়স কমপক্ষে ১৮ বছর হতে হবে';
    }
    if (_d.occupation.isEmpty) e['occupation'] = 'পেশা বাছুন';
    if (_email.text.trim().isNotEmpty && !Validators.email(_email.text)) e['email'] = 'সঠিক ইমেইল দিন অথবা ফাঁকা রাখুন';
    if (_d.fundsSource.isEmpty) e['source'] = 'টাকার উৎস বাছুন';
    if (_d.division == null) e['division'] = 'বিভাগ বাছুন';
    if (_d.district == null) e['district'] = 'জেলা বাছুন';
    if (_upazila.text.trim().length < 2) e['upazila'] = 'উপজেলা/থানা লিখুন';
    if (_detail.text.trim().length < 2) e['detail'] = 'বাড়ি ও রাস্তা লিখুন';
    final amount = Validators.amount(_amount.text);
    if (amount == null) e['amount'] = 'কত টাকা বিনিয়োগ করতে চান লিখুন';
    final pw = Validators.password(_password.text);
    if (pw != null) e['password'] = pw;
    if (pw == null && _confirm.text != _password.text) e['confirm'] = 'দুই পাসওয়ার্ড মেলেনি';

    setState(() => _errors = e);
    if (e.isNotEmpty) {
      showDemoNotice(context, 'লাল চিহ্নিত ঘরগুলো ঠিক করুন।');
      return;
    }
    _d
      ..fullName = name
      ..email = _email.text.trim()
      ..upazila = _upazila.text.trim()
      ..addressDetail = _detail.text.trim()
      ..proposedAmount = amount!.toStringAsFixed(0)
      ..password = _password.text;
    context.push(AppRoutes.signupKyc);
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: 14.h);
    final dob = _d.dateOfBirth;
    return StepScaffold(
      step: 2,
      title: 'আপনার পরিচয়',
      subtitle: 'NID-তে যেভাবে লেখা আছে, ঠিক সেভাবে দিন — চুক্তিতে এটাই যাবে।',
      buttonLabel: 'পরের ধাপ',
      onNext: _next,
      children: [
        LabeledField(
          label: 'পুরো নাম',
          hint: 'NID অনুযায়ী নাম',
          controller: _name,
          autofillHints: const [AutofillHints.name],
          errorText: _errors['name'],
        ),
        gap,
        LabeledField(
          key: ValueKey(dob),
          label: 'জন্মতারিখ',
          hint: 'দিন/মাস/বছর',
          initialValue: dob == null ? null : BnFormat.dateFull(dob),
          readOnly: true,
          onTap: _pickDob,
          suffix: const Icon(Icons.calendar_today_outlined, size: 20),
          errorText: _errors['dob'],
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledDropdown(
                label: 'পেশা',
                options: _occupations,
                hint: 'বাছুন',
                value: _d.occupation.isEmpty ? null : _d.occupation,
                errorText: _errors['occupation'],
                onChanged: (v) => setState(() => _d.occupation = v),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: LabeledDropdown(
                label: 'টাকার উৎস',
                options: _sources,
                hint: 'বাছুন',
                value: _d.fundsSource.isEmpty ? null : _d.fundsSource,
                errorText: _errors['source'],
                onChanged: (v) => setState(() => _d.fundsSource = v),
              ),
            ),
          ],
        ),
        gap,
        LabeledField(
          label: 'ইমেইল (ঐচ্ছিক — মাসিক রিপোর্টের জন্য)',
          hint: 'you@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          errorText: _errors['email'],
        ),
        gap,
        Text('বর্তমান ঠিকানা', style: AppText.label),
        SizedBox(height: 6.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledDropdown(
                label: '',
                options: bdDistricts.keys.toList(),
                hint: 'বিভাগ',
                value: _d.division,
                errorText: _errors['division'],
                onChanged: (v) => setState(() {
                  if (_d.division != v) _d.district = null;
                  _d.division = v;
                }),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: LabeledDropdown(
                label: '',
                options: bdDistricts[_d.division] ?? const [],
                hint: 'জেলা',
                value: _d.district,
                errorText: _errors['district'],
                onChanged: (v) => setState(() => _d.district = v),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        LabeledField(label: '', hint: 'উপজেলা / থানা', controller: _upazila, errorText: _errors['upazila']),
        SizedBox(height: 10.h),
        LabeledField(label: '', hint: 'বাড়ি, রোড, ব্লক', controller: _detail, errorText: _errors['detail']),
        gap,
        LabeledField(
          label: 'কত টাকা বিনিয়োগ করতে চান? (প্রস্তাবিত)',
          hint: 'যেমন: ১,০০,০০০',
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯,]'))],
          helper: 'এখন কোনো টাকা পাঠাবেন না — অনুমোদনের পর অ্যাপে কোম্পানির অ্যাকাউন্ট দেখানো হবে।',
          errorText: _errors['amount'],
        ),
        gap,
        LabeledField(
          label: 'পাসওয়ার্ড দিন',
          controller: _password,
          obscure: !_showPassword,
          autofillHints: const [AutofillHints.newPassword],
          helper: 'কমপক্ষে ৮ অক্ষর ও একটি সংখ্যা',
          errorText: _errors['password'],
          suffix: IconButton(
            tooltip: _showPassword ? 'পাসওয়ার্ড লুকান' : 'পাসওয়ার্ড দেখুন',
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        SizedBox(height: 10.h),
        LabeledField(
          label: 'পাসওয়ার্ড আবার দিন',
          controller: _confirm,
          obscure: !_showPassword,
          textInputAction: TextInputAction.done,
          errorText: _errors['confirm'],
        ),
      ],
    );
  }
}
