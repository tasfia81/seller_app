import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_text.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/data/dashboard_repository.dart';
import '../../products/data/product_repository_impl.dart';
import '../data/inventory_repository.dart';

class PendingStock extends ConsumerWidget {
  const PendingStock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(pendingAssignmentsProvider).when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(pendingAssignmentsProvider),
      ),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final quantities = <String, double>{};
        for (final row in rows) {
          for (final item in jsonRows(row['items'])) {
            final unit = parseUnit(item['unit']).label;
            quantities.update(unit, (sum) => sum + number(item, 'quantity'), ifAbsent: () => number(item, 'quantity'));
          }
        }
        final summary = quantities.entries.map((item) => '${BnFormat.qty(item.value)} ${item.key}').join(' · ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('গ্রহণ বাকি · $summary', style: AppText.section),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _AssignmentCard(key: ValueKey(row['id']), row: row),
              ),
          ],
        );
      },
    );
  }
}

class _AssignmentCard extends ConsumerStatefulWidget {
  const _AssignmentCard({super.key, required this.row});

  final Json row;

  @override
  ConsumerState<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends ConsumerState<_AssignmentCard> {
  bool _busy = false;

  Future<void> _accept(List<String> details) async {
    final repository = ref.read(inventoryRepositoryProvider);
    if (repository is! ApiInventoryRepository) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'স্টক হাতে পেয়েছেন?',
      message: details.join('\n'),
      scrollable: true,
      confirmLabel: 'পেয়েছি',
      cancelLabel: 'ফিরে যান',
    );
    if (!confirmed || !mounted || _busy) return;
    setState(() => _busy = true);
    final invalidate = ProviderScope.containerOf(context);
    try {
      await repository.api.post('/seller/assignments/${Uri.encodeComponent(widget.row['id'] as String)}/accept');
      if (mounted) showAppSnack(context, 'স্টক গ্রহণ করা হয়েছে।');
      invalidate.invalidate(pendingAssignmentsProvider);
      invalidate.invalidate(inventorySummaryProvider);
      invalidate.invalidate(stockMovementsProvider);
      invalidate.invalidate(assignedProductsProvider);
      invalidate.invalidate(homeDataProvider);
    } catch (error) {
      if (mounted) showAppSnack(context, failureMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      for (final item in jsonRows(widget.row['items']))
        '${item['name']}${item['variant'] == null ? '' : ' · সাইজ/ধরন ${item['variant']}'} · ${BnFormat.qty(number(item, 'quantity'))} ${parseUnit(item['unit']).label}',
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final detail in details)
            Text(detail, style: AppText.body),
          const SizedBox(height: 8),
          AppButton(
            label: 'স্টক হাতে পেয়েছি',
            loading: _busy,
            onPressed: _busy ? null : () => _accept(details),
          ),
        ],
      ),
    );
  }
}
