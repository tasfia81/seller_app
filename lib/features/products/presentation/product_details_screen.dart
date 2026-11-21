import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../data/product_repository_impl.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(productProvider(productId));
    final product = value.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('পণ্যের বিস্তারিত')),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(productProvider(productId)),
        data: (p) => ListView(
          children: [
            Container(
              height: 200.h,
              color: AppColors.mint,
              alignment: Alignment.center,
              child: p.imageUrl != null
                  ? Image.network(p.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Icon(categoryIcon(p.category), size: 64, color: const Color(0xFF8FB5A0)),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StatusChip(p.category),
                SizedBox(height: 8.h),
                Text(p.name, style: AppText.pageTitle.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w700)),
                SizedBox(height: 4.h),
                Text.rich(TextSpan(children: [
                  TextSpan(text: BnFormat.money(p.price), style: AppText.amount(26, color: AppColors.successText)),
                  TextSpan(text: ' / ${p.unit.label}', style: AppText.body.copyWith(color: AppColors.textSecondary)),
                ])),
                if (p.variants.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(p.variantLabel ?? 'ধরন', style: AppText.caption),
                  SizedBox(height: 6.h),
                  Wrap(spacing: 8.w, runSpacing: 8.h, children: [
                    for (final v in p.variants)
                      Container(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.inputBorder),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(v, style: AppText.label),
                      ),
                  ]),
                ],
                SizedBox(height: 14.h),
                AppCard(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                  child: Column(children: [
                    KeyValueRow('হাতে থাকা স্টক', qtyWithUnit(p.availableQty, p),
                        valueColor: p.isOutOfStock ? AppColors.errorText : null),
                    KeyValueRow('ইউনিট', p.unit.label),
                    KeyValueRow(
                      'দাম',
                      p.isPriceFlexible
                          ? 'বদলানো যাবে · ${BnFormat.money(p.minPrice!)} – ${BnFormat.money(p.maxPrice!)}'
                          : 'নির্ধারিত, বদলানো যাবে না',
                      divider: false,
                    ),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: product == null
          ? null
          : BottomActionBar(
              child: Row(children: [
                Expanded(
                  child: AppButton(
                    label: 'স্টকের হিসাব',
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.inventory),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppButton(
                    label: 'বিক্রি করুন',
                    onPressed: product.isOutOfStock ? null : () => context.push(AppRoutes.newSale(productId: product.id)),
                  ),
                ),
              ]),
            ),
    );
  }
}
