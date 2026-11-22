import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../utils/bn_format.dart';
import 'ui.dart';

/// Layout shared by the 5 sign-up steps: back button, "ধাপ x/৫",
/// progress bar, scrollable form and a pinned bottom button.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.children,
    required this.buttonLabel,
    required this.onNext,
    this.subtitle,
    this.footer,
    this.total = 5,
  });

  final int step;
  final int total;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback? onNext;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 20.w, 0),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'পেছনে যান',
                      size: 44,
                      iconColor: AppColors.primary,
                      onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                    ),
                    const Spacer(),
                    Text('ধাপ ${BnFormat.digits('$step')}/${BnFormat.digits('$total')}', style: AppText.caption),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                child: Semantics(
                  label: 'ধাপ $step, মোট $total',
                  child: Row(
                    children: [
                      for (var i = 1; i <= total; i++) ...[
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= step ? AppColors.primary : const Color(0xFFDDE3E0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (i < total) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Text(title, style: AppText.headline),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(subtitle!, style: AppText.caption.copyWith(fontSize: 14.sp)),
                    ],
                    SizedBox(height: 18.h),
                    ...children,
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h + MediaQuery.paddingOf(context).bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(onPressed: onNext, child: Text(buttonLabel)),
                      if (footer != null) ...[SizedBox(height: 8.h), footer!],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
