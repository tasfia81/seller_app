import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/bn_format.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/ui.dart';
import '../../data/investor_repository.dart';
import '../../data/models.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(holdingProvider(productId));
    if (h == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('প্রোডাক্টটি পাওয়া যায়নি', style: AppText.body)),
      );
    }
    final gap = SizedBox(height: 12.h);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.only(bottom: 24.h + MediaQuery.paddingOf(context).bottom),
          children: [
            _Header(h: h),
            gap,
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'স্টকের অবস্থা', style: AppText.cardTitle),
                    TextSpan(text: '  · কেনা ${h.purchasedOn}', style: AppText.caption),
                  ])),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _StockTile('বিক্রি হয়েছে', h.sold, Icons.check_rounded)),
                      SizedBox(width: 8.w),
                      Expanded(child: _StockTile('সেলারের হাতে', h.withSellers, Icons.person_outline_rounded)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: _StockTile('গুদামে', h.inWarehouse, Icons.warehouse_outlined)),
                      SizedBox(width: 8.w),
                      Expanded(child: _StockTile('নষ্ট / হারানো', h.damaged, Icons.error_outline_rounded, bad: true)),
                    ],
                  ),
                ],
              ),
            ),
            gap,
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('কোন সেলারের দায়িত্বে', style: AppText.cardTitle)),
                      TextButton(onPressed: () => context.push(AppRoutes.sellers), child: const Text('সব দেখুন')),
                    ],
                  ),
                  for (final s in h.sellers)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 21.r,
                            backgroundColor: AppColors.softGreen,
                            child: Text(s.initial, style: AppText.label.copyWith(color: AppColors.primaryDark)),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: AppText.bodyStrong),
                                Text(s.area, style: AppText.small),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(text: bn(s.inHand), style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700)),
                                TextSpan(text: ' হাতে', style: AppText.small),
                              ])),
                              Text('${bn(s.sold)} বিক্রি', style: AppText.small),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            gap,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ClipRRect(
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
                            Text('লাভের হিসাব', style: AppText.cardTitle),
                            SizedBox(height: 6.h),
                            KeyValueRow('বিক্রি (${bn(h.sold)} × ${tk(h.salePrice)})', tk(h.revenue)),
                            KeyValueRow('কেনা দাম (${bn(h.sold)} × ${tk(h.unitCost)})', tk(-h.costOfSold)),
                            KeyValueRow('সেলার কমিশন (${BnFormat.digits('${AppConfig.sellerCommissionPercent}')}%)',
                                tk(-h.sellerCommission)),
                            KeyValueRow('অন্যান্য খরচ', tk(-h.otherCost)),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
                            KeyValueRow('নিট লাভ', tk(h.netProfit), strong: true),
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
                                child: Text(
                                  'আপনার ভাগ (${BnFormat.digits('${AppConfig.profitSharePercent}')}%)',
                                  style: AppText.bodyStrong.copyWith(color: Colors.white, fontSize: 16.sp),
                                ),
                              ),
                              Text(tk(h.investorShare), style: AppText.amount(20, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (h.damaged > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                child: Text(
                  'নষ্ট ${bn(h.damaged)} পিসের ক্ষতি (${tk(h.damageLoss)}) তদন্তের পর হিসাবে যোগ হবে।',
                  style: AppText.small,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.h});

  final ProductHolding h;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Expanded(
                child: Text('প্রোডাক্টের বিস্তারিত',
                    textAlign: TextAlign.center, style: AppText.bodyStrong.copyWith(color: Colors.white, fontSize: 16.sp)),
              ),
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'নোটিফিকেশন',
                size: 44,
                onTap: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              const IconBox(icon: Icons.checkroom_outlined, background: AppColors.onPrimaryGlass, color: Colors.white, size: 48),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('আপনার বিনিয়োগ', style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted)),
                    Text(h.name, style: AppText.title.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Pill(h.remaining > 0 ? 'চালু' : 'শেষ', background: AppColors.onPrimaryGlass, color: Colors.white),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(color: Color(0x2EFFFFFF)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text('${bn(h.bought)} পিস × ${tk(h.unitCost)} · ${h.batch}',
                    style: AppText.caption.copyWith(color: AppColors.onPrimaryMuted, fontSize: 14.sp)),
              ),
              Text(tk(h.invested), style: AppText.amount(15, color: Colors.white)),
            ],
          ),
          SizedBox(height: 2.h),
          Text('বিক্রির দাম ${h.priceNote}', style: AppText.small.copyWith(color: AppColors.onPrimaryMuted)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AppCard(child: child),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile(this.label, this.value, this.icon, {this.bad = false});

  final String label;
  final int value;
  final IconData icon;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bad ? AppColors.dangerSoft : AppColors.softGreen,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.small.copyWith(color: bad ? AppColors.dangerText : AppColors.softGreenText)),
                Text(bn(value), style: AppText.amount(20, color: bad ? AppColors.danger : AppColors.textPrimary)),
              ],
            ),
          ),
          Icon(icon, size: 18.r, color: bad ? AppColors.danger : AppColors.primary),
        ],
      ),
    );
  }
}
