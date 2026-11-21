import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/finance.dart';
import '../data/cash_repository.dart';

class CashHandoverScreen extends ConsumerStatefulWidget {
  const CashHandoverScreen({super.key});

  @override
  ConsumerState<CashHandoverScreen> createState() => _CashHandoverScreenState();
}

class _CashHandoverScreenState extends ConsumerState<CashHandoverScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  HandoverMethod _method = HandoverMethod.inPerson;
  bool _sending = false;
  bool _prefilled = false;
  final List<CashHandover> _submitted = [];

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(BnFormat.toAscii(_amount.text).replaceAll(',', ''));

  Future<void> _submit(CashSummary s) async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final ok = await showConfirmDialog(context,
        title: 'জমার তথ্য পাঠাবেন?',
        message: '${BnFormat.money(_value!)} · ${_method.label}\nঅ্যাডমিন যাচাই করার পরই জমা সম্পন্ন হবে।',
        confirmLabel: 'পাঠান');
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      final h = await ref.read(cashRepositoryProvider).submit(
            amount: _value!,
            method: _method,
            reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _submitted.insert(0, h);
        _amount.clear();
        _reference.clear();
        _note.clear();
      });
      showAppSnack(context, 'জমার তথ্য পাঠানো হয়েছে — যাচাইয়ের অপেক্ষায়।');
    } catch (e) {
      if (mounted) showAppSnack(context, failureMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(cashSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যাশ জমা')),
      body: AsyncValueView<CashSummary>(
        value: summary,
        onRetry: () => ref.invalidate(cashSummaryProvider),
        data: (s) {
          final pendingLocal = _submitted.fold<double>(0, (a, h) => a + h.amount);
          final remaining = (s.remaining - pendingLocal).clamp(0, double.infinity).toDouble();
          if (!_prefilled && remaining > 0) {
            _prefilled = true;
            _amount.text = BnFormat.number(remaining, decimals: 2).replaceAll(',', '');
          }
          return Form(
            key: _form,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(16.r),
              children: [
                AppCard(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                  child: Column(children: [
                    KeyValueRow('আজ সংগ্রহ করা ক্যাশ', BnFormat.money(s.collected)),
                    KeyValueRow('আগে যাচাই হয়েছে', BnFormat.money(s.verified)),
                    KeyValueRow('যাচাইয়ের অপেক্ষায়', BnFormat.money(s.pendingVerification + pendingLocal)),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Row(children: [
                        Expanded(child: Text('জমা দিতে বাকি', style: AppText.bodyStrong)),
                        Text(BnFormat.money(remaining), style: AppText.amount(22, color: AppColors.warningText)),
                      ]),
                    ),
                  ]),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: 'জমার পরিমাণ',
                  required: true,
                  controller: _amount,
                  prefixText: '৳ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]'))],
                  validator: (_) {
                    final v = _value;
                    if (v == null || v <= 0) return 'সঠিক পরিমাণ দিন।';
                    if (v > remaining + 0.001) return 'বাকি টাকার (${BnFormat.money(remaining)}) চেয়ে বেশি দেওয়া যাবে না।';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                const FieldLabel('কীভাবে জমা দিচ্ছেন', required: true),
                ChoicePills<HandoverMethod>(
                  options: HandoverMethod.values,
                  selected: _method,
                  labelOf: (m) => m.label,
                  onSelected: (m) => setState(() => _method = m),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  label: 'লেনদেন নম্বর / রেফারেন্স',
                  optional: true,
                  controller: _reference,
                  hint: _method == HandoverMethod.inPerson ? 'যার হাতে দিলেন তার নাম' : 'যেমন: TX8K2…',
                ),
                SizedBox(height: 14.h),
                AppTextField(label: 'নোট', optional: true, controller: _note, textInputAction: TextInputAction.done),
                SizedBox(height: 10.h),
                Text('অ্যাডমিন টাকা বুঝে নিয়ে যাচাই করার পরই জমা সম্পন্ন দেখাবে।', style: AppText.caption),
                SizedBox(height: 16.h),
                AppButton(
                  label: 'জমার তথ্য পাঠান',
                  loading: _sending,
                  onPressed: remaining <= 0 ? null : () => _submit(s),
                ),
                SizedBox(height: 24.h),
                Text('জমার ইতিহাস', style: AppText.section),
                SizedBox(height: 8.h),
                _History(local: _submitted),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.local});
  final List<CashHandover> local;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(cashHistoryProvider);
    return v.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(cashHistoryProvider)),
      data: (remote) {
        final list = [...local, ...remote];
        if (list.isEmpty) {
          return AppCard(child: Text('এখনো কোনো জমা নেই।', style: AppText.caption, textAlign: TextAlign.center));
        }
        return AppCard(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
          child: Column(children: [
            for (var i = 0; i < list.length; i++)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: i < list.length - 1
                    ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider)))
                    : null,
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(BnFormat.money(list[i].amount), style: AppText.amount(15)),
                      Text('${BnFormat.dateTime(list[i].submittedAt)} · ${list[i].method.label}', style: AppText.caption),
                    ]),
                  ),
                  StatusChip(
                    list[i].status == RequestStatus.pending ? 'যাচাইয়ের অপেক্ষায়' : 'যাচাই হয়েছে',
                    tone: list[i].status == RequestStatus.pending ? ChipTone.warning : ChipTone.success,
                  ),
                ]),
              ),
          ]),
        );
      },
    );
  }
}
