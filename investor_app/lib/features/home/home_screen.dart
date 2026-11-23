import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/bn_format.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/sparkline.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(summaryProvider);
    final holdings = ref.watch(holdingsProvider);
    final sellers = ref.watch(sellersProvider);

    final fastest = holdings.reduce((a, b) => a.soldRatio >= b.soldRatio ? a : b);
    final topSeller = sellers.reduce((a, b) => a.soldToday >= b.soldToday ? a : b);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 64.h),
                      child: _Header(summary: s),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _QuickActions(summary: s, inHand: sellers.fold(0, (sum, x) => sum + x.inHand)),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                    child: _ProfitTiles(summary: s),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 8.w, 0),
                    child: SectionHeader('ব্যবসার খবর',
                        action: 'রিপোর্ট', onAction: () => context.go(AppRoutes.report)),
                  ),
                  _InsightRow(
                    icon: Icons.checkroom_outlined,
                    label: 'সবচেয়ে দ্রুত বিক্রি',
                    value: '${fastest.shortName} · ${pct(fastest.soldRatio * 100, decimals: 0)}',
                    trend: const [24, 20, 22, 14, 16, 9, 11, 4],
                    onTap: () => context.push(AppRoutes.productOf(fastest.id)),
                  ),
                  _InsightRow(
                    icon: Icons.person_outline_rounded,
                    label: 'আজকের সেরা সেলার',
                    value: '${topSeller.name} · ${bn(topSeller.soldToday)} পিস',
                    trend: const [22, 25, 18, 20, 12, 15, 8, 10],
                    onTap: () => context.push(AppRoutes.sellers),
                  ),
                  _InsightRow(
                    icon: Icons.show_chart_rounded,
                    label: 'আজ বিক্রি (আপনার স্টক)',
                    value: '${bn(s.todayPieces)} পিস · ${tk(s.todayAmount)}',
                    trend: const [26, 24, 25, 19, 21, 14, 9, 6],
                    onTap: () => context.push(AppRoutes.sellers),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return GradientHeader(
      rounded: true,
      padding: EdgeInsets.fromLTRB(20.w, MediaQuery.paddingOf(context).top + 10.h, 20.w, 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: Icons.menu_rounded,
                label: 'মেনু খুলুন',
                onTap: () => ref.read(sideMenuOpenProvider.notifier).state = true,
              ),
              const Spacer(),
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'নোটিফিকেশন, ${summary.unreadUpdates}টি নতুন',
                badge: summary.unreadUpdates > 0,
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(BnFormat.weekdayDate(now), style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted, fontSize: 14.sp)),
          Text('${BnFormat.greeting(now)},', style: AppText.display.copyWith(color: Colors.white)),
          Text(summary.investorName, style: AppText.section.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('এখন খাটছে', style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(tk(summary.activeCapital), style: AppText.amount(32, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(color: AppColors.onPrimaryGlass, borderRadius: BorderRadius.circular(14.r)),
                child: Text('↗ ${pct(summary.returnPercent)} রিটার্ন',
                    style: AppText.small.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.summary, required this.inHand});

  final PortfolioSummary summary;
  final int inHand;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: const [BoxShadow(color: Color(0x2608452F), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          _QuickRow(
            icon: Icons.account_balance_wallet_outlined,
            text: 'পাওনা লাভ ${tk(summary.profitThisMonth)}',
            pill: Pill(summary.nextPayoutLabel, background: AppColors.amberSoft, color: AppColors.amber),
            onTap: () => context.push(AppRoutes.withdraw),
          ),
          SizedBox(height: 8.h),
          _QuickRow(
            icon: Icons.inventory_2_outlined,
            text: 'সেলারের হাতে স্টক',
            pill: Pill(bn(inHand)),
            onTap: () => context.push(AppRoutes.sellers),
          ),
          SizedBox(height: 8.h),
          _QuickRow(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'নতুন আপডেট',
            pill: Pill(bn(summary.unreadUpdates), background: AppColors.dangerSoft, color: AppColors.danger),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          SizedBox(height: 8.h),
          _QuickRow(
            icon: Icons.support_agent_rounded,
            text: 'কোনো প্রশ্ন? সাপোর্টে লিখুন',
            pill: const Pill('চ্যাট'),
            onTap: () => context.push(AppRoutes.support),
          ),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.icon, required this.text, required this.pill, required this.onTap});

  final IconData icon;
  final String text;
  final Widget pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              IconBox(icon: icon, background: Colors.white, size: 40),
              SizedBox(width: 12.w),
              Expanded(child: Text(text, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
              pill,
              SizedBox(width: 8.w),
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.north_east_rounded, size: 16.r, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TileStyle { light, green, dark }

class _ProfitTiles extends StatelessWidget {
  const _ProfitTiles({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: 10.w, height: 10.h);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('আপনার লাভ', style: AppText.section),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                style: _TileStyle.light,
                icon: Icons.trending_up_rounded,
                label: 'মোট লাভ',
                value: tk(summary.totalProfit),
                sub: '${bn(summary.monthsActive)} মাসে',
              ),
            ),
            gap,
            Expanded(
              child: _StatTile(
                style: _TileStyle.green,
                icon: Icons.calendar_month_outlined,
                label: 'এই মাসে',
                value: tk(summary.profitThisMonth),
                sub: 'চলমান',
              ),
            ),
          ],
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: _StatTile(
                style: _TileStyle.dark,
                icon: Icons.check_rounded,
                label: 'পেয়েছেন',
                value: tk(summary.profitPaid),
                sub: '${bn(summary.profitPaidTimes)} বারে',
                onTap: () => context.go(AppRoutes.ledger),
              ),
            ),
            gap,
            Expanded(
              child: _StatTile(
                style: _TileStyle.light,
                icon: Icons.attach_money_rounded,
                label: 'মোট দিয়েছেন',
                value: tk(summary.totalInvested),
                sub: 'ফেরত ${tk(summary.withdrawn)}',
                onTap: () => context.go(AppRoutes.ledger),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.style,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.onTap,
  });

  final _TileStyle style;
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, muted, iconBg) = switch (style) {
      _TileStyle.light => (Colors.white, AppColors.textPrimary, AppColors.textSecondary, AppColors.softGreen),
      _TileStyle.green => (AppColors.primary, Colors.white, AppColors.onPrimaryMuted, AppColors.onPrimaryGlass),
      _TileStyle.dark => (AppColors.dark, Colors.white, AppColors.onDarkMuted, const Color(0x1FFFFFFF)),
    };
    return AppCard(
      color: bg,
      radius: 18,
      onTap: onTap,
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          IconBox(
            icon: icon,
            circle: true,
            size: 38,
            background: iconBg,
            color: style == _TileStyle.light ? AppColors.primary : Colors.white,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.small.copyWith(color: muted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AppText.amount(17, color: fg)),
                ),
                Text(sub, style: AppText.small.copyWith(color: muted, fontSize: 11.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<double> trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  Text(value, style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Sparkline(values: trend),
          ],
        ),
      ),
    );
  }
}
