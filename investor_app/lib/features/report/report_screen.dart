import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int? _index; // null → latest closed month

  @override
  Widget build(BuildContext context) {
    final months = ref.watch(monthsProvider);
    final latestClosed = months.lastIndexWhere((m) => m.closed);
    final index = _index ?? (latestClosed < 0 ? months.length - 1 : latestClosed);
    final m = months[index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: EdgeInsets.only(bottom: 24.h),
        children: [
          GradientHeader(
            padding: EdgeInsets.fromLTRB(20.w, MediaQuery.paddingOf(context).top + 16.h, 20.w, 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('মাসিক রিপোর্ট', style: AppText.title.copyWith(color: Colors.white)),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: Text('${m.name} — আপনার লাভ',
                          style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted, fontSize: 14.sp)),
                    ),
                    Pill(m.closed ? 'দেওয়া হয়েছে' : 'চলমান',
                        background: AppColors.onPrimaryGlass, color: Colors.white),
                  ],
                ),
                Text(tk(m.share), style: AppText.amount(34, color: Colors.white)),
                SizedBox(height: 2.h),
                Text(m.paidNote, style: AppText.small.copyWith(color: AppColors.onPrimaryMuted)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: SegmentedTabs(
              labels: [for (final x in months) x.shortLabel],
              index: index,
              onChanged: (i) => setState(() => _index = i),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Row(
              children: [
                Expanded(child: _Tile('বিক্রি হয়েছে', '${bn(m.pieces)} পিস')),
                SizedBox(width: 10.w),
                Expanded(child: _Tile('মূলধনে পরিবর্তন', tkSigned(m.capitalChange))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: _Breakdown(m: m),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: OutlinedButton.icon(
              onPressed: () => showDemoNotice(context, 'ডেমো মোড: রিপোর্টের PDF সার্ভার যুক্ত হলে পাওয়া যাবে।'),
              icon: const Icon(Icons.download_rounded),
              label: Text('${m.name}-এর রিপোর্ট PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.amount(18)),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.m});

  final MonthReport m;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('হিসাবটা যেভাবে হলো', style: AppText.cardTitle),
                  SizedBox(height: 6.h),
                  KeyValueRow('বিক্রি', tk(m.revenue)),
                  KeyValueRow('কেনা দাম', tk(-m.cost)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
                  KeyValueRow('মোট লাভ', tk(m.gross), strong: true),
                  KeyValueRow('সেলার কমিশন', tk(-m.commission)),
                  KeyValueRow('অন্যান্য খরচ', tk(-m.otherCost)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
                  KeyValueRow('নিট লাভ', tk(m.net), strong: true),
                ],
              ),
            ),
            ColoredBox(
              color: AppColors.dark,
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('আপনার ভাগ (${BnFormat.digits('${AppConfig.profitSharePercent}')}%)',
                          style: AppText.bodyStrong.copyWith(color: Colors.white, fontSize: 16.sp)),
                    ),
                    Text(tk(m.share), style: AppText.amount(19, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
