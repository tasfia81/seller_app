import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_text.dart';
import '../../../core/errors/failure.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/image_upload_card.dart';
import '../../../core/widgets/inputs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/inventory.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/commerce_widgets.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../products/data/product_repository_impl.dart';

class StockReturnScreen extends ConsumerStatefulWidget {
  const StockReturnScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<StockReturnScreen> createState() => _StockReturnScreenState();
}

class _StockReturnScreenState extends ConsumerState<StockReturnScreen> {
  Product? _product;
  double _qty = 1;
  ReturnReason? _reason;
  final _note = TextEditingController();
  XFile? _photo;
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _choose(Product p) => setState(() {
        _product = p;
        _qty = p.unit.step.clamp(0, p.availableQty).toDouble();
      });

  Future<void> _pickProduct(List<Product> list) async {
    final p = await showSearchSheet<Product>(context,
        title: 'কোন পণ্য ফেরত দেবেন?', items: list, labelOf: (p) => '${p.name} — ${qtyWithUnit(p.availableQty, p)}');
    if (p != null) _choose(p);
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await ref.read(inventoryRepositoryProvider).submitReturn(StockReturnDraft(
            productId: _product!.id,
            quantity: _qty,
            reason: _reason!,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            photoPath: _photo?.path,
          ));
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showAppSnack(context, failureMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) return _SentView(product: _product!, qty: _qty);
    final products = ref.watch(assignedProductsProvider);
    final canSubmit = _product != null && _qty > 0 && _reason != null;
    return Scaffold(
      appBar: AppBar(title: const Text('স্টক ফেরত')),
      body: AsyncValueView<List<Product>>(
        value: products,
        onRetry: () => ref.invalidate(assignedProductsProvider),
        data: (all) {
          final returnable = all.where((p) => !p.isOutOfStock).toList();
          if (_product == null && widget.productId != null) {
            final m = returnable.where((p) => p.id == widget.productId);
            if (m.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _choose(m.first));
          }
          if (returnable.isEmpty) {
            return const EmptyView(icon: Icons.inventory_2_outlined, title: 'ফেরত দেওয়ার মতো কোনো পণ্য নেই');
          }
          final p = _product;
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(16.r),
            children: [
              PickerField(
                label: 'পণ্য',
                required: true,
                hint: 'পণ্য বাছুন',
                value: p == null ? null : '${p.name} · ${qtyWithUnit(p.availableQty, p)} আছে',
                onTap: () => _pickProduct(returnable),
              ),
              if (p != null) ...[
                SizedBox(height: 16.h),
                FieldLabel('পরিমাণ (${p.unit.label})', required: true),
                QuantityStepper(
                  value: _qty,
                  step: p.unit.step,
                  min: p.unit.step,
                  max: p.availableQty,
                  onChanged: (v) => setState(() => _qty = v),
                ),
              ],
              SizedBox(height: 16.h),
              const FieldLabel('ফেরতের কারণ', required: true),
              ChoicePills<ReturnReason>(
                options: ReturnReason.values,
                selected: _reason,
                labelOf: (r) => r.label,
                onSelected: (r) => setState(() => _reason = r),
              ),
              SizedBox(height: 16.h),
              ImageUploadCard(
                title: _reason == ReturnReason.damaged ? 'ক্ষতির ছবি (ঐচ্ছিক)' : 'ছবি (ঐচ্ছিক)',
                file: _photo,
                onPicked: (f) => setState(() => _photo = f),
                onRemove: () => setState(() => _photo = null),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                label: 'নোট',
                optional: true,
                controller: _note,
                hint: 'যেমন: প্যাকেট ছিঁড়ে গেছে',
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 16.h),
              const InfoBanner(text: 'অ্যাডমিন অনুমোদন না দেওয়া পর্যন্ত এই পণ্য আপনার স্টকেই থাকবে।'),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppButton(label: 'অনুরোধ পাঠান', loading: _sending, onPressed: canSubmit ? _submit : null),
      ),
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.product, required this.qty});
  final Product product;
  final double qty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('স্টক ফেরত')),
      body: ListView(padding: EdgeInsets.all(16.r), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('অনুরোধ পাঠানো হয়েছে', style: AppText.section)),
              StatusChip.request(RequestStatus.pending),
            ]),
            SizedBox(height: 8.h),
            Text('${product.name} · ${qtyWithUnit(qty, product)}', style: AppText.body),
            SizedBox(height: 4.h),
            Text('অ্যাডমিন অনুমোদন দিলে নোটিফিকেশন পাবেন। ততক্ষণ পণ্যটি আপনার স্টকেই দেখাবে।', style: AppText.caption),
          ]),
        ),
        SizedBox(height: 12.h),
        Text('অবস্থাগুলো: ${RequestStatus.values.map((s) => s.label).join(' → ')}',
            style: AppText.small, textAlign: TextAlign.center),
        SizedBox(height: 20.h),
        AppButton(label: 'ঠিক আছে', onPressed: () => Navigator.of(context).maybePop()),
      ]),
    );
  }
}
