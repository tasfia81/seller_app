import '../../core/widgets/api_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../data/support/support_repository.dart' show SupportRepository;
import '../../core/utils/bn_format.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  int _mode = 1; // 0 লাভ, 1 মূলধন
  bool _saving = false;
  String? _requestId;
  String? _requestInput;
  final _reason = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  int get _entered => int.tryParse(BnFormat.toAscii(_amount.text).replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final sState = ref.watch(summaryProvider);
    if (!sState.hasValue) return ApiStatus(sState, onRetry: () => ref.invalidate(summaryProvider));
    final s = sState.valueOrNull!;
    final history = ref.watch(withdrawalsProvider);


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: 24.h + MediaQuery.paddingOf(context).bottom),
          children: [
            GradientHeader(
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'পেছনে যান',
                    light: false,
                    size: 44,
                    onTap: () => context.pop(),
                  ),
                  SizedBox(width: 12.w),
                  Text('টাকা তুলুন', style: AppText.title.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: SegmentedTabs(
                labels: const ['লাভ', 'মূলধন ফেরত'],
                index: _mode,
                onChanged: (i) => setState(() => _mode = i),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _mode == 0
                    ? _profit(s.profitThisMonth, s.nextPayoutLabel, s.preference)
                    : _capital(s.activeCapital, s.uninvested, s.inStock ?? 0, s.noticeDays),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('আগের অনুরোধ', style: AppText.cardTitle),
                    SizedBox(height: 8.h),
                    history.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => TextButton(onPressed: () => ref.invalidate(withdrawalsProvider), child: const Text('আবার চেষ্টা করুন')),
                      data: (items) => items.isEmpty ? const Text('এখনো কোনো অনুরোধ নেই।') : Column(
                        children: [
                          for (final row in items)
                            KeyValueRow(tk((row['amount'] as num).round()), row['status_label'] as String),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profit(int pending, String payoutLabel, String preference) {
    return Column(
      key: const ValueKey('profit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('এখন তোলা যাবে', style: AppText.caption),
              Text(tk(0), style: AppText.amount(30)),
              SizedBox(height: 10.h),
              InfoBox(
                tone: InfoTone.warn,
                text: 'চলতি মাসের লাভ ${tk(pending)} মাস শেষে হিসাব বন্ধের পর $payoutLabel নিজে থেকেই আপনার মাধ্যমে চলে যাবে।',
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('লাভ কীভাবে নেবেন', style: AppText.cardTitle),
              _choice('প্রতি মাসে টাকা হাতে নেব', 0, preference == 'reinvest' ? 1 : 0,
                (value) => _changePreference(value == 0 ? 'cash' : 'reinvest')),
              _choice('লাভ আবার বিনিয়োগ করব', 1, preference == 'reinvest' ? 1 : 0,
                (value) => _changePreference(value == 0 ? 'cash' : 'reinvest')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capital(int active, int idle, int inStock, int noticeDays) {
    final amount = _entered;
    final tooMuch = amount > active;
    return Column(
      key: const ValueKey('capital'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              KeyValueRow('সক্রিয় মূলধন', tk(active), strong: true),
              KeyValueRow('এখনই ফেরত সম্ভব (খাটেনি)', tk(idle), valueColor: AppColors.primary),
              KeyValueRow('স্টকে আটকে আছে', tk(inStock)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
              Text(
                'স্টকে থাকা টাকা বিক্রি হওয়ার সাথে সাথে ফেরত আসে — অনুরোধের পর সর্বোচ্চ ${BnFormat.digits('${noticeDays}')} দিন।',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('কত টাকা ফেরত চান', style: AppText.label),
              SizedBox(height: 8.h),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]'))],
                style: AppText.amount(20),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '০',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 6.w),
                    child: Text('৳', style: AppText.amount(20, color: AppColors.textSecondary)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  errorText: tooMuch ? 'সক্রিয় মূলধনের বেশি তোলা যাবে না' : null,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _reason,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'ফেরতের কারণ'),
              ),
              SizedBox(height: 8.h),
              FilledButton(
                onPressed: amount <= 0 || tooMuch || _saving || _reason.text.trim().length < 3 ? null : _withdraw,
                child: const Text('ফেরতের অনুরোধ পাঠান'),
              ),
              SizedBox(height: 6.h),
              Text('অ্যাডমিন যাচাই করে অনুমোদন দেবেন। প্রতিটি ধাপ আপনাকে জানানো হবে।',
                  textAlign: TextAlign.center, style: AppText.small),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _run(Future<void> Function() operation, String success) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await operation();
      if (!mounted) return;
      ref.invalidate(summaryProvider);
      ref.invalidate(withdrawalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePreference(String preference) => _run(
    () => ref.read(investorRepositoryProvider).setPreference(preference),
    'লাভ পাওয়ার পছন্দ সংরক্ষিত হয়েছে।',
  );

  Future<void> _withdraw() async {
    final amount = _entered;
    final reason = _reason.text.trim();
    final input = '$amount:$reason';
    if (_requestInput != input) {
      _requestInput = input;
      _requestId = SupportRepository.newRequestId();
    }
    await _run(() async {
      await ref.read(investorRepositoryProvider).requestWithdrawal(amount, reason, _requestId!);
      if (mounted) {
        _amount.clear();
        _reason.clear();
      }
      _requestInput = null;
    }, 'ফেরতের অনুরোধ জমা হয়েছে।');
  }

  Widget _choice(String label, int value, int group, ValueChanged<int> onChanged) {
    return RadioListTile<int>(
      value: value,
      groupValue: group,
      onChanged: _saving ? null : (v) => onChanged(v ?? group),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(label, style: AppText.body),
    );
  }
}
