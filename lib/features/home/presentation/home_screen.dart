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
        toolbarHeight: 72.h.clamp(64.0, 84.0).toDouble(),
        titleSpacing: 16.w,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${BnFormat.greeting(now)},', style: AppText.caption),
          Text(seller?.name ?? ' ', style: AppText.pageTitle),
          Text(BnFormat.weekdayDate(now), style: AppText.caption),
        ]),
        actions: [
          IconButton(
            tooltip: unread > 0 ? 'নোটিফিকেশন, ${BnFormat.digits('$unread')}টি নতুন' : 'নোটিফিকেশন',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 9,
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_none_rounded),
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
                  amount: BnFormat.money(s.todaySales),
                  caption: s.salesCount == 0
                      ? 'আজ এখনো কোনো বিক্রি হয়নি'
                      : '${BnFormat.digits('${s.salesCount}')}টি বিক্রি'
                          '${s.lastSaleAt == null ? '' : ' · সর্বশেষ ${BnFormat.time(s.lastSaleAt!)}'}',
                ),
                SizedBox(height: 12.h),
                Row(children: [
                  Expanded(
                      child: _tap(context, AppRoutes.sales,
                          MetricTile(label: 'বিক্রিত পণ্য', value: '${BnFormat.digits('${s.itemsSold}')}টি'))),
                  SizedBox(width: 10.w),
                  Expanded(
                      child: _tap(
                          context,
                          AppRoutes.earnings,
                          MetricTile(
                              label: 'আমার আজকের আয়',
                              value: BnFormat.money(s.todayEarnings),
                              valueColor: AppColors.successText))),
                ]),
                SizedBox(height: 10.h),
                Row(children: [
                  Expanded(
                      child: _tap(context, AppRoutes.inventory,
                          MetricTile(label: 'হাতে থাকা স্টক', value: '${BnFormat.qty(s.availableStock)}টি'))),
                  SizedBox(width: 10.w),
                  Expanded(
                      child: _tap(
                          context,
                          AppRoutes.cashHandover,
                          MetricTile(
                              label: 'জমা দিতে হবে',
                              value: BnFormat.money(s.cashToSubmit),
                              warning: s.cashToSubmit > 0))),
                ]),
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

  Widget _tap(BuildContext context, String route, Widget child) => InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => route == AppRoutes.sales ? context.go(route) : context.push(route),
        child: child,
      );
}
