import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../core/utils/bn_format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_chip.dart';
import '../models/enums.dart';
import '../models/product.dart';
import '../models/sale.dart';

IconData categoryIcon(String category) => switch (category) {
      'জার্সি' || 'টি-শার্ট' => Icons.checkroom_rounded,
      'প্যান্ট' => Icons.dry_cleaning_outlined,
      'অ্যাক্সেসরিজ' => Icons.shopping_bag_outlined,
      _ => Icons.inventory_2_outlined,
    };

/// Product image or category icon placeholder.
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, this.size = 52, this.muted = false});

  final Product product;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final s = size.r;
    return Container(
      width: s,
      height: s,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: muted ? AppColors.neutralSoft : AppColors.mint,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: product.imageUrl != null
          ? Image.network(product.imageUrl!, fit: BoxFit.cover, cacheWidth: 200,
              errorBuilder: (_, __, ___) => _icon())
          : _icon(),
    );
  }

  Widget _icon() => Icon(categoryIcon(product.category),
      color: muted ? AppColors.disabledText : AppColors.primary, size: size.r * 0.5);
}

String priceWithUnit(Product p) => '${BnFormat.money(p.price)} / ${p.unit.label}';
String qtyWithUnit(num q, Product p) => '${BnFormat.qty(q)} ${p.unit.label}';

class SaleCard extends StatelessWidget {
  const SaleCard({super.key, required this.sale, this.onTap});

  final Sale sale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pending = sale.status == SaleStatus.pendingSync;
    return AppCard(
      onTap: onTap,
      borderColor: pending ? AppColors.warningBorder : AppColors.border,
      padding: EdgeInsets.all(12.r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(
              '${sale.productName}${sale.variant == null ? '' : ' (${sale.variant})'} · ${BnFormat.qty(sale.quantity)} ${sale.unit.label}',
              style: AppText.bodyStrong,
            ),
          ),
          SizedBox(width: 8.w),
          Text(BnFormat.money(sale.total), style: AppText.amount(15)),
        ]),
        SizedBox(height: 6.h),
        Row(children: [
          Expanded(
            child: Text(
              [if (!pending) '#${sale.id}', BnFormat.time(sale.time), sale.payment.label].join(' · '),
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusChip.sale(sale.status),
        ]),
        if (pending) ...[
          SizedBox(height: 4.h),
          Text('ইন্টারনেট ফিরলে নিজে থেকে পাঠানো হবে', style: AppText.small.copyWith(color: AppColors.warningText)),
        ],
      ]),
    );
  }
}
