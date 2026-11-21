import '../../../shared/models/sale.dart';

abstract interface class SalesRepository {
  Future<List<Sale>> getSales({required SalesPeriod period, DateTime? from, DateTime? to});
  Future<Sale> getSale(String id);

  /// Sends the sale to the server. Returns the confirmed sale only after
  /// server-side validation; throws [InsufficientStockFailure],
  /// [NetworkFailure] etc. otherwise.
  Future<Sale> submitSale(SaleDraft draft);

  Future<void> requestCorrection(String saleId, String reason);
}
