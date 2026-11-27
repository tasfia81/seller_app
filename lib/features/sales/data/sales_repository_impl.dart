import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/bn_format.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/sale.dart';
import '../domain/sales_repository.dart';

class PreviewSalesRepository implements SalesRepository {
  @override
  Future<List<Sale>> getSales({required SalesPeriod period, DateTime? from, DateTime? to}) async {
    DemoData.ensureEnabled();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool inRange(DateTime t) => switch (period) {
          SalesPeriod.today => !t.isBefore(today),
          SalesPeriod.yesterday => t.isBefore(today) && !t.isBefore(today.subtract(const Duration(days: 1))),
          SalesPeriod.last7Days => !t.isBefore(today.subtract(const Duration(days: 6))),
          SalesPeriod.custom => (from == null || !t.isBefore(from)) &&
              (to == null || t.isBefore(to.add(const Duration(days: 1)))),
        };
    return DemoData.sales.where((s) => inRange(s.time)).toList();
  }

  @override
  Future<Sale> getSale(String id) async {
    DemoData.ensureEnabled();
    return DemoData.sales.firstWhere((s) => s.id == id,
        orElse: () => throw const ValidationFailure('বিক্রিটি পাওয়া যায়নি।'));
  }

  @override
  Future<Sale?> checkAttempt(String requestId) async => null;

  @override
  Future<Sale> submitSale(SaleDraft draft) async {
    DemoData.ensureEnabled();
    final product = DemoData.products.firstWhere((p) => p.id == draft.productId);
    if (draft.quantity > product.availableQty) {
      throw InsufficientStockFailure('${BnFormat.qty(product.availableQty)} ${product.unit.label}');
    }
    // Preview only: echoes the draft back so the success screen can be seen.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return Sale(
      id: 'ডেমো-${BnFormat.digits('${DateTime.now().millisecondsSinceEpoch % 100000}')}',
      productId: product.id,
      productName: product.name,
      variant: draft.variant,
      quantity: draft.quantity,
      unit: product.unit,
      unitPrice: draft.unitPrice,
      payment: draft.payment,
      time: DateTime.now(),
      status: SaleStatus.confirmed,
      note: draft.note,
    );
  }

  @override
  Future<void> requestCorrection(String saleId, String reason) async {
    DemoData.ensureEnabled();
    throw const NotConnectedFailure();
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) => AppConfig.previewAuth
    ? PreviewSalesRepository()
    : ApiSalesRepository(ref.watch(sellerSessionProvider).api));

class ApiSalesRepository implements SalesRepository {
  ApiSalesRepository(this.api);
  final ApiClient api;

  @override
  Future<List<Sale>> getSales({required SalesPeriod period, DateTime? from, DateTime? to}) async {
    final query = Uri(queryParameters: {
      'period': period == SalesPeriod.last7Days ? 'last7' : period.name,
      if (from != null) 'date_from': dateParam(from),
      if (to != null) 'date_to': dateParam(to),
    }).query;
    return jsonRows(jsonMap(await api.get('/seller/sales?$query'))['items']).map(parseSale).toList();
  }

  @override
  Future<Sale> getSale(String id) async =>
      parseSale(jsonMap(await api.get('/seller/sales/${Uri.encodeComponent(id)}')));

  @override
  Future<Sale?> checkAttempt(String requestId) async {
    final response = await api.get('/seller/sales/attempts/${Uri.encodeComponent(requestId)}');
    if (response is! Map || !response.containsKey('sale')) {
      throw const ApiException('বিক্রির অবস্থা যাচাই করা যায়নি।');
    }
    final sale = response['sale'];
    return sale == null ? null : parseSale(jsonMap(sale));
  }

  @override
  Future<Sale> submitSale(SaleDraft draft) async => parseSale(jsonMap(await api.post('/seller/sales', {
        'product_id': draft.productId,
        'quantity': draft.quantity,
        'unit_price': draft.unitPrice,
        'payment': draft.payment.name,
        'variant': draft.variant,
        'note': draft.note,
        'client_request_id': draft.clientRequestId,
      })));

  @override
  Future<void> requestCorrection(String saleId, String reason) async {
    await api.post('/seller/sales/${Uri.encodeComponent(saleId)}/corrections', {'reason': reason});
  }
}
