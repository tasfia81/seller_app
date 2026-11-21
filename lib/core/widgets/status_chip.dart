import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/enums.dart';

enum ChipTone { success, warning, error, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = ChipTone.neutral});

  final String label;
  final ChipTone tone;

  factory StatusChip.sale(SaleStatus s) => StatusChip(s.label,
      tone: switch (s) {
        SaleStatus.confirmed => ChipTone.success,
        SaleStatus.pendingSync => ChipTone.warning,
        SaleStatus.correctionRequested => ChipTone.neutral,
        SaleStatus.cancelled => ChipTone.error,
      });

  factory StatusChip.request(RequestStatus s) => StatusChip(s.label,
      tone: switch (s) {
        RequestStatus.pending => ChipTone.warning,
        RequestStatus.approved => ChipTone.success,
        RequestStatus.rejected => ChipTone.error,
        RequestStatus.completed => ChipTone.neutral,
      });

  factory StatusChip.application(ApplicationStatus s) => StatusChip(s.label,
      tone: switch (s) {
        ApplicationStatus.approved => ChipTone.success,
        ApplicationStatus.rejected => ChipTone.error,
        ApplicationStatus.underReview || ApplicationStatus.moreInfoRequired => ChipTone.warning,
        _ => ChipTone.neutral,
      });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.success => (AppColors.successSoft, AppColors.successText),
      ChipTone.warning => (AppColors.warningSoft, AppColors.warningText),
      ChipTone.error => (AppColors.errorSoft, AppColors.errorText),
      ChipTone.neutral => (AppColors.neutralSoft, AppColors.neutralText),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          maxLines: 1,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: fg, height: 1.3)),
    );
  }
}
