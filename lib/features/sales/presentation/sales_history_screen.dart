import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/sale.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../data/sales_repository_impl.dart';

typedef SalesQuery = ({SalesPeriod period, DateTimeRange? range});

final salesListProvider = FutureProvider.autoDispose.family<List<Sale>, SalesQuery>((ref, q) {
  return ref.watch(salesRepositoryProvider).getSales(period: q.period, from: q.range?.start, to: q.range?.end);
});

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  SalesPeriod _period = SalesPeriod.today;
  DateTimeRange? _range;
  SaleStatus? _status;
  String _query = '';

  SalesQuery get _q => (period: _period, range: _range);

  Future<void> _onPeriod(SalesPeriod p) async {
    if (p != SalesPeriod.custom) {
      setState(() => _period = p);
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'তারিখ বাছুন',
    );
    if (picked != null) {
      setState(() {
        _period = SalesPeriod.custom;
        _range = picked;
      });
    }
  }

  Future<void> _pickStatus() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: const Text('সব অবস্থা'),
            trailing: _status == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () => Navigator.pop(ctx, 'all'),
          ),
          for (final s in SaleStatus.values)
            ListTile(
              title: Text(s.label),
              trailing: _status == s ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(ctx, s),
            ),
          SizedBox(height: 8.h),
        ]),
      ),
    );
    if (picked == null) return;
    setState(() => _status = picked is SaleStatus ? picked : null);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(salesListProvider(_q));
    return Scaffold(
      appBar: AppBar(titleSpacing: 16.w, title: const Text('বিক্রির ইতিহাস')),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: Column(children: [
            AppSearchField(
              hint: 'বিক্রি নম্বর দিয়ে খুঁজুন',
              onChanged: (v) => setState(() => _query = BnFormat.digits(v.trim())),
            ),
            SizedBox(height: 10.h),
            ChoicePills<SalesPeriod>(
              options: SalesPeriod.values,
              selected: _period,
              style: PillStyle.filter,
              scrollable: true,
              iconOf: (p) => p == SalesPeriod.custom ? Icons.calendar_month_outlined : null,
              labelOf: (p) => p == SalesPeriod.custom && _range != null
                  ? '${BnFormat.date(_range!.start)} – ${BnFormat.date(_range!.end)}'
                  : p.label,
              onSelected: _onPeriod,
            ),
          ]),
        ),
        Expanded(
          child: AsyncValueView(
            value: value,
            onRetry: () => ref.invalidate(salesListProvider(_q)),
            data: (all) {
              final list = all
                  .where((s) => _status == null || s.status == _status)
                  .where((s) => _query.isEmpty || (s.receiptNo ?? s.id).toLowerCase().contains(_query.toLowerCase()))
                  .toList();
              final total = list.fold<double>(0, (a, s) => a + s.total);
              return RefreshIndicator(
                onRefresh: () => ref.refresh(salesListProvider(_q).future),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text.rich(TextSpan(style: AppText.caption, children: [
                          TextSpan(text: '${BnFormat.digits('${list.length}')}টি বিক্রি · '),
                          TextSpan(text: BnFormat.money(total), style: AppText.bodyStrong),
                        ])),
                      ),
                      TextButton.icon(
                        onPressed: _pickStatus,
                        style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        label: Text(_status?.label ?? 'সব অবস্থা'),
                      ),
                    ]),
                    if (list.isEmpty)
                      SizedBox(
                        height: 320.h,
                        child: EmptyView(
                          icon: Icons.receipt_long_outlined,
                          title: all.isEmpty ? 'এই সময়ে কোনো বিক্রি নেই' : 'কোনো বিক্রি মেলেনি',
                          message: all.isEmpty ? 'বিক্রি যোগ করলে এখানে দেখা যাবে।' : 'অন্য নম্বর বা ফিল্টার দিয়ে খুঁজুন।',
                          actionLabel: all.isEmpty ? 'নতুন বিক্রি' : null,
                          onAction: () => context.push(AppRoutes.newSale()),
                        ),
                      )
                    else
                      for (final s in list)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: SaleCard(
                            sale: s,
                            onTap: () => context.push(AppRoutes.saleDetail(s.id), extra: s),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
