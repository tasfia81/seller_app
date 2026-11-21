import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../../products/data/product_repository_impl.dart';
import 'quick_sale_controller.dart';

/// The fastest screen in the app: product → quantity → confirm.
class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final _price = TextEditingController();
  bool _initialised = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _select(Product p) {
    ref.read(quickSaleProvider.notifier).selectProduct(p);
    _price.text = ref.read(quickSaleProvider).priceText;
  }

  Future<void> _pickProduct(List<Product> products) async {
    final available = products.where((p) => !p.isOutOfStock).toList();
    final p = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ProductPickerSheet(products: available),
    );
    if (p != null) _select(p);
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    final sale = await ref.read(quickSaleProvider.notifier).submit();
    if (sale != null && mounted) {
      context.pushReplacement(AppRoutes.saleSuccess, extra: sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsValue = ref.watch(assignedProductsProvider);
    final state = ref.watch(quickSaleProvider);
    final ctrl = ref.read(quickSaleProvider.notifier);

    // Preselect the product passed from Products / Product details.
    if (!_initialised && widget.productId != null && productsValue.hasValue) {
      _initialised = true;
      final match = productsValue.value!.where((p) => p.id == widget.productId);
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _select(match.first);
        });
      }
    }

    final p = state.product;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'বন্ধ করুন',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('নতুন বিক্রি'),
      ),
      body: AsyncValueView(
        value: productsValue,
        onRetry: () => ref.invalidate(assignedProductsProvider),
        data: (products) => ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            // 1. Product
            AppCard(
              onTap: () => _pickProduct(products),
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 4.w, 10.h),
              child: Row(children: [
                if (p != null) ProductThumb(product: p, size: 44) else _emptyThumb(),
                SizedBox(width: 12.w),
                Expanded(
                  child: p == null
                      ? Text('পণ্য বাছুন', style: AppText.bodyStrong.copyWith(color: AppColors.primaryDark))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: AppText.bodyStrong),
                          Text('${qtyWithUnit(p.availableQty, p)} আছে', style: AppText.caption),
                        ]),
                ),
                TextButton(
                  onPressed: () => _pickProduct(products),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(p == null ? 'বাছুন' : 'বদলান'),
                ),
              ]),
            ),
            if (p != null) ...[
              if (p.variants.isNotEmpty) ...[
                SizedBox(height: 16.h),
                FieldLabel(p.variantLabel ?? 'ধরন', required: true),
                ChoicePills<String>(
                  options: p.variants,
                  selected: state.variant,
                  labelOf: (v) => v,
                  onSelected: ctrl.setVariant,
                ),
              ],
              SizedBox(height: 16.h),
              FieldLabel('পরিমাণ (${p.unit.label})',
                  trailing: Text('ধাপ ${BnFormat.qty(p.unit.step)}', style: AppText.small)),
              QuantityStepper(
                value: state.quantity,
                step: p.unit.step,
                min: p.unit.step,
                max: p.availableQty,
                onChanged: ctrl.setQuantity,
              ),
              SizedBox(height: 8.h),
              ChoicePills<double>(
                options: p.unit.presets.where((q) => q <= p.availableQty).toList(),
                selected: state.quantity,
                labelOf: (q) => BnFormat.qty(q),
                scrollable: true,
                onSelected: ctrl.setQuantity,
              ),
              SizedBox(height: 16.h),
              FieldLabel('প্রতি ${p.unit.label} দাম',
                  trailing: Text(
                    p.isPriceFlexible
                        ? 'সীমা ${BnFormat.money(p.minPrice!)} – ${BnFormat.money(p.maxPrice!)}'
                        : 'নির্ধারিত দাম',
                    style: AppText.small,
                  )),
              TextField(
                controller: _price,
                readOnly: !p.isPriceFlexible,
                onChanged: ctrl.setPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]'))],
                style: AppText.input.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '৳ ',
                  errorText: state.priceError,
                  filled: true,
                  fillColor: p.isPriceFlexible ? Colors.white : AppColors.background,
                  suffixIcon: p.isPriceFlexible
                      ? null
                      : const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
              SizedBox(height: 16.h),
              const FieldLabel('পেমেন্ট'),
              ChoicePills<PaymentMethod>(
                options: PaymentMethod.values,
                selected: state.payment,
                labelOf: (m) => m.label,
                equalWidth: true,
                onSelected: ctrl.setPayment,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                hint: 'নোট যোগ করুন (ঐচ্ছিক)',
                prefixIcon: Icons.edit_note_rounded,
                onChanged: ctrl.setNote,
                textInputAction: TextInputAction.done,
              ),
              if (state.error != null) ...[
                SizedBox(height: 14.h),
                InfoBanner(
                  tone: BannerTone.error,
                  icon: state.error is NetworkFailure ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  text: state.error is NetworkFailure
                      ? 'বিক্রি নিশ্চিত হয়নি। ইন্টারনেট ঠিক করে আবার "বিক্রি নিশ্চিত করুন" চাপুন — একই বিক্রি দুবার হবে না।'
                      : failureMessage(state.error!),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: p == null
          ? null
          : BottomActionBar(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('মোট টাকা', style: AppText.caption),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(BnFormat.money(state.total), style: AppText.amount(26)),
                      ),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('বিক্রির পর স্টক', style: AppText.caption),
                    Text(
                      qtyWithUnit((p.availableQty - state.quantity).clamp(0, double.infinity), p),
                      style: AppText.bodyStrong,
                    ),
                  ]),
                ]),
                if (state.quantityError != null || state.needsVariant) ...[
                  SizedBox(height: 6.h),
                  Text(
                    state.quantityError ?? '${p.variantLabel ?? 'ধরন'} বাছুন।',
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFFC23B3B)),
                  ),
                ],
                SizedBox(height: 10.h),
                AppButton(
                  label: state.submitting ? 'নিশ্চিত করা হচ্ছে…' : 'বিক্রি নিশ্চিত করুন',
                  loading: state.submitting,
                  onPressed: state.canSubmit ? _confirm : null,
                ),
              ]),
            ),
    );
  }

  Widget _emptyThumb() => Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12.r)),
        child: const Icon(Icons.add_rounded, color: AppColors.primary),
      );
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});
  final List<Product> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.products.where((p) => p.name.contains(_q.trim())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('পণ্য বাছুন', style: AppText.section.copyWith(fontSize: 17.sp)),
              SizedBox(height: 10.h),
              AppSearchField(hint: 'পণ্যের নাম খুঁজুন', onChanged: (v) => setState(() => _q = v)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyView(icon: Icons.search_off_rounded, title: 'স্টকে থাকা কোনো পণ্য মেলেনি')
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return AppCard(
                        onTap: () => Navigator.pop(context, p),
                        padding: EdgeInsets.all(10.r),
                        child: Row(children: [
                          ProductThumb(product: p, size: 44),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: AppText.bodyStrong),
                              Text('${priceWithUnit(p)} · ${qtyWithUnit(p.availableQty, p)} আছে',
                                  style: AppText.caption),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
