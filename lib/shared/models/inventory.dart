import 'enums.dart';

class InventorySummary {
  const InventorySummary({
    required this.policy,
    required this.totalAssigned,
    required this.sold,
    required this.available,
    required this.pendingReturn,
    required this.damaged,
    required this.disputed,
  });

  final InventoryPolicy policy;
  final double totalAssigned;
  final double sold;
  final double available;
  final double pendingReturn;
  final double damaged;
  final double disputed;
}

enum MovementKind { assigned, sold, returnRequested, returned, damaged }

class StockMovement {
  const StockMovement({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final MovementKind kind;
  final String title;
  final String subtitle;
  final DateTime time;
}

class StockReturnDraft {
  const StockReturnDraft({
    required this.productId,
    required this.quantity,
    required this.reason,
    this.note,
    this.photoPath,
  });

  final String productId;
  final double quantity;
  final ReturnReason reason;
  final String? note;
  final String? photoPath;
}
