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
  HandoverMethod? _method;
  bool _sending = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(BnFormat.toAscii(_amount.text).replaceAll(',', ''));

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final method = _method!;
    final ok = await showConfirmDialog(context,
        title: 'জমার তথ্য পাঠাবেন?',
        message: '${BnFormat.money(_value!)} · ${method.label}\nঅ্যাডমিন যাচাই করার পরই জমা সম্পন্ন হবে।',
        confirmLabel: 'পাঠান');
    if (!ok || !mounted) return;
    setState(() => _sending = true);
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await ref.read(cashRepositoryProvider).submit(
            amount: _value!,
            method: method,
            reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      container.invalidate(cashSnapshotProvider);
      setState(() {
        _amount.clear();
        _reference.clear();
        _note.clear();
        _form.currentState?.clearError();
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
    final cash = ref.watch(cashSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ক্যাশ জমা')),
      body: AsyncValueView<CashSnapshot>(
        value: cash,
        onRetry: () => ref.invalidate(cashSnapshotProvider),
        data: (snapshot) {
          final s = snapshot.summary;
          final remaining = s.remaining;
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
                    KeyValueRow('যাচাইয়ের অপেক্ষায়', BnFormat.money(s.pendingVerification)),
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
                _HandoverMethodField(
                  value: _method,
                  enabled: !_sending,
                  onChanged: (method) => setState(() => _method = method),
                ),
                if (_method != null) ...[
                  SizedBox(height: 16.h),
                  AppTextField(
                    label: _method == HandoverMethod.inPerson
                        ? 'যার হাতে দিলেন তার নাম'
                        : 'লেনদেন নম্বর / রেফারেন্স',
                    optional: true,
                    controller: _reference,
                    hint: _method == HandoverMethod.inPerson ? null : 'যেমন: TX8K2…',
                  ),
                ],
                SizedBox(height: 14.h),
                AppTextField(label: 'নোট', optional: true, controller: _note, textInputAction: TextInputAction.done),
                SizedBox(height: 10.h),
                Text('অ্যাডমিন টাকা বুঝে নিয়ে যাচাই করার পরই জমা সম্পন্ন দেখাবে।', style: AppText.caption),
                SizedBox(height: 16.h),
                AppButton(
                  label: 'জমার তথ্য পাঠান',
                  loading: _sending,
                  onPressed: remaining <= 0 ? null : _submit,
                ),
                SizedBox(height: 24.h),
                Text('জমার ইতিহাস', style: AppText.section),
                SizedBox(height: 8.h),
                _History(items: snapshot.history),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HandoverMethodField extends StatelessWidget {
  const _HandoverMethodField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final HandoverMethod? value;
  final bool enabled;
  final ValueChanged<HandoverMethod> onChanged;

  Future<HandoverMethod?> _pick(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showModalBottomSheet<HandoverMethod>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text('জমার মাধ্যম বাছুন', style: AppText.section),
              ),
              for (final method in HandoverMethod.values)
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    selected: value == method,
                    selectedColor: AppColors.primaryDark,
                    selectedTileColor: AppColors.successSoft,
                    tileColor: AppColors.background,
                    leading: Container(
                      width: 38.r,
                      height: 38.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: _DepositMethodIcon(method),
                    ),
                    title: Text(method.label, style: AppText.bodyStrong),
                    trailing: value == method ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(sheetContext).pop(method),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<HandoverMethod>(
      initialValue: value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (method) => method == null ? 'জমার মাধ্যম বাছুন।' : null,
      builder: (field) {
        final method = field.value;
        return Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: !enabled ? null : () async {
                final selected = await _pick(context);
                if (!field.mounted || selected == null) return;
                field.didChange(selected);
                onChanged(selected);
              },
              child: InputDecorator(
                decoration: InputDecoration(errorText: field.errorText, enabled: enabled),
                child: Row(
                  children: [
                    if (method == null)
                      Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryDark, size: 22.r)
                    else
                      _DepositMethodIcon(method),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        method?.label ?? 'জমার মাধ্যম বাছুন',
                        style: AppText.input.copyWith(
                          color: method == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DepositMethodIcon extends StatelessWidget {
  const _DepositMethodIcon(this.method);

  final HandoverMethod method;

  @override
  Widget build(BuildContext context) {
    final asset = switch (method) {
      HandoverMethod.inPerson => 'handshake',
      HandoverMethod.bkash => 'bkash',
      HandoverMethod.nagad => 'nagad',
      HandoverMethod.bank => 'landmark',
    };
    return Image.asset(
      'assets/deposit_methods/$asset.png',
      width: 23.r,
      height: 23.r,
      excludeFromSemantics: true,
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.items});
  final List<CashHandover> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(child: Text('এখনো কোনো জমা নেই।', style: AppText.caption, textAlign: TextAlign.center));
    }
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      child: Column(children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: i < items.length - 1
                ? const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider)))
                : null,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(BnFormat.money(items[i].amount), style: AppText.amount(15)),
                  Text('${BnFormat.dateTime(items[i].submittedAt)} · ${items[i].method.label}', style: AppText.caption),
                ]),
              ),
              switch (items[i].status) {
                RequestStatus.pending => const StatusChip('যাচাইয়ের অপেক্ষায়', tone: ChipTone.warning),
                RequestStatus.rejected => const StatusChip('প্রত্যাখ্যাত', tone: ChipTone.error),
                _ => const StatusChip('যাচাই হয়েছে', tone: ChipTone.success),
              },
            ]),
          ),
      ]),
    );
  }
}
