import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';

class MenuEntry {
  const MenuEntry(this.icon, this.label, {required this.onTap, this.trailing, this.danger = false});
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
}

class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.title, required this.items});

  final String title;
  final List<MenuEntry> items;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
        child: Text(title, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      ),
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 14, endIndent: 14),
            _row(items[i]),
          ],
        ]),
      ),
    ]);
  }

  Widget _row(MenuEntry m) {
    final color = m.danger ? AppColors.errorText : AppColors.textPrimary;
    return InkWell(
      onTap: m.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(children: [
            if (m.icon != null) ...[
              Icon(m.icon, color: m.danger ? AppColors.errorText : AppColors.primary, size: 22),
              SizedBox(width: 12.w),
            ],
            Expanded(child: Text(m.label, style: AppText.body.copyWith(fontSize: 15.sp, color: color))),
            if (m.trailing != null) m.trailing!,
            if (m.trailing == null && !m.danger && m.onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A968F)),
          ]),
        ),
      ),
    );
  }
}
