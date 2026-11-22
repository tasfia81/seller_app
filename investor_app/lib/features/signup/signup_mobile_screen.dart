import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/step_scaffold.dart';
import '../../core/widgets/ui.dart';

class SignupMobileScreen extends StatefulWidget {
  const SignupMobileScreen({super.key});

  @override
  State<SignupMobileScreen> createState() => _SignupMobileScreenState();
}

class _SignupMobileScreenState extends State<SignupMobileScreen> {
  final _mobile = TextEditingController();
  final _otpKey = GlobalKey<_OtpBoxesState>();
  bool _sent = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _mobile.dispose();
    super.dispose();
  }

  String get _masked {
    final p = BnFormat.toAscii(_mobile.text).replaceAll(RegExp(r'\D'), '');
    if (p.length < 6) return BnFormat.digits(p);
    return BnFormat.digits('${p.substring(0, 3)}•••••${p.substring(p.length - 3)}');
  }

  void _send() {
    final p = BnFormat.toAscii(_mobile.text).replaceAll(RegExp(r'\D'), '');
    if (!AppConfig.skipValidation && !RegExp(r'^01[3-9]\d{8}$').hasMatch(p)) {
      showDemoNotice(context, 'সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।');
      return;
    }
    FocusScope.of(context).unfocus();
    // UI phase: no SMS gateway yet, so no real code is sent.
    showDemoNotice(context, 'ডেমো মোড: আসল SMS যায়নি — যেকোনো ৬ সংখ্যা দিয়ে এগোতে পারবেন।');
    setState(() {
      _sent = true;
      _seconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _seconds <= 1) {
        t.cancel();
        if (mounted) setState(() => _seconds = 0);
        return;
      }
      setState(() => _seconds--);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _otpKey.currentState?.focusFirst());
  }

  void _next() {
    final code = _otpKey.currentState?.code ?? '';
    if (!AppConfig.skipValidation && code.length != 6) {
      showDemoNotice(context, '৬ সংখ্যার কোডটি দিন।');
      return;
    }
    context.push(AppRoutes.signupInfo);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: 1,
      title: 'আপনার মোবাইল নম্বর',
      subtitle: 'এই নম্বরেই লগইন করবেন আর লাভ জমা হলে SMS পাবেন।',
      buttonLabel: _sent ? 'যাচাই করে এগিয়ে যান' : 'কোড পাঠান',
      onNext: _sent ? _next : _send,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('আগে থেকেই অ্যাকাউন্ট আছে?', style: AppText.caption),
          TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('লগইন')),
        ],
      ),
      children: [
        Text('মোবাইল নম্বর', style: AppText.label),
        SizedBox(height: 6.h),
        TextField(
          controller: _mobile,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
          style: AppText.body.copyWith(fontSize: 17.sp, height: 1.3),
          decoration: InputDecoration(
            counterText: '',
            hintText: '01XXXXXXXXX',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14.w, right: 10.w),
              child: Text('+৮৮', style: AppText.body.copyWith(color: AppColors.textSecondary)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          onSubmitted: (_) => _send(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_sent
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_masked নম্বরে ৬ সংখ্যার কোড পাঠানো হয়েছে', style: AppText.bodySmall),
                        SizedBox(height: 12.h),
                        _OtpBoxes(key: _otpKey),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _seconds > 0
                                    ? 'আবার পাঠানো যাবে ${BnFormat.digits('0:${_seconds.toString().padLeft(2, '0')}')} পরে'
                                    : 'কোড পাননি?',
                                style: AppText.caption,
                              ),
                            ),
                            TextButton(
                              onPressed: _seconds > 0 ? null : _send,
                              child: const Text('আবার পাঠান'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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

/// Six single-digit boxes; focus jumps forward/back automatically.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({super.key});

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  static const _n = 6;
  final _controllers = List.generate(_n, (_) => TextEditingController());
  final _nodes = List.generate(_n, (_) => FocusNode());

  String get code => BnFormat.toAscii(_controllers.map((c) => c.text).join());

  void focusFirst() => _nodes.first.requestFocus();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _changed(int i, String v) {
    if (v.length > 1) {
      // Pasted / autofilled code: spread it over the boxes.
      final digits = v.split('');
      for (var k = 0; k < _n; k++) {
        _controllers[k].text = k < digits.length ? digits[k] : '';
      }
      _nodes[(digits.length).clamp(0, _n - 1)].requestFocus();
      return;
    }
    if (v.isNotEmpty && i < _n - 1) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Row(
        children: [
          for (var i = 0; i < _n; i++) ...[
            if (i > 0) SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
                style: AppText.amount(22),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  hintText: '',
                  semanticCounterText: 'কোডের ${i + 1} নম্বর সংখ্যা',
                ),
                onChanged: (v) => _changed(i, v),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
