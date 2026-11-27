import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/presentation/pending_stock.dart';
import '../data/product_repository_impl.dart';

enum _StockFilter { all, inStock, out }

class MyProductsScreen extends ConsumerStatefulWidget {
  const MyProductsScreen({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  String _query = '';
  String _category = 'সব';
  _StockFilter _stock = _StockFilter.all;

  List<Product> _filter(List<Product> all) => all.where((p) {
        if (_category != 'সব' && p.category != _category) return false;
        if (_stock == _StockFilter.inStock && p.isOutOfStock) return false;
        if (_stock == _StockFilter.out && !p.isOutOfStock) return false;
        return _query.isEmpty || p.name.contains(_query.trim());
      }).toList();

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(assignedProductsProvider);
    return Scaffold(
      appBar: AppBar(titleSpacing: 16.w, title: const Text('আমার পণ্য')),
      body: AsyncValueView(
        value: value,
        onRetry: () => ref.invalidate(assignedProductsProvider),
        data: (all) {
          final categories = ['সব', ...{for (final p in all) p.category}];
          final list = _filter(all);
          final inStock = all.where((p) => !p.isOutOfStock).length;
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(assignedProductsProvider.future),
                ref.refresh(pendingAssignmentsProvider.future),
              ]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                sliver: const SliverToBoxAdapter(child: PendingStock()),
              ),
              if (all.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                sliver: SliverList.list(children: [
                  AppSearchField(hint: 'পণ্যের নাম খুঁজুন', onChanged: (v) => setState(() => _query = v)),
                  SizedBox(height: 10.h),
                  ChoicePills<String>(
                    options: categories,
                    selected: _category,
                    labelOf: (c) => c,
                    style: PillStyle.filter,
                    scrollable: true,
                    onSelected: (c) => setState(() => _category = c),
                  ),
                  SizedBox(height: 8.h),
                  ChoicePills<_StockFilter>(
                    options: _StockFilter.values,
                    selected: _stock,
                    scrollable: true,
                    labelOf: (f) => switch (f) {
                      _StockFilter.all => 'সব স্টক',
                      _StockFilter.inStock => 'স্টকে আছে ${BnFormat.digits('$inStock')}',
                      _StockFilter.out => 'স্টক শেষ ${BnFormat.digits('${all.length - inStock}')}',
                    },
                    onSelected: (f) => setState(() => _stock = f),
                  ),
                ]),
              ),
              if (all.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(icon: Icons.inventory_2_outlined, title: 'বিক্রির জন্য এখনো কোনো পণ্য নেই',
                    message: 'বরাদ্দ করা স্টক গ্রহণ করলে এখানে দেখা যাবে।'),
                )
              else if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(icon: Icons.search_off_rounded, title: 'কোনো পণ্য মেলেনি', message: 'অন্য নাম বা ফিল্টার দিয়ে খুঁজুন।'),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) => ProductTile(product: list[i]),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Opacity(
      opacity: p.isOutOfStock ? 0.75 : 1,
      child: AppCard(
        onTap: () => context.push(AppRoutes.product(p.id)),
        padding: EdgeInsets.all(12.r),
        child: Row(children: [
          ProductThumb(product: p, muted: p.isOutOfStock),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: AppText.bodyStrong.copyWith(fontSize: 15.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              if (p.isOutOfStock)
                const StatusChip('স্টক শেষ', tone: ChipTone.error)
              else if (p.isLowStock)
                StatusChip('কম স্টক · ${qtyWithUnit(p.availableQty, p)}', tone: ChipTone.warning)
              else
                Text(
                  '${p.variants.isEmpty ? '' : '${p.variantLabel ?? 'ধরন'}: ${p.variants.join(', ')} · '}${qtyWithUnit(p.availableQty, p)} আছে',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 2.h),
              Text(priceWithUnit(p), style: AppText.amount(15)),
            ]),
          ),
          SizedBox(width: 8.w),
          AppButton(
            label: 'বিক্রি',
            compact: true,
            expanded: false,
            onPressed: p.isOutOfStock ? null : () => context.push(AppRoutes.newSale(productId: p.id)),
          ),
        ]),
      ),
    );
  }
}
