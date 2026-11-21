import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

/// Flat white card with a hairline border (no heavy shadows).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color = Colors.white,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14.r);
    final content = Padding(padding: padding ?? EdgeInsets.all(14.r), child: child);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.divider = true, this.valueColor, this.valueWidget});

  final String label;
  final String value;
  final bool divider;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: divider
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary))),
          SizedBox(width: 12.w),
          Flexible(
            child: valueWidget ??
                Text(value,
                    textAlign: TextAlign.right,
                    style: AppText.bodyStrong.copyWith(color: valueColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.section)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              foregroundColor: AppColors.primaryDark,
              textStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

enum BannerTone { info, warning, error }

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon, this.tone = BannerTone.info, this.child});

  final String text;
  final IconData? icon;
  final BannerTone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, iconColor) = switch (tone) {
      BannerTone.info => (AppColors.infoSurface, AppColors.infoSurface, const Color(0xFF24412F), AppColors.primary),
      BannerTone.warning => (AppColors.warningSurface, AppColors.warningBorder, const Color(0xFF5C3D08), const Color(0xFFB57A12)),
      BannerTone.error => (AppColors.errorSoft, AppColors.errorSoft, AppColors.errorText, AppColors.errorText),
    };
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, color: iconColor, size: 22),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppText.caption.copyWith(color: fg)),
                if (child != null) child!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.valueColor, this.warning = false, this.highlight = false});

  final String label;
  final String value;
  final Color? valueColor;
  final bool warning;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningSurface : Colors.white,
        border: Border.all(
            color: warning
                ? AppColors.warningBorder
                : highlight
                    ? const Color(0xFFB6DCC5)
                    : AppColors.border),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: AppText.amount(19, color: valueColor ?? (warning ? AppColors.warningText : AppColors.textPrimary))),
          ),
        ],
      ),
    );
  }
}

/// Dark green card for the single most important amount on a screen.
class HeroAmountCard extends StatelessWidget {
  const HeroAmountCard({super.key, required this.label, required this.amount, this.caption});

  final String label;
  final String amount;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: AppColors.onDarkMuted)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: AppText.amount(30, color: Colors.white)),
          ),
          if (caption != null) Text(caption!, style: AppText.caption.copyWith(color: AppColors.onDarkMuted)),
        ],
      ),
    );
  }
}

/// Fixed white bar at the bottom of a form screen. Moves above the keyboard.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h), child: child),
      ),
    );
  }
}
