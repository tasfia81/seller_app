import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';
import '../../data/auth/auth_repository.dart';
import 'signup_draft.dart';

/// Step 1: the mobile number the investor will log in with. The server checks
/// it is not already used, so nobody fills five steps only to be refused.
class SignupMobileScreen extends ConsumerStatefulWidget {
  const SignupMobileScreen({super.key});

  @override
  ConsumerState<SignupMobileScreen> createState() => _SignupMobileScreenState();
}

class _SignupMobileScreenState extends ConsumerState<SignupMobileScreen> {
  late final _mobile = TextEditingController(text: ref.read(signupDraftProvider).mobile);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final mobile = Validators.mobile(_mobile.text);
    if (mobile == null) {
      setState(() => _error = 'সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন (০১ দিয়ে শুরু)।');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final free = await ref.read(authRepositoryProvider).mobileAvailable(mobile);
      if (!mounted) return;
      if (!free) {
        setState(() => _error = 'এই নম্বরে আগেই অ্যাকাউন্ট বা আবেদন আছে। লগইন করুন।');
        return;
      }
      ref.read(signupDraftProvider).mobile = mobile;
      context.push(AppRoutes.signupInfo);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      title: 'আপনার মোবাইল নম্বর',
      subtitle: 'এই নম্বর দিয়েই লগইন করবেন। নিজের নামে নিবন্ধিত নম্বর দিন।',
      buttonLabel: _busy ? 'যাচাই হচ্ছে…' : 'এগিয়ে যান',
      onNext: _busy ? null : _next,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('আগে থেকেই অ্যাকাউন্ট আছে?', style: AppText.caption),
          TextButton(onPressed: () => context.go(AppRoutes.login), child: const Text('লগইন')),
        ],
      ),
      children: [
        Text('মোবাইল নম্বর', style: AppText.label),
        SizedBox(height: 6.h),
        TextField(
          controller: _mobile,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
          style: AppText.body.copyWith(fontSize: 17.sp, height: 1.3),
          decoration: InputDecoration(
            counterText: '',
            hintText: '01XXXXXXXXX',
            errorText: _error,
            errorMaxLines: 3,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14.w, right: 10.w),
              child: Text('+৮৮', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _next(),
        ),
        SizedBox(height: 16.h),
        const InfoBox(
          tone: InfoTone.plain,
          icon: Icons.lock_outline_rounded,
          text: 'আমরা কখনো ফোন করে OTP বা পাসওয়ার্ড চাই না। কেউ চাইলে বুঝবেন সেটা প্রতারণা।',
        ),
      ],
    );
  }
}
