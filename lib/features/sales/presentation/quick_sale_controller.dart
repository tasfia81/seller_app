import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/sale.dart';
import '../data/sales_repository_impl.dart';

class QuickSaleState {
  const QuickSaleState({
    this.product,
    this.variant,
    this.quantity = 1,
    this.priceText = '',
    this.payment = PaymentMethod.cash,
    this.note = '',
    this.submitting = false,
    this.error,
  });

  final Product? product;
  final String? variant;
  final double quantity;
  final String priceText;
  final PaymentMethod payment;
  final String note;
  final bool submitting;
  final Object? error;

  double? get unitPrice => double.tryParse(BnFormat.toAscii(priceText).replaceAll(',', ''));
  double get total => (unitPrice ?? 0) * quantity;

  String? get priceError {
    final p = product;
    final price = unitPrice;
    if (p == null) return null;
    if (price == null || price <= 0) return 'সঠিক দাম দিন।';
    if (p.isPriceFlexible && (price < p.minPrice! || price > p.maxPrice!)) {
      return 'দাম ${BnFormat.money(p.minPrice!)} থেকে ${BnFormat.money(p.maxPrice!)} এর মধ্যে হতে হবে।';
    }
    return null;
  }

  double get availableQty => product?.stockFor(variant) ?? 0;

  String? get quantityError {
    final p = product;
    if (p == null) return null;
    if (quantity <= 0) return 'পরিমাণ দিন।';
    if (quantity > availableQty) {
      return 'পর্যাপ্ত স্টক নেই। হাতে আছে ${BnFormat.qty(availableQty)} ${p.unit.label}।';
    }
    return null;
  }

  bool get needsVariant => (product?.variants.isNotEmpty ?? false) && variant == null;

  bool get canSubmit =>
      product != null && !submitting && priceError == null && quantityError == null && !needsVariant && product!.paymentMethods.contains(payment);

  QuickSaleState copyWith({
    Product? product,
    String? variant,
    bool clearVariant = false,
    double? quantity,
    String? priceText,
    PaymentMethod? payment,
    String? note,
    bool? submitting,
    Object? error,
    bool clearError = false,
  }) =>
      QuickSaleState(
        product: product ?? this.product,
        variant: clearVariant ? null : (variant ?? this.variant),
        quantity: quantity ?? this.quantity,
        priceText: priceText ?? this.priceText,
        payment: payment ?? this.payment,
        note: note ?? this.note,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class QuickSaleController extends AutoDisposeNotifier<QuickSaleState> {
  // One idempotency key per sale attempt; reused on retry so the server
  // never records the same sale twice.
  String _requestId = _newId();

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7FFFFFFF).toRadixString(16)}';

  @override
  QuickSaleState build() => const QuickSaleState();

  void selectProduct(Product p) {
    state = QuickSaleState(
      product: p,
      variant: p.variants.length == 1 ? p.variants.first : null,
      quantity: p.unit.presets.first.clamp(0, max(p.availableQty, p.unit.step)).toDouble(),
      priceText: BnFormat.number(p.price, decimals: 2).replaceAll(',', ''),
      payment: p.paymentMethods.contains(state.payment) ? state.payment :
          p.paymentMethods.firstOrNull ?? PaymentMethod.cash,
    );
    _requestId = _newId();
  }

  void setVariant(String v) {
    final stock = state.product?.stockFor(v) ?? 0;
    state = state.copyWith(variant: v, quantity: min(state.quantity, stock), clearError: true);
  }
  void setQuantity(double q) => state = state.copyWith(quantity: q, clearError: true);
  void setPrice(String text) => state = state.copyWith(priceText: text, clearError: true);
  void setPayment(PaymentMethod m) => state = state.copyWith(payment: m);
  void setNote(String n) => state = state.copyWith(note: n);

  /// Returns the server-confirmed sale, or null on failure (error in state).
  Future<Sale?> submit() async {
    final s = state;
    if (!s.canSubmit) return null;
    state = s.copyWith(submitting: true, clearError: true);
    try {
      final sale = await ref.read(salesRepositoryProvider).submitSale(SaleDraft(
            productId: s.product!.id,
            variant: s.variant,
            quantity: s.quantity,
            unitPrice: s.unitPrice!,
            payment: s.payment,
            note: s.note.trim().isEmpty ? null : s.note.trim(),
            clientRequestId: _requestId,
          ));
      _requestId = _newId();
      state = state.copyWith(submitting: false);
      return sale;
    } on Failure catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return null;
    } catch (_) {
      state = state.copyWith(submitting: false, error: const UnknownFailure());
      return null;
    }
  }
}

final quickSaleProvider =
    AutoDisposeNotifierProvider<QuickSaleController, QuickSaleState>(QuickSaleController.new);
