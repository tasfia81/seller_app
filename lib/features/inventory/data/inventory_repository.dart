import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/inventory.dart';

abstract interface class InventoryRepository {
  Future<InventorySummary> getSummary();
  Future<List<StockMovement>> getMovements();

  /// Creates a PENDING return request. Stock is not moved until an admin
  /// approves and completes it.
  Future<void> submitReturn(StockReturnDraft draft);
}

class PreviewInventoryRepository implements InventoryRepository {
  @override
  Future<InventorySummary> getSummary() async {
    DemoData.ensureEnabled();
    return DemoData.inventory;
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    DemoData.ensureEnabled();
    return DemoData.movements;
  }

  @override
  Future<void> submitReturn(StockReturnDraft draft) async {
    DemoData.ensureEnabled();
    if (draft.quantity <= 0) throw const ValidationFailure('পরিমাণ দিন।');
    // Preview: the request is accepted as PENDING only; no stock moves.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((_) => PreviewInventoryRepository());
final inventorySummaryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(inventoryRepositoryProvider).getSummary());
final stockMovementsProvider =
    FutureProvider.autoDispose((ref) => ref.watch(inventoryRepositoryProvider).getMovements());
