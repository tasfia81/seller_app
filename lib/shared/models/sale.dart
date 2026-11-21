import 'enums.dart';

class Sale {
  const Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.payment,
    required this.time,
    required this.status,
    this.variant,
    this.note,
  });

  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final UnitType unit;
  final double unitPrice;
  final PaymentMethod payment;
  final DateTime time;
  final SaleStatus status;
  final String? variant;
  final String? note;

  double get total => quantity * unitPrice;
}

/// What the seller submits. The server validates stock and price limits and
/// answers with a confirmed [Sale].
class SaleDraft {
  const SaleDraft({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.payment,
    this.variant,
    this.note,
    required this.clientRequestId,
  });

  final String productId;
  final double quantity;
  final double unitPrice;
  final PaymentMethod payment;
  final String? variant;
  final String? note;

  /// Idempotency key so a retried request never records a sale twice.
  final String clientRequestId;
}

enum SalesPeriod {
  today('আজ'),
  yesterday('গতকাল'),
  last7Days('৭ দিন'),
  custom('তারিখ');

  const SalesPeriod(this.label);
  final String label;
}
