import '../../../core/api/seller_payload.dart';
import '../../../core/errors/failure.dart';
import '../../../core/widgets/dialogs.dart';
import '../../products/data/product_repository_impl.dart';
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
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/inventory.dart';
import '../data/inventory_repository.dart';

class MyInventoryScreen extends ConsumerWidget {
  const MyInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(inventorySummaryProvider);
    final movements = ref.watch(stockMovementsProvider);
    final pending = ref.watch(pendingAssignmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('আমার স্টক')),
      body: AsyncValueView<InventorySummary>(
        value: summary,
        onRetry: () => ref.invalidate(inventorySummaryProvider),
        data: (s) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(stockMovementsProvider);
            ref.invalidate(pendingAssignmentsProvider);
            ref.invalidate(inventorySummaryProvider);
            await ref.read(inventorySummaryProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              AppCard(
                color: AppColors.warningSurface,
                borderColor: AppColors.warningBorder,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFB57A12)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 8.w, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text('আজকের নিয়ম', style: AppText.bodyStrong),
                        StatusChip(s.policy.label, tone: ChipTone.warning),
                      ]),
                      SizedBox(height: 4.h),
                      Text(s.policy.description, style: AppText.caption.copyWith(color: AppColors.textBody)),
                    ]),
                  ),
                ]),
              ),
              SizedBox(height: 12.h),
              _grid([
                ('মোট বরাদ্দ', s.totalAssigned, null, false),
                ('বিক্রি হয়েছে', s.sold, null, false),
                ('হাতে আছে', s.available, AppColors.successText, true),
                ('ফেরতের অপেক্ষায়', s.pendingReturn, null, false),
                ('ক্ষতিগ্রস্ত', s.damaged, AppColors.errorText, false),
                ('বিতর্কিত', s.disputed, null, false),
              ]),
              SizedBox(height: 16.h),
              pending.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(pendingAssignmentsProvider)),
                data: (rows) => Column(children: [
                  for (final row in rows)
                    AppCard(child: Column(children: [
                      Text('অপেক্ষমাণ বরাদ্দ · ${row['id']}', style: AppText.bodyStrong),
                      for (final item in jsonRows(row['items']))
                        Text('${item['name']} · ${BnFormat.qty(number(item, 'quantity'))}'),
                      AppButton(label: 'স্টক হাতে পেয়েছি', onPressed: () => _accept(context, ref, row['id'] as String)),
                    ])),
                ]),
              ),
              Text('স্টকের আসা-যাওয়া', style: AppText.section),
              SizedBox(height: 8.h),
              movements.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(stockMovementsProvider)),
                data: (list) => list.isEmpty
                    ? AppCard(child: Text('আজ কোনো আসা-যাওয়া নেই।', style: AppText.caption))
                    : AppCard(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                        child: Column(children: [
                          for (var i = 0; i < list.length; i++)
                            _MovementRow(m: list[i], divider: i < list.length - 1),
                        ]),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppButton(
          label: 'স্টক ফেরতের অনুরোধ',
          icon: Icons.assignment_return_outlined,
          variant: AppButtonVariant.outline,
          onPressed: () => context.push(AppRoutes.stockReturn),
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, String id) async {
    final repository = ref.read(inventoryRepositoryProvider);
    if (repository is! ApiInventoryRepository) return;
    final confirmed = await showConfirmDialog(context, title: 'স্টক হাতে পেয়েছেন?',
      message: 'পণ্য গুনে মিলিয়ে নিশ্চিত করুন।', confirmLabel: 'পেয়েছি', cancelLabel: 'ফিরে যান');
    if (!confirmed || !context.mounted) return;
    try {
      await repository.api.post('/seller/assignments/${Uri.encodeComponent(id)}/accept');
      if (!context.mounted) return;
      ref.invalidate(pendingAssignmentsProvider);
      ref.invalidate(inventorySummaryProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(assignedProductsProvider);
    } catch (error) {
      if (context.mounted) showAppSnack(context, failureMessage(error), error: true);
    }
  }

  Widget _grid(List<(String, double, Color?, bool)> items) {
    Widget cell((String, double, Color?, bool) it) =>
        MetricTile(label: it.$1, value: BnFormat.qty(it.$2), valueColor: it.$3, highlight: it.$4);
    return Column(children: [
      for (var r = 0; r < items.length; r += 3) ...[
        if (r > 0) SizedBox(height: 8.h),
        Row(children: [
          for (var c = 0; c < 3; c++) ...[
            if (c > 0) SizedBox(width: 8.w),
            Expanded(child: cell(items[r + c])),
          ],
        ]),
      ],
    ]);
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.m, required this.divider});
  final StockMovement m;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (m.kind) {
      MovementKind.assigned => (Icons.add_rounded, AppColors.successSoft, AppColors.primary),
      MovementKind.sold => (Icons.remove_rounded, AppColors.neutralSoft, AppColors.neutralText),
      MovementKind.returnRequested => (Icons.undo_rounded, AppColors.warningSoft, AppColors.warningText),
      MovementKind.returned => (Icons.assignment_return_outlined, AppColors.neutralSoft, AppColors.neutralText),
      MovementKind.damaged => (Icons.broken_image_outlined, AppColors.errorSoft, AppColors.errorText),
    };
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))) : null,
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: fg),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: AppText.bodyStrong),
            Text('${BnFormat.time(m.time)} · ${m.subtitle}', style: AppText.caption),
          ]),
        ),
      ]),
    );
  }
}
