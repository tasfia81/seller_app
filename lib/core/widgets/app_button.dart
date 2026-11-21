import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_size.dart';
import '../../app/theme/app_text.dart';

enum AppButtonVariant { primary, outline, text, danger }

/// The one button used across the app. While [loading] it is disabled, which
/// prevents accidental double submission.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? AppSize.touch : AppSize.button;
    final fg = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.danger => AppColors.errorText,
      _ => AppColors.primaryDark,
    };
    final textStyle = AppText.button.copyWith(fontSize: compact ? 14.sp : 16.sp);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: variant == AppButtonVariant.primary ? Colors.white : AppColors.primary,
            ),
          ),
          SizedBox(width: 10.w),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          SizedBox(width: 8.w),
        ],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (trailingIcon != null && !loading) ...[
          SizedBox(width: 8.w),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r));
    final minSize = Size(expanded ? double.infinity : 0, height);
    final padding = EdgeInsets.symmetric(horizontal: compact ? 14.w : 16.w);
    final action = loading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: fg,
            disabledBackgroundColor: loading ? AppColors.primaryDark : AppColors.disabled,
            disabledForegroundColor: loading ? Colors.white : AppColors.disabledText,
            minimumSize: minSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.outline:
      case AppButtonVariant.danger:
        final color = variant == AppButtonVariant.danger ? AppColors.error : AppColors.primary;
        return OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            backgroundColor: Colors.white,
            disabledForegroundColor: AppColors.disabledText,
            side: BorderSide(color: action == null ? AppColors.border : color, width: 1.5),
            minimumSize: minSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: action,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            minimumSize: Size(expanded ? double.infinity : 0, AppSize.touch),
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          ),
          child: child,
        );
    }
  }
}
