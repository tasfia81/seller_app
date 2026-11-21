import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/models/sale.dart';

/// Shown only with a sale the server confirmed (passed via route `extra`).
class SaleSuccessScreen extends StatelessWidget {
  const SaleSuccessScreen({super.key, required this.sale});

  final Sale? sale;

  @override
  Widget build(BuildContext context) {
    final s = sale;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'বিক্রির তথ্য পাওয়া যায়নি',
          message: 'বিক্রির ইতিহাসে আপনার বিক্রিটি দেখুন।',
          actionLabel: 'বিক্রির ইতিহাস',
          onAction: () => context.go(AppRoutes.sales),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 16.h),
              children: [
                Center(
                  child: Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 42, color: AppColors.primary),
                  ),
                ),
                SizedBox(height: 14.h),
                Text('বিক্রি নিশ্চিত হয়েছে',
                    textAlign: TextAlign.center, style: AppText.headline.copyWith(fontSize: 22.sp)),
                SizedBox(height: 4.h),
                Text(BnFormat.money(s.total),
                    textAlign: TextAlign.center, style: AppText.amount(34, color: AppColors.successText)),
                SizedBox(height: 16.h),
                AppCard(
                  color: AppColors.background,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                  child: Column(children: [
                    KeyValueRow('বিক্রি নম্বর', '#${s.id}'),
                    KeyValueRow('পণ্য', '${s.productName}${s.variant == null ? '' : ' (${s.variant})'}'),
                    KeyValueRow('পরিমাণ',
                        '${BnFormat.qty(s.quantity)} ${s.unit.label} × ${BnFormat.money(s.unitPrice)}'),
                    KeyValueRow('পেমেন্ট', s.payment.label),
                    KeyValueRow('সময়', BnFormat.dateTime(s.time), divider: false),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Column(children: [
              AppButton(
                label: 'নতুন বিক্রি',
                icon: Icons.add_rounded,
                onPressed: () => context.pushReplacement(AppRoutes.newSale()),
              ),
              SizedBox(height: 8.h),
              AppButton(
                label: 'রসিদ দেখুন',
                variant: AppButtonVariant.outline,
                onPressed: () => context.pushReplacement(AppRoutes.saleDetail(s.id), extra: s),
              ),
              AppButton(
                label: 'হোমে ফিরে যান',
                variant: AppButtonVariant.text,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
