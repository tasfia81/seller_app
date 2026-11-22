import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(summaryProvider);
    final holdings = ref.watch(holdingsProvider);
    final active = s.activeCapital;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              padding: EdgeInsets.fromLTRB(20.w, MediaQuery.paddingOf(context).top + 16.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('আপনার টাকা কোথায় খাটছে', style: AppText.title.copyWith(color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text('সক্রিয় মূলধন ${tk(active)} · ${bn(holdings.length)}টি প্রোডাক্টে',
                      style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted, fontSize: 14.sp)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            sliver: SliverToBoxAdapter(child: _Allocation(holdings: holdings, active: active, idle: s.uninvested)),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            sliver: SliverList.separated(
              itemCount: holdings.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => _HoldingCard(holding: holdings[i]),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('এখনো খাটেনি', style: AppText.bodyStrong),
                          Text('পরের কেনাকাটায় যাবে', style: AppText.caption),
                        ],
                      ),
                    ),
                    Text(tk(s.uninvested), style: AppText.amount(16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Allocation extends StatelessWidget {
  const _Allocation({required this.holdings, required this.active, required this.idle});

  final List<ProductHolding> holdings;
  final int active;
  final int idle;

  @override
  Widget build(BuildContext context) {
    final parts = <(String, int, Color)>[
      for (var i = 0; i < holdings.length; i++)
        (holdings[i].shortName, holdings[i].invested, AppColors.allocation[i % (AppColors.allocation.length - 1)]),
      ('খাটেনি', idle, AppColors.allocation.last),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ভাগ করে দেখুন', style: AppText.cardTitle),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(7.r),
            child: SizedBox(
              height: 14.h,
              child: Row(
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(flex: parts[i].$2, child: ColoredBox(color: parts[i].$3)),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 14.w,
            runSpacing: 6.h,
            children: [
              for (final p in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3)),
                    ),
                    SizedBox(width: 6.w),
                    Text('${p.$1} ${pct(active == 0 ? 0 : p.$2 * 100 / active, decimals: 0)}',
                        style: AppText.caption.copyWith(color: const Color(0xFF3C4842))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.holding});

  final ProductHolding holding;

  @override
  Widget build(BuildContext context) {
    final h = holding;
    return AppCard(
      onTap: () => context.push(AppRoutes.productOf(h.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBox(icon: Icons.checkroom_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: AppText.cardTitle),
                    Text('${bn(h.bought)} পিস · ${tk(h.unitCost)} করে', style: AppText.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tk(h.invested), style: AppText.amount(16)),
                  Text('বিনিয়োগ', style: AppText.small),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: h.soldRatio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: const Color(0xFFEEF1EF),
            color: AppColors.primary,
            semanticsLabel: 'বিক্রি হয়েছে',
            semanticsValue: pct(h.soldRatio * 100, decimals: 0),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${bn(h.sold)} বিক্রি (${pct(h.soldRatio * 100, decimals: 0)}) · ${bn(h.remaining)} বাকি',
                  style: AppText.caption.copyWith(color: const Color(0xFF3C4842)),
                ),
              ),
              Text('লাভ ${tk(h.investorShare)}',
                  style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
