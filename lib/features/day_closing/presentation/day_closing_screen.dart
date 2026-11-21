import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/finance.dart';
import '../data/day_closing_repository.dart';

class DayClosingScreen extends ConsumerStatefulWidget {
  const DayClosingScreen({super.key});

  @override
  ConsumerState<DayClosingScreen> createState() => _DayClosingScreenState();
}

class _DayClosingScreenState extends ConsumerState<DayClosingScreen> {
  bool _sending = false;

  Future<void> _submit() async {
    final ok = await showConfirmDialog(context,
        title: 'দিনের হিসাব জমা দেবেন?',
        message: 'জমা দেওয়ার পর আজকের বিক্রি আর যোগ করা যাবে না।',
        confirmLabel: 'জমা দিন');
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      await ref.read(dayClosingRepositoryProvider).submitClosing();
      if (mounted) showAppSnack(context, 'দিনের হিসাব জমা হয়েছে। অ্যাডমিন যাচাই করবেন।');
    } catch (e) {
      if (mounted) showAppSnack(context, failureMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(dayClosingProvider);
    final data = value.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text('দিনের হিসাব · ${BnFormat.date(DateTime.now())}')),
      body: AsyncValueView<DayClosingSummary>(
        value: value,
        onRetry: () => ref.invalidate(dayClosingProvider),
        data: (d) {
          final pending = d.requirements.where((r) => !r.done).length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dayClosingProvider.future),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                AppCard(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                  child: Column(children: [
                    KeyValueRow('মোট বিক্রি', BnFormat.money(d.totalSales)),
                    KeyValueRow('বিক্রিত পণ্য', '${BnFormat.digits('${d.itemsSold}')}টি'),
                    KeyValueRow('ক্যাশ / ডিজিটাল', '${BnFormat.money(d.cashCollected)} / ${BnFormat.money(d.digitalCollected)}'),
                    KeyValueRow('হাতে থাকা স্টক', '${BnFormat.qty(d.availableStock)}টি'),
                    KeyValueRow('ফেরতের অনুরোধ', '${BnFormat.digits('${d.pendingReturns}')}টি অপেক্ষমাণ'),
                    KeyValueRow('আজকের আয়', BnFormat.money(d.earned), valueColor: AppColors.successText, divider: false),
                  ]),
                ),
                SizedBox(height: 12.h),
                AppCard(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 6.w, 8.h),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('জমার আগে যা করতে হবে', style: AppText.section)),
                      StatusChip(d.policy.label, tone: ChipTone.warning),
                      SizedBox(width: 8.w),
                    ]),
                    SizedBox(height: 4.h),
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(d.policy.description, style: AppText.caption),
                    ),
                    SizedBox(height: 6.h),
                    for (final r in d.requirements) _RequirementRow(r: r),
                  ]),
                ),
                if (pending > 0) ...[
                  SizedBox(height: 12.h),
                  InfoBanner(
                    tone: BannerTone.warning,
                    icon: Icons.pending_actions_outlined,
                    text: 'আরও ${BnFormat.digits('$pending')}টি বিষয় বাকি আছে। এগুলো শেষ হলে দিনের হিসাব জমা দিতে পারবেন।',
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: data == null
          ? null
          : BottomActionBar(
              child: AppButton(
                label: 'দিনের হিসাব জমা দিন',
                loading: _sending,
                onPressed: data.canSubmit ? _submit : null,
              ),
            ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.r});
  final ClosingRequirement r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(children: [
        Icon(r.done ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 20, color: r.done ? AppColors.primary : const Color(0xFFC23B3B)),
        SizedBox(width: 10.w),
        Expanded(child: Text(r.text, style: AppText.body)),
        if (!r.done && r.actionLabel != null && r.route != null)
          TextButton(
            onPressed: () => context.push(r.route!),
            style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
            child: Text(r.actionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
          )
        else
          const SizedBox(height: 44),
      ]),
    );
  }
}
