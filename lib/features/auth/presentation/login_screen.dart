import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../data/seller_session.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).login(
            mobile: Validators.normalizePhone(_mobile.text),
            password: _password.text,
          );
      if (mounted) {
        final active = AppConfig.previewAuth || ref.read(sellerSessionProvider).active;
        context.go(active ? AppRoutes.home : AppRoutes.applicationStatus);
      }
    } catch (e) {
      if (mounted) setState(() => _error = failureMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(shape: const Border()),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
              children: [
                Text('লগইন করুন', style: AppText.headline),
                SizedBox(height: 6.h),
                Text('আপনার মোবাইল নম্বর ও পাসওয়ার্ড দিন', style: AppText.body.copyWith(color: AppColors.textSecondary)),
                SizedBox(height: 24.h),
                AppTextField(
                  label: 'মোবাইল নম্বর',
                  controller: _mobile,
                  hint: '01XXXXXXXXX',
                  prefixText: '+৮৮০  ',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]')), LengthLimitingTextInputFormatter(11)],
                  validator: Validators.auth(Validators.mobile),
                ),
                SizedBox(height: 16.h),
                PasswordField(
                  label: 'পাসওয়ার্ড বা পিন',
                  hint: 'অ্যাকাউন্টের পাসওয়ার্ড লিখুন',
                  controller: _password,
                  textInputAction: TextInputAction.done,
                  validator: Validators.auth((v) => Validators.required(v, 'পাসওয়ার্ড দিন।')),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    child: const Text('পাসওয়ার্ড ভুলে গেছেন?', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_error != null) ...[
                  InfoBanner(text: _error!, tone: BannerTone.error, icon: Icons.error_outline_rounded),
                  SizedBox(height: 12.h),
                ],
                AppButton(label: 'লগইন করুন', loading: _loading, onPressed: _submit),
                SizedBox(height: 28.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('অ্যাকাউন্ট নেই?', style: AppText.body.copyWith(color: AppColors.textBody)),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      child: const Text('কাজের জন্য আবেদন করুন', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
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
