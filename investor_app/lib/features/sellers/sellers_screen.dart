import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class SellersScreen extends ConsumerStatefulWidget {
  const SellersScreen({super.key});

  @override
  ConsumerState<SellersScreen> createState() => _SellersScreenState();
}

class _SellersScreenState extends ConsumerState<SellersScreen> {
  int _range = 0; // আজ, এই সপ্তাহ, এই মাস
  static const _ranges = ['আজ', 'এই সপ্তাহ', 'এই মাস'];

  int _sold(SellerHolding s) => switch (_range) { 0 => s.soldToday, 1 => s.soldWeek, _ => s.soldMonth };

  @override
  Widget build(BuildContext context) {
    final sellers = ref.watch(sellersProvider);
    final inHand = sellers.fold(0, (sum, s) => sum + s.inHand);
    final sold = sellers.fold(0, (sum, s) => sum + _sold(s));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'পেছনে যান',
                          light: false,
                          size: 44,
                          onTap: () => context.pop(),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text('সেলারদের কাছে আপনার স্টক',
                              style: AppText.cardTitle.copyWith(color: Colors.white, fontSize: 18.sp)),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        _HeadStat('সেলার', '${bn(sellers.length)} জন'),
                        _HeadStat('হাতে আছে', bn(inHand)),
                        _HeadStat('${_ranges[_range]} বিক্রি', bn(sold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
              sliver: SliverToBoxAdapter(
                child: FilterPills(labels: _ranges, index: _range, onChanged: (i) => setState(() => _range = i)),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              sliver: SliverList.separated(
                itemCount: sellers.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) {
                  final s = sellers[i];
                  return _SellerCard(seller: s, sold: _sold(s), rangeLabel: _ranges[_range]);
                },
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h + MediaQuery.paddingOf(context).bottom),
              sliver: const SliverToBoxAdapter(
                child: InfoBox(
                  tone: InfoTone.plain,
                  icon: Icons.lock_outline_rounded,
                  text: 'সেলারের ফোন নম্বর, ঠিকানা ও NID গোপন রাখা হয়। আপনি শুধু নাম, এলাকা ও বিক্রির হিসাব দেখবেন।',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadStat extends StatelessWidget {
  const _HeadStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small.copyWith(color: AppColors.onPrimaryMuted)),
          Text(value, style: AppText.amount(20, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller, required this.sold, required this.rangeLabel});

  final SellerHolding seller;
  final int sold;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final s = seller;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppColors.softGreen,
                child: Text(s.initial, style: AppText.label.copyWith(color: AppColors.primaryDark)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: AppText.cardTitle),
                    Text('${s.area} · শেষ বিক্রি ${s.lastSale}', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12.r)),
            child: Row(
              children: [
                _Cell('হাতে', bn(s.inHand)),
                _Cell('$rangeLabel বিক্রি', bn(sold)),
                _Cell('টাকা', tk(s.amountFor(sold))),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(s.items, style: AppText.caption.copyWith(color: const Color(0xFF3C4842))),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.amount(16)),
          ),
        ],
      ),
    );
  }
}
