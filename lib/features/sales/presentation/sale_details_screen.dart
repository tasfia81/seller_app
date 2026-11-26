import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/sale.dart';
import '../data/sales_repository_impl.dart';

final _saleProvider = FutureProvider.autoDispose.family<Sale, String>(
    (ref, id) => ref.watch(salesRepositoryProvider).getSale(id));

class SaleDetailsScreen extends ConsumerWidget {
  const SaleDetailsScreen({super.key, required this.saleId, this.initial});

  final String saleId;
  final Sale? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = initial != null ? AsyncData(initial!) : ref.watch(_saleProvider(saleId));
    return Scaffold(
      appBar: AppBar(title: const Text('বিক্রির বিস্তারিত')),
      body: AsyncValueView<Sale>(
        value: value,
        onRetry: () => ref.invalidate(_saleProvider(saleId)),
        data: (s) => ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _Receipt(sale: s),
            SizedBox(height: 16.h),
            if (s.status == SaleStatus.confirmed)
              AppButton(
                label: 'সংশোধনের অনুরোধ',
                icon: Icons.edit_note_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => _requestCorrection(context, ref, s),
              ),
            SizedBox(height: 10.h),
            Text(
              'নিশ্চিত হওয়া বিক্রি মুছে ফেলা যায় না। ভুল হলে সংশোধনের অনুরোধ পাঠান, অ্যাডমিন যাচাই করবেন।',
              style: AppText.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCorrection(BuildContext context, WidgetRef ref, Sale s) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _CorrectionSheet(),
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(salesRepositoryProvider).requestCorrection(s.id, reason);
      if (context.mounted) showAppSnack(context, 'সংশোধনের অনুরোধ পাঠানো হয়েছে। অ্যাডমিন যাচাই করবেন।');
    } catch (e) {
      if (context.mounted) showAppSnack(context, failureMessage(e), error: true);
    }
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final s = sale;
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
          SizedBox(width: 8.w),
          Expanded(child: Text('রসিদ', style: AppText.section)),
          StatusChip.sale(s.status),
        ]),
        SizedBox(height: 8.h),
        Text(s.status == SaleStatus.pendingSync ? 'সার্ভারে পাঠানো বাকি' : 'বিক্রি নম্বর #${s.receiptNo ?? s.id}', style: AppText.caption),
        Text(BnFormat.dateTime(s.time), style: AppText.caption),
        const Divider(height: 24),
        KeyValueRow('পণ্য', s.productName),
        if (s.variant != null) KeyValueRow('ধরন', s.variant!),
        KeyValueRow('পরিমাণ', '${BnFormat.qty(s.quantity)} ${s.unit.label}'),
        KeyValueRow('একক দাম', BnFormat.money(s.unitPrice)),
        KeyValueRow('পেমেন্ট', s.payment.label),
        if (s.note != null) KeyValueRow('নোট', s.note!),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(child: Text('মোট', style: AppText.section)),
          Text(BnFormat.money(s.total), style: AppText.amount(22, color: AppColors.successText)),
        ]),
      ]),
    );
  }
}

class _CorrectionSheet extends StatefulWidget {
  const _CorrectionSheet();

  @override
  State<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<_CorrectionSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, MediaQuery.viewInsetsOf(context).bottom + 16.h),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('কী ভুল হয়েছে?', style: AppText.section.copyWith(fontSize: 17.sp)),
        SizedBox(height: 10.h),
        TextField(
          controller: _c,
          autofocus: true,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'যেমন: পরিমাণ ২ এর বদলে ১ হবে'),
        ),
        SizedBox(height: 12.h),
        AppButton(
          label: 'অনুরোধ পাঠান',
          onPressed: _c.text.trim().isEmpty ? null : () => Navigator.pop(context, _c.text.trim()),
        ),
      ]),
    );
  }
}
