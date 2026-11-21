import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/finance.dart';
import '../data/earnings_repository.dart';

enum _Tab { earnings, payouts }

class MyEarningsScreen extends ConsumerStatefulWidget {
  const MyEarningsScreen({super.key});

  @override
  ConsumerState<MyEarningsScreen> createState() => _MyEarningsScreenState();
}

class _MyEarningsScreenState extends ConsumerState<MyEarningsScreen> {
  _Tab _tab = _Tab.earnings;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(earningsSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('আমার আয়')),
      body: AsyncValueView<EarningsSummary>(
        value: summary,
        onRetry: () => ref.invalidate(earningsSummaryProvider),
        data: (e) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(earningsHistoryProvider);
            ref.invalidate(payoutsProvider);
            await ref.refresh(earningsSummaryProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              InfoBanner(icon: Icons.trending_up_rounded, text: e.ruleText),
              SizedBox(height: 12.h),
              HeroAmountCard(
                label: 'আজকের আয়',
                amount: BnFormat.money(e.today),
                caption: 'এই মাসে মোট ${BnFormat.money(e.thisMonth)}',
              ),
              SizedBox(height: 12.h),
              Row(children: [
                Expanded(child: MetricTile(label: 'অপেক্ষমাণ', value: BnFormat.money(e.pending), valueColor: AppColors.warningText)),
                SizedBox(width: 10.w),
                Expanded(child: MetricTile(label: 'অনুমোদিত', value: BnFormat.money(e.approved))),
              ]),
              SizedBox(height: 10.h),
              Row(children: [
                Expanded(child: MetricTile(label: 'মোট পেয়েছেন', value: BnFormat.money(e.totalPaid))),
                SizedBox(width: 10.w),
                Expanded(
                    child: MetricTile(label: 'বাকি পাওনা', value: BnFormat.money(e.outstanding), valueColor: AppColors.successText)),
              ]),
              SizedBox(height: 16.h),
              ChoicePills<_Tab>(
                options: _Tab.values,
                selected: _tab,
                equalWidth: true,
                style: PillStyle.filter,
                labelOf: (t) => t == _Tab.earnings ? 'আয়ের ইতিহাস' : 'পেমেন্টের ইতিহাস',
                onSelected: (t) => setState(() => _tab = t),
              ),
              SizedBox(height: 10.h),
              if (_tab == _Tab.earnings) const _EarningHistory() else const _PayoutHistory(),
              SizedBox(height: 12.h),
              Text('পেমেন্ট অ্যাডমিন অনুমোদনের পর দেওয়া হয়। ব্যবসার মোট লাভের হিসাব এখানে দেখানো হয় না।',
                  style: AppText.small, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningHistory extends ConsumerWidget {
  const _EarningHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(earningsHistoryProvider);
    return v.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(earningsHistoryProvider)),
      data: (list) => list.isEmpty
          ? AppCard(child: Text('এখনো কোনো আয় নেই।', style: AppText.caption, textAlign: TextAlign.center))
          : AppCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
              child: Column(children: [
                for (var i = 0; i < list.length; i++)
                  _HistoryRow(
                    title: BnFormat.date(list[i].date),
                    subtitle: '${BnFormat.digits('${list[i].salesCount}')}টি বিক্রি',
                    amount: BnFormat.money(list[i].amount),
                    chip: StatusChip.request(list[i].status),
                    divider: i < list.length - 1,
                  ),
              ]),
            ),
    );
  }
}

class _PayoutHistory extends ConsumerWidget {
  const _PayoutHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(payoutsProvider);
    return v.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(payoutsProvider)),
      data: (list) => list.isEmpty
          ? AppCard(child: Text('এখনো কোনো পেমেন্ট হয়নি।', style: AppText.caption, textAlign: TextAlign.center))
          : AppCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
              child: Column(children: [
                for (var i = 0; i < list.length; i++)
                  _HistoryRow(
                    title: BnFormat.dateFull(list[i].date),
                    subtitle: list[i].method,
                    amount: BnFormat.money(list[i].amount),
                    chip: StatusChip.request(RequestStatus.completed),
                    divider: i < list.length - 1,
                  ),
              ]),
            ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.chip,
    required this.divider,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Widget chip;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))) : null,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.bodyStrong),
            Text(subtitle, style: AppText.caption),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount, style: AppText.amount(15)),
          SizedBox(height: 2.h),
          chip,
        ]),
      ]),
    );
  }
}
