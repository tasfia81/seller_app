import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../errors/failure.dart';
import 'app_button.dart';

/// Lightweight skeleton list (no shimmer animation, cheap on low-end phones).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          height: 12.h,
          width: w,
          decoration: BoxDecoration(color: const Color(0xFFE7ECE9), borderRadius: BorderRadius.circular(6)),
        );
    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(color: const Color(0xFFE7ECE9), borderRadius: BorderRadius.circular(12.r)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bar(160.w),
              SizedBox(height: 8.h),
              bar(90.w),
            ]),
          ),
        ]),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = ChipToneLike.neutral,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ChipToneLike tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tone == ChipToneLike.error
        ? (AppColors.errorSoft, AppColors.errorText)
        : (AppColors.mint, AppColors.primary);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 30),
            ),
            SizedBox(height: 14.h),
            Text(title, style: AppText.section.copyWith(fontSize: 16.sp), textAlign: TextAlign.center),
            if (message != null) ...[
              SizedBox(height: 6.h),
              Text(message!, style: AppText.caption, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 18.h),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.outline,
                expanded: false,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum ChipToneLike { neutral, error }

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (error) {
      NetworkFailure() => Icons.wifi_off_rounded,
      PermissionFailure() => Icons.lock_outline_rounded,
      NotConnectedFailure() => Icons.cloud_off_outlined,
      _ => Icons.error_outline_rounded,
    };
    final title = switch (error) {
      NetworkFailure() => 'ইন্টারনেট সংযোগ নেই',
      PermissionFailure() => 'অনুমতি নেই',
      NotConnectedFailure() => 'এখনো চালু হয়নি',
      _ => 'তথ্য আনা যায়নি',
    };
    return EmptyView(
      icon: icon,
      title: title,
      message: failureMessage(error),
      tone: ChipToneLike.error,
      actionLabel: onRetry == null ? null : 'আবার চেষ্টা করুন',
      onAction: onRetry,
    );
  }
}

/// Renders loading / error / data for an [AsyncValue] with retry.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry, this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}
