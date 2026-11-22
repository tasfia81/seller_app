import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';
import '../common/sheets.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  int _filter = 0;
  static const _labels = ['সব', 'বিনিয়োগ', 'লাভ', 'ফেরত'];
  static const _kinds = [null, LedgerKind.invest, LedgerKind.profit, LedgerKind.withdraw];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(summaryProvider);
    final all = ref.watch(ledgerProvider);
    final kind = _kinds[_filter];
    final rows = kind == null ? all : all.where((e) => e.kind == kind).toList(growable: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              padding: EdgeInsets.fromLTRB(20.w, MediaQuery.paddingOf(context).top + 16.h, 16.w, 22.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('লেনদেনের খাতা', style: AppText.title.copyWith(color: Colors.white))),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                        ),
                        onPressed: () => showInvestSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('নতুন বিনিয়োগ'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _HeadStat('দিয়েছেন', tk(s.totalInvested)),
                      _HeadStat('লাভ পেয়েছেন', tk(s.profitPaid)),
                      _HeadStat('ফেরত নিয়েছেন', tk(s.withdrawn)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
            sliver: SliverToBoxAdapter(
              child: FilterPills(labels: _labels, index: _filter, onChanged: (i) => setState(() => _filter = i)),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
              sliver: SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                sliver: SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => _LedgerRow(entry: rows[i]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            sliver: SliverToBoxAdapter(
              child: Text('প্রতিটি লেনদেনের রসিদ নম্বর আছে — ট্যাপ করে বিস্তারিত দেখুন',
                  textAlign: TextAlign.center, style: AppText.small),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadStat extends StatelessWidget {
  const _HeadStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small.copyWith(color: AppColors.onPrimaryMuted)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.amount(16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final (icon, bg, fg, amount, amountColor) = switch (e.kind) {
      LedgerKind.invest => (Icons.south_rounded, AppColors.softGreen, AppColors.primaryDark, tk(e.amount), AppColors.textPrimary),
      LedgerKind.profit => (Icons.attach_money_rounded, AppColors.softGreen, AppColors.primaryDark, tkSigned(e.amount), AppColors.primary),
      LedgerKind.withdraw => (Icons.north_rounded, AppColors.amberSoft, AppColors.amber, tkSigned(-e.amount), AppColors.amber),
    };
    return InkWell(
      onTap: () => showInfoSheet(
        context,
        title: e.title,
        children: [
          KeyValueRow('পরিমাণ', amount, strong: true, valueColor: amountColor),
          KeyValueRow('তারিখ', e.date),
          KeyValueRow('মাধ্যম', e.via),
          KeyValueRow('রসিদ নম্বর', e.reference),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => showDemoNotice(context, 'ডেমো মোড: রসিদের PDF সার্ভার যুক্ত হলে পাওয়া যাবে।'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('রসিদ ডাউনলোড (PDF)'),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            IconBox(icon: icon, background: bg, color: fg, size: 40),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: AppText.bodyStrong),
                  Text('${e.date} · ${e.via}', style: AppText.small),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: AppText.amount(15, color: amountColor)),
                Text('রসিদ ${e.reference}', style: AppText.small),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
