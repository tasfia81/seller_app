import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
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
  int _payMode = 0; // 0 টাকা নেব, 1 আবার বিনিয়োগ
  int _dest = 0; // 0 ব্যাংক, 1 বিকাশ
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _entered => int.tryParse(BnFormat.toAscii(_amount.text).replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(summaryProvider);
    final holdings = ref.watch(holdingsProvider);
    final inStock = holdings.fold(0, (sum, h) => sum + h.invested);

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
                    ? _profit(s.profitThisMonth, s.nextPayoutLabel)
                    : _capital(s.activeCapital, s.uninvested, inStock),
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('মূলধন ফেরত ${tk(s.withdrawn)}', style: AppText.bodyStrong),
                              Text('চাওয়া ২ নভে · পেয়েছেন ১৮ নভে · ব্যাংক ••৪৮২১', style: AppText.small),
                            ],
                          ),
                        ),
                        const Pill('সম্পন্ন'),
                      ],
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

  Widget _profit(int pending, String payoutLabel) {
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
              _choice('প্রতি মাসে টাকা হাতে নেব', 0, _payMode, (v) => setState(() => _payMode = v)),
              _choice('লাভ আবার বিনিয়োগ করব', 1, _payMode, (v) => setState(() => _payMode = v)),
              if (_payMode == 1)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text('পরিবর্তন পরের মাস থেকে কার্যকর হবে। (ডেমো — এখনো সংরক্ষণ হয় না)',
                      style: AppText.small),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _capital(int active, int idle, int inStock) {
    final amount = _entered;
    final fast = amount < idle ? amount : idle;
    final later = amount - fast;
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
                'স্টকে থাকা টাকা বিক্রি হওয়ার সাথে সাথে ফেরত আসে — অনুরোধের পর সর্বোচ্চ ${BnFormat.digits('${AppConfig.capitalNoticeDays}')} দিন।',
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
              if (amount > 0 && !tooMuch) ...[
                SizedBox(height: 6.h),
                Text(
                  later > 0
                      ? '${tk(fast)} ৩ দিনে, বাকি ${tk(later)} বিক্রি অনুযায়ী ${BnFormat.digits('${AppConfig.capitalNoticeDays}')} দিনের মধ্যে'
                      : '${tk(fast)} ৩ দিনের মধ্যে',
                  style: AppText.caption,
                ),
              ],
              SizedBox(height: 12.h),
              Text('কোথায় নেবেন', style: AppText.label),
              _choice('ব্যাংক অ্যাকাউন্ট ••৪৮২১', 0, _dest, (v) => setState(() => _dest = v)),
              _choice('বিকাশ ••৭৭০২', 1, _dest, (v) => setState(() => _dest = v)),
              SizedBox(height: 8.h),
              FilledButton(
                onPressed: amount <= 0 || tooMuch
                    ? null
                    : () => showDemoNotice(context, 'ডেমো মোড: অনুরোধ এখনো সার্ভারে যায়নি। ব্যাকএন্ড যুক্ত হলে কাজ করবে।'),
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

  Widget _choice(String label, int value, int group, ValueChanged<int> onChanged) {
    return RadioListTile<int>(
      value: value,
      groupValue: group,
      onChanged: (v) => onChanged(v ?? group),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(label, style: AppText.body),
    );
  }
}
