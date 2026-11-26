import '../../../core/api/api_client.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/inputs.dart';
import '../data/auth_repository.dart';

/// Mobile → OTP → new password. OTP is never simulated: until the backend is
/// connected, each step shows that the service is not live yet. In demo mode
/// the next screen can still be previewed, clearly marked as a preview.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0;
  bool _loading = false;
  bool _previewOnly = false;
  String? _error;
  final _mobileForm = GlobalKey<FormState>();
  final _passForm = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  Timer? _timer;
  int _seconds = 0;

  static const _titles = ['মোবাইল নম্বর', 'কোড যাচাই', 'নতুন পাসওয়ার্ড'];

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_mobile, _otp, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  Future<void> _run(Future<void> Function() call, VoidCallback onSuccess) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await call();
      if (mounted) onSuccess();
    } on NotConnectedFailure catch (e) {
      if (!mounted) return;
      if (AppConfig.previewAuth) {
        _previewOnly = true;
        onSuccess();
      } else {
        setState(() => _error = e.message);
      }
    } on ApiException catch (error) {
      if (mounted && error.code == 'invalid_otp') setState(() => _step = 1);
      if (mounted) showAppSnack(context, error.message, error: true);
    } catch (e) {
      if (mounted) setState(() => _error = failureMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sendCode() {
    if (!_mobileForm.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    _run(() => repo.requestOtp(Validators.normalizePhone(_mobile.text)), () {
      setState(() => _step = 1);
      _startTimer();
    });
  }

  void _verify() {
    setState(() => _step = 2);
  }

  void _save() {
    if (!_passForm.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    _run(
      () => repo.resetPassword(mobile: Validators.normalizePhone(_mobile.text), code: BnFormat.toAscii(_otp.text), newPassword: _pass.text),
      () async {
        if (_previewOnly) {
          await showConfirmDialog(context,
              title: 'প্রিভিউ শেষ',
              message: 'সার্ভার সংযোগ চালু না হওয়ায় পাসওয়ার্ড বদলানো হয়নি। আসল পরিবর্তন পরে চালু হবে।',
              confirmLabel: 'ঠিক আছে',
              cancelLabel: 'বন্ধ');
        } else {
          showAppSnack(context, 'পাসওয়ার্ড পরিবর্তন হয়েছে। নতুন পাসওয়ার্ড দিয়ে লগইন করুন।');
        }
        if (mounted) context.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('পাসওয়ার্ড পুনরুদ্ধার')),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
            children: [
              StepProgress(total: 3, current: _step + 1),
              SizedBox(height: 8.h),
              Text('ধাপ ${BnFormat.digits('${_step + 1}')}/৩ · ${_titles[_step]}', style: AppText.caption),
              SizedBox(height: 20.h),
              if (_previewOnly && _step > 0) ...[
                const InfoBanner(
                  tone: BannerTone.warning,
                  icon: Icons.visibility_outlined,
                  text: 'শুধু স্ক্রিন দেখানো হচ্ছে — কোনো কোড পাঠানো বা যাচাই করা হয়নি।',
                ),
                SizedBox(height: 16.h),
              ],
              ...switch (_step) {
                0 => _mobileStep(),
                1 => _otpStep(),
                _ => _passwordStep(),
              },
              if (_error != null) ...[
                SizedBox(height: 16.h),
                InfoBanner(text: _error!, tone: BannerTone.error, icon: Icons.cloud_off_outlined),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _mobileStep() => [
        Text('মোবাইল নম্বর দিন', style: AppText.headline.copyWith(fontSize: 22.sp)),
        SizedBox(height: 6.h),
        Text('এই নম্বরে একটি ৬ সংখ্যার কোড পাঠানো হবে।', style: AppText.caption.copyWith(fontSize: 14.sp)),
        SizedBox(height: 20.h),
        Form(
          key: _mobileForm,
          child: AppTextField(
            label: 'মোবাইল নম্বর',
            controller: _mobile,
            hint: '01XXXXXXXXX',
            prefixText: '+৮৮০  ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]')), LengthLimitingTextInputFormatter(11)],
            validator: Validators.auth(Validators.mobile),
          ),
        ),
        SizedBox(height: 24.h),
        AppButton(label: 'কোড পাঠান', loading: _loading, onPressed: _sendCode),
      ];

  List<Widget> _otpStep() => [
        Text('কোডটি দিন', style: AppText.headline.copyWith(fontSize: 22.sp)),
        SizedBox(height: 6.h),
        Text('${BnFormat.phone(_mobile.text)} নম্বরে পাঠানো ৬ সংখ্যার কোড লিখুন।',
            style: AppText.caption.copyWith(fontSize: 14.sp)),
        SizedBox(height: 20.h),
        TextField(
          controller: _otp,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w700, letterSpacing: 14),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
        ),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(
            child: Text(
              _seconds > 0 ? 'আবার কোড পাঠানো যাবে ${BnFormat.digits('$_seconds')} সেকেন্ড পরে' : 'কোড পাননি?',
              style: AppText.caption,
            ),
          ),
          TextButton(
            onPressed: _seconds > 0 || _loading ? null : _sendCode,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('আবার পাঠান'),
          ),
        ]),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48), alignment: Alignment.centerLeft),
          child: const Text('নম্বর পরিবর্তন করুন'),
        ),
        SizedBox(height: 16.h),
        AppButton(
          label: 'যাচাই করুন',
          loading: _loading,
          onPressed: AppConfig.skipAuthValidation || _otp.text.length == 6 ? _verify : null,
        ),
      ];

  List<Widget> _passwordStep() => [
        Text('নতুন পাসওয়ার্ড দিন', style: AppText.headline.copyWith(fontSize: 22.sp)),
        SizedBox(height: 20.h),
        Form(
          key: _passForm,
          child: Column(children: [
            PasswordField(
              label: 'নতুন পাসওয়ার্ড',
              controller: _pass,
              onChanged: (_) => setState(() {}),
              validator: Validators.auth(Validators.password),
            ),
            SizedBox(height: 10.h),
            PasswordStrength(password: _pass.text),
            SizedBox(height: 16.h),
            PasswordField(
              label: 'পাসওয়ার্ড আবার লিখুন',
              controller: _confirm,
              textInputAction: TextInputAction.done,
              validator: Validators.auth((v) => Validators.confirm(v, _pass.text)),
            ),
          ]),
        ),
        SizedBox(height: 24.h),
        AppButton(label: 'পাসওয়ার্ড সংরক্ষণ করুন', loading: _loading, onPressed: _save),
      ];
}

