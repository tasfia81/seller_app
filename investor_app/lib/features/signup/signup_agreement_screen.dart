import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import '../../data/auth/auth_controller.dart';
import '../../data/auth/auth_models.dart';
import '../../data/auth/auth_repository.dart';
import '../common/sheets.dart';
import 'signup_draft.dart';

class SignupAgreementScreen extends ConsumerStatefulWidget {
  const SignupAgreementScreen({super.key});

  @override
  ConsumerState<SignupAgreementScreen> createState() => _SignupAgreementScreenState();
}

class _SignupAgreementScreenState extends ConsumerState<SignupAgreementScreen> {
  static const _texts = [
    'আমি বুঝেছি এটা ব্যবসায় বিনিয়োগ — লাভ নিশ্চিত নয়, ক্ষতিও হতে পারে।',
    'আমার দেওয়া তথ্য ও টাকার উৎস সত্য ও বৈধ।',
    'আমি চুক্তিপত্র ও গোপনীয়তা নীতি পড়েছি এবং মেনে নিচ্ছি।',
  ];
  final _checked = [false, false, false];

  /// null = idle; otherwise what is happening right now.
  String? _progress;
  String _otp = '';

  Future<void> _requestOtp() async {
    final mobile = ref.read(signupDraftProvider).mobile;
    if (mobile.isEmpty) {
      context.go(AppRoutes.signupMobile);
      return;
    }
    setState(() => _progress = 'কোড পাঠানো হচ্ছে…');
    try {
      await ref.read(authRepositoryProvider).requestApplicationOtp(mobile);
      if (mounted) showDemoNotice(context, 'নম্বরটি উপলব্ধ হলে SMS কোড পাঠানো হবে।');
    } on ApiException catch (error) {
      if (mounted) showDemoNotice(context, error.message);
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _submit() async {
    final draft = ref.read(signupDraftProvider);
    if (draft.dateOfBirth == null || draft.mobile.isEmpty || draft.photos.length != 3) {
      // Draft lost (e.g. app was killed): start again rather than send half a form.
      showDemoNotice(context, 'কিছু তথ্য হারিয়ে গেছে। প্রথম ধাপ থেকে আবার দিন।');
      context.go(AppRoutes.signupMobile);
      return;
    }
    setState(() => _progress = 'আবেদন জমা হচ্ছে…');
    try {
      await ref.read(authControllerProvider.notifier).submitApplication({...draft.toJson(), 'otp_code': _otp});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _progress = null);
      _showSubmitError(e);
      return;
    }

    // The application exists now. Photos go one by one; any that fail can be
    // uploaded again from the status screen, so we never lose the application.
    final repo = ref.read(authRepositoryProvider);
    final photos = draft.photos;
    final failed = <String>[];
    var n = 0;
    for (final entry in photos.entries) {
      n++;
      if (mounted) setState(() => _progress = 'ছবি পাঠানো হচ্ছে (${BnFormat.digits('$n')}/${BnFormat.digits('${photos.length}')})…');
      try {
        await repo.uploadDocument(entry.key, entry.value);
      } on ApiException {
        failed.add(entry.key);
      }
    }
    ref.invalidate(signupDraftProvider); // Wipe the password and photos from memory.
    if (!mounted) return;
    if (failed.isNotEmpty) {
      showDemoNotice(context, 'আবেদন জমা হয়েছে, কিন্তু ${failed.map(DocKind.label).join(', ')} যায়নি। পরের স্ক্রিন থেকে আবার দিন।');
    }
    context.go(AppRoutes.signupStatus);
  }

  void _showSubmitError(ApiException e) {
    if (e.code == 'mobile_exists') {
      showDemoNotice(context, e.message);
      context.go(AppRoutes.login);
      return;
    }
    final issues = e.fieldIssues;
    showInfoSheet(
      context,
      title: 'আবেদন জমা হয়নি',
      children: [
        Text(e.message, style: AppText.body),
        if (issues.isNotEmpty) ...[
          SizedBox(height: 10.h),
          for (final i in issues.entries) Text('• ${_fieldName(i.key)}: ${i.value}', style: AppText.bodySmall),
        ],
        SizedBox(height: 16.h),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ঠিক আছে')),
      ],
    );
  }

  static String _fieldName(String field) {
    const names = {
      'full_name': 'নাম', 'mobile': 'মোবাইল', 'date_of_birth': 'জন্মতারিখ', 'email': 'ইমেইল', 'nid_number': 'NID নম্বর',
      'proposed_amount': 'বিনিয়োগের পরিমাণ', 'password': 'পাসওয়ার্ড', 'payout.account_number': 'অ্যাকাউন্ট নম্বর',
      'payout.account_name': 'অ্যাকাউন্টের নাম', 'nominee.mobile': 'নমিনির মোবাইল', 'nominee.name': 'নমিনির নাম',
    };
    if (names.containsKey(field)) return names[field]!;
    if (field.startsWith('address')) return 'ঠিকানা';
    return field;
  }

  @override
  Widget build(BuildContext context) {
    final done = _checked.where((c) => c).length;
    final ready = done == _texts.length && _otp.length == 6;
    final busy = _progress != null;
    return PopScope(
      canPop: !busy, // Don't leave halfway through sending.
      child: StepScaffold(
        step: 5,
        title: 'চুক্তির মূল কথা',
        subtitle: 'সহজ ভাষায় — জমা দেওয়ার আগে একবার পড়ে নিন।',
        buttonLabel: busy
            ? _progress!
            : ready
                ? 'সম্মতি দিয়ে আবেদন জমা দিন'
                : done == _texts.length ? '৬ সংখ্যার SMS কোড দিন' : 'সবগুলো টিক দিন (${BnFormat.digits('$done')}/${BnFormat.digits('${_texts.length}')})',
        onNext: ready && !busy ? _submit : null,
        children: [
          TextButton(onPressed: busy ? null : _requestOtp, child: const Text('মোবাইলে SMS কোড পাঠান')),
          TextField(
            keyboardType: TextInputType.number, maxLength: 6,
            onChanged: (value) => setState(() => _otp = BnFormat.toAscii(value).replaceAll(RegExp(r'[^0-9]'), '')),
            decoration: const InputDecoration(labelText: 'SMS কোড'),
          ),
          AppCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(children: agreementTermRows()),
          ),
          SizedBox(height: 12.h),
          for (var i = 0; i < _texts.length; i++)
            CheckboxListTile(
              value: _checked[i],
              onChanged: busy ? null : (v) => setState(() => _checked[i] = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              title: Text(_texts[i], style: AppText.bodySmall),
            ),
        ],
      ),
    );
  }
}
