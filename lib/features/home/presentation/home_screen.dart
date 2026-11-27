import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../data/dashboard_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(homeDataProvider);
    final now = DateTime.now();
    final seller = value.valueOrNull?.seller;
    final unread = value.valueOrNull?.summary.unreadNotifications ?? 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64.h.clamp(60.0, 74.0).toDouble(),
        titleSpacing: 16.w,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${BnFormat.greeting(now)},', style: AppText.caption),
            Text(seller?.name ?? ' ', style: AppText.pageTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: unread > 0 ? 'নোটিফিকেশন, ${BnFormat.digits('$unread')}টি নতুন' : 'নোটিফিকেশন',
            onPressed: () => context.push(AppRoutes.notifications),
            padding: EdgeInsets.zero,
            icon: Container(
              width: 40.r,
              height: 40.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Badge(
                isLabelVisible: unread > 0,
                smallSize: 8,
                backgroundColor: AppColors.error,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 22.r,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(homeDataProvider),
        data: (data) {
          final s = data.summary;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(homeDataProvider.future),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                HeroAmountCard(
                  label: 'আজকের মোট বিক্রি',
                  dateLabel: BnFormat.weekdayDate(now),
                  amount: BnFormat.money(s.todaySales),
                  caption: s.salesCount == 0
                      ? 'আজ এখনো কোনো বিক্রি হয়নি'
                      : '${BnFormat.digits('${s.salesCount}')}টি বিক্রি'
                          '${s.lastSaleAt == null ? '' : ' · সর্বশেষ ${BnFormat.time(s.lastSaleAt!)}'}',
                ),
                SizedBox(height: 12.h),
                _MetricRow(
                  first: _HomeMetric(
                    label: 'বিক্রিত পণ্য',
                    amount: BnFormat.qty(s.itemsSold),
                    unit: 'টি',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.go(AppRoutes.sales),
                  ),
                  second: _HomeMetric(
                    label: 'আমার আজকের আয়',
                    amount: BnFormat.money(s.todayEarnings),
                    icon: Icons.trending_up_rounded,
                    surface: AppColors.infoSurface,
                    accent: AppColors.successText,
                    onTap: () => context.push(AppRoutes.earnings),
                  ),
                ),
                SizedBox(height: 10.h),
                _MetricRow(
                  first: _HomeMetric(
                    label: 'হাতে থাকা স্টক',
                    amount: BnFormat.qty(s.availableStock),
                    unit: 'টি',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => context.push(AppRoutes.inventory),
                  ),
                  second: _HomeMetric(
                    label: 'জমা দিতে হবে',
                    amount: BnFormat.money(s.cashToSubmit),
                    icon: Icons.account_balance_wallet_outlined,
                    surface: s.cashToSubmit > 0 ? AppColors.warningSurface : AppColors.surface,
                    border: s.cashToSubmit > 0 ? AppColors.warningBorder : AppColors.border,
                    accent: s.cashToSubmit > 0 ? AppColors.warningText : AppColors.successText,
                    iconSurface: s.cashToSubmit > 0 ? AppColors.warningSoft : AppColors.mint,
                    onTap: () => context.push(AppRoutes.cashHandover),
                  ),
                ),
                SizedBox(height: 14.h),
                AppButton(
                  label: 'নতুন বিক্রি যোগ করুন',
                  icon: Icons.add_rounded,
                  onPressed: () => context.push(AppRoutes.newSale()),
                ),
                if (s.lowStockNames.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  AppCard(
                    onTap: () => context.go(AppRoutes.products),
                    color: AppColors.warningSurface,
                    borderColor: AppColors.warningBorder,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFB57A12)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text('কম স্টক: ${s.lowStockNames.join(', ')}',
                            style: AppText.caption.copyWith(color: const Color(0xFF5C3D08))),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFB57A12)),
                    ]),
                  ),
                ],
                SizedBox(height: 16.h),
                SectionHeader('সাম্প্রতিক বিক্রি',
                    actionLabel: 'সব দেখুন', onAction: () => context.go(AppRoutes.sales)),
                SizedBox(height: 6.h),
                if (data.recent.isEmpty)
                  AppCard(
                    child: Text('প্রথম বিক্রি যোগ করলে এখানে দেখা যাবে।',
                        style: AppText.caption, textAlign: TextAlign.center),
                  )
                else
                  for (final sale in data.recent)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: SaleCard(sale: sale, onTap: () => context.push(AppRoutes.saleDetail(sale.id))),
                    ),
                SizedBox(height: 8.h),
                AppButton(
                  label: 'দিনের হিসাব জমা দিন',
                  icon: Icons.event_available_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.push(AppRoutes.dayClosing),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: first),
            SizedBox(width: 10.w),
            Expanded(child: second),
          ],
        ),
      );
}

class _HomeMetric extends StatelessWidget {
  const _HomeMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.onTap,
    this.unit,
    this.surface = AppColors.surface,
    this.border = AppColors.border,
    this.accent = AppColors.textPrimary,
    this.iconSurface = AppColors.mint,
  });

  final String label;
  final String amount;
  final IconData icon;
  final VoidCallback onTap;
  final String? unit;
  final Color surface;
  final Color border;
  final Color accent;
  final Color iconSurface;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: surface,
      borderColor: border,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 12.w, 13.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: amount,
                      children: [
                        if (unit != null)
                          TextSpan(
                            text: unit,
                            style: AppText.bodyStrong.copyWith(color: accent),
                          ),
                      ],
                    ),
                    style: AppText.amount(29, color: accent),
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  color: iconSurface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 16.r, color: accent),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(label, style: AppText.caption.copyWith(color: AppColors.textBody)),
        ],
      ),
    );
  }
}
