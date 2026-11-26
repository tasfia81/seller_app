import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/api/api_client.dart';
import 'password_reset_dialog.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ui.dart';
import '../../data/auth/auth_controller.dart';
import '../intro/brand_mark.dart';

/// Mobile + password. Where to go next (status screen or home) is decided by
/// the router from the signed-in user.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _mobileError;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final mobile = Validators.mobile(_mobile.text);
    setState(() {
      _mobileError = mobile == null ? 'সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন' : null;
      _error = _password.text.isEmpty ? 'পাসওয়ার্ড দিন' : null;
    });
    if (mobile == null || _password.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).login(mobile, _password.text);
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _forgot() {
    showDialog<void>(context: context, builder: (_) => PasswordResetDialog(initialMobile: _mobile.text));
  }

  @override
  Widget build(BuildContext context) {
    final expired = switch (ref.watch(authControllerProvider)) {
      SignedOut(sessionExpired: true) => true,
      _ => false,
    };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: AutofillGroup(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'পেছনে যান',
                    size: 44,
                    iconColor: AppColors.primary,
                    onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                  ),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(22.r)),
                    child: const BrandMark(size: 52),
                  ),
                ),
                SizedBox(height: 16.h),
                Text('আবার স্বাগতম', textAlign: TextAlign.center, style: AppText.headline),
                SizedBox(height: 4.h),
                Text('নিবন্ধিত মোবাইল নম্বর ও পাসওয়ার্ড দিন', textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 14.sp)),
                SizedBox(height: 24.h),
                if (expired) ...[
                  const InfoBox(tone: InfoTone.warn, icon: Icons.lock_clock_outlined, text: 'নিরাপত্তার জন্য সেশন শেষ হয়েছে। আবার লগইন করুন।'),
                  SizedBox(height: 14.h),
                ],
                LabeledField(
                  label: 'মোবাইল নম্বর',
                  hint: '01XXXXXXXXX',
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  autofillHints: const [AutofillHints.telephoneNumber, AutofillHints.username],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
                  errorText: _mobileError,
                ),
                SizedBox(height: 14.h),
                LabeledField(
                  label: 'পাসওয়ার্ড',
                  controller: _password,
                  obscure: !_show,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  suffix: IconButton(
                    tooltip: _show ? 'পাসওয়ার্ড লুকান' : 'পাসওয়ার্ড দেখুন',
                    icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _forgot, child: const Text('পাসওয়ার্ড ভুলে গেছেন?')),
                ),
                if (_error != null) ...[
                  InfoBox(tone: InfoTone.bad, icon: Icons.error_outline_rounded, text: _error!),
                  SizedBox(height: 12.h),
                ],
                SizedBox(height: 8.h),
                FilledButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'লগইন হচ্ছে…' : 'লগইন')),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('নতুন বিনিয়োগকারী?', style: AppText.caption),
                    TextButton(onPressed: () => context.go(AppRoutes.signupMobile), child: const Text('যুক্ত হোন')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