/// Strength meter + rule checklist, shared with registration.
class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final score = Validators.passwordScore(password);
    final (label, color) = switch (score) {
      0 || 1 => ('দুর্বল', AppColors.error),
      2 => ('মাঝারি', AppColors.warning),
      _ => ('শক্তিশালী', AppColors.primary),
    };
    Widget rule(bool ok, String text) => Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Row(children: [
            Icon(ok ? Icons.check_rounded : Icons.circle_outlined,
                size: 18, color: ok ? AppColors.successText : AppColors.textSecondary),
            SizedBox(width: 8.w),
            Expanded(
                child: Text(text,
                    style: AppText.caption.copyWith(color: ok ? AppColors.successText : AppColors.textSecondary))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: password.isNotEmpty && i < score.clamp(1, 4) ? color : AppColors.disabled,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ]),
      if (password.isNotEmpty) ...[
        SizedBox(height: 6.h),
        Text(label, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
      SizedBox(height: 4.h),
      rule(Validators.hasMinLength(password), 'কমপক্ষে ৮টি অক্ষর'),
      rule(Validators.hasDigit(password), 'অন্তত একটি সংখ্যা'),
      rule(Validators.hasSymbol(password), 'অন্তত একটি বিশেষ চিহ্ন (যেমন @ বা #) — ভালো হয়'),
    ]);
  }
}
