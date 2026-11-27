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
import '../../../shared/models/sale.dart';
import '../data/pending_sale_store.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../../products/data/product_repository_impl.dart';
import '../../home/data/dashboard_repository.dart';
import 'sales_history_screen.dart';
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
  bool _checked = false;
  bool _changingProduct = false;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _select(Product p) {
    ref.read(quickSaleProvider.notifier).selectProduct(p);
    _price.text = ref.read(quickSaleProvider).priceText;
  }

  void _chooseProduct(Product product) {
    FocusScope.of(context).unfocus();
    if (ref.read(quickSaleProvider).product?.id != product.id) _select(product);
    setState(() => _changingProduct = false);
  }

  bool _showConfirmed(Sale sale) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    ref.invalidate(homeDataProvider);
    ref.invalidate(assignedProductsProvider);
    ref.invalidate(salesListProvider);
    context.pushReplacement(AppRoutes.saleSuccess, extra: sale);
    return true;
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    await ref.read(quickSaleProvider.notifier).submit(_showConfirmed);
  }

  Future<void> _recover({required bool resend}) async {
    setState(() => _checked = false);
    await ref.read(quickSaleProvider.notifier).recover(
      resend: resend,
      onConfirmed: _showConfirmed,
    );
    if (!mounted) return;
    setState(() => _checked = !resend && ref.read(quickSaleProvider).error == null);
  }

  Widget _recovery(PendingSale pending, QuickSaleState state) {
    final draft = pending.draft;
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        InfoBanner(
          tone: BannerTone.warning,
          icon: Icons.sync_problem_rounded,
          text: state.submitting
              ? 'বিক্রির তথ্য সার্ভারে দেখা হচ্ছে…'
              : _checked
                  ? 'সার্ভারে বিক্রিটি এখনো দেখা যাচ্ছে না। একই তথ্য আবার পাঠাতে পারেন।'
                  : 'আগের বিক্রির অবস্থা যাচাই করুন। ফর্ম বন্ধ করলেও এই তথ্য এই ফোনে থাকবে।',
        ),
        SizedBox(height: 12.h),
        AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pending.productName, style: AppText.bodyStrong),
            SizedBox(height: 6.h),
            Text([
              if (draft.variant != null) draft.variant!,
              '${BnFormat.qty(draft.quantity)} ${pending.unit.label}',
              draft.payment.label,
            ].join(' · '), style: AppText.caption),
            SizedBox(height: 6.h),
            Text(BnFormat.money(draft.quantity * draft.unitPrice), style: AppText.amount(22)),
          ]),
        ),
        if (state.error != null) ...[
          SizedBox(height: 12.h),
          InfoBanner(
            tone: BannerTone.error,
            icon: Icons.info_outline,
            text: failureMessage(state.error!),
          ),
        ],
        SizedBox(height: 16.h),
        AppButton(
          label: _checked ? 'একই বিক্রি আবার পাঠান' : 'বিক্রির অবস্থা যাচাই করুন',
          loading: state.submitting,
          onPressed: state.submitting ? null : () => _recover(resend: _checked),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingValue = ref.watch(pendingSaleProvider);
    final pending = pendingValue.valueOrNull;
    final productsValue = ref.watch(assignedProductsProvider);
    final state = ref.watch(quickSaleProvider);
    final ctrl = ref.read(quickSaleProvider.notifier);

    // Preselect the product passed from Products / Product details.
    if (pendingValue.hasValue && pending == null && !_initialised && widget.productId != null && productsValue.hasValue) {
      _initialised = true;
      final match = productsValue.value!.where((p) => p.id == widget.productId && !p.isOutOfStock);
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
      body: pending != null
          ? _recovery(pending, state)
          : !pendingValue.hasValue
              ? AsyncValueView(
                  value: pendingValue,
                  onRetry: () => ref.invalidate(pendingSaleProvider),
                  data: (_) => const SizedBox.shrink(),
                )
              : AsyncValueView(
        value: productsValue,
        onRetry: () => ref.invalidate(assignedProductsProvider),
        data: (products) => p == null || _changingProduct
            ? _ProductList(
                products: products.where((product) => !product.isOutOfStock).toList(),
                onSelected: _chooseProduct,
                onCancel: p == null ? null : () => setState(() => _changingProduct = false),
              )
            : ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            // 1. Product
            AppCard(
              onTap: () => setState(() => _changingProduct = true),
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 4.w, 10.h),
              child: Row(children: [
                ProductThumb(product: p, size: 44),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: AppText.bodyStrong),
                    Text('${qtyWithUnit(p.availableQty, p)} আছে', style: AppText.caption),
                  ]),
                ),
                TextButton(
                  onPressed: () => setState(() => _changingProduct = true),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('বদলান'),
                ),
              ]),
            ),
            ...[
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
                max: state.availableQty,
                onChanged: ctrl.setQuantity,
              ),
              SizedBox(height: 8.h),
              ChoicePills<double>(
                options: p.unit.presets.where((q) => q <= state.availableQty).toList(),
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
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 6.w),
                    child: Text('৳', style: AppText.input.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
                options: p.paymentMethods,
                selected: state.payment,
                labelOf: (m) => m.label,
                equalWidth: true,
                onSelected: ctrl.setPayment,
              ),
              SizedBox(height: 16.h),
              AppTextField(
                hint: 'নোট যোগ করুন (ঐচ্ছিক)',
                initialValue: state.note,
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
      bottomNavigationBar: p == null || _changingProduct || !pendingValue.hasValue || pending != null
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
                      qtyWithUnit((state.availableQty - state.quantity).clamp(0, double.infinity), p),
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

}

class _ProductList extends StatefulWidget {
  const _ProductList({required this.products, required this.onSelected, this.onCancel});
  final List<Product> products;
  final ValueChanged<Product> onSelected;
  final VoidCallback? onCancel;

  @override
  State<_ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<_ProductList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final products = widget.products.where((p) => p.name.toLowerCase().contains(query)).toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
          child: Row(children: [
            Expanded(
              child: AppSearchField(
                hint: 'পণ্যের নাম খুঁজুন',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (widget.onCancel != null)
              TextButton(onPressed: widget.onCancel, child: const Text('বাতিল')),
          ]),
        ),
        Expanded(
          child: products.isEmpty
              ? EmptyView(
                  icon: Icons.search_off_rounded,
                  title: widget.products.isEmpty
                      ? 'বিক্রির জন্য স্টকে কোনো পণ্য নেই'
                      : 'এই নামে কোনো পণ্য মেলেনি',
                )
              : ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) {
                    final product = products[index];
                    return AppCard(
                      onTap: () => widget.onSelected(product),
                      padding: EdgeInsets.all(12.r),
                      child: Row(children: [
                        ProductThumb(product: product, size: 44),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(product.name, style: AppText.bodyStrong),
                            Text('${priceWithUnit(product)} · ${qtyWithUnit(product.availableQty, product)} আছে',
                                style: AppText.caption),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
