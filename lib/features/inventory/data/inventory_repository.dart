import '../../../shared/models/enums.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
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

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => AppConfig.previewAuth
    ? PreviewInventoryRepository()
    : ApiInventoryRepository(ref.watch(sellerSessionProvider).api));
final inventorySummaryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(inventoryRepositoryProvider).getSummary());
final stockMovementsProvider =
    FutureProvider.autoDispose((ref) => ref.watch(inventoryRepositoryProvider).getMovements());

class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository(this.api);
  final ApiClient api;
  final _pendingPhotos = <String, String>{};

  Future<Json> _inventory() async => jsonMap(await api.get('/seller/inventory'));

  @override
  Future<InventorySummary> getSummary() async {
    final row = await _inventory();
    return InventorySummary(policy: parsePolicy(row['policy']), totalAssigned: number(row, 'total_assigned'),
      sold: number(row, 'sold'), available: number(row, 'available'), pendingReturn: number(row, 'pending_return'),
      damaged: number(row, 'damaged'), disputed: number(row, 'disputed'));
  }

  @override
  Future<List<StockMovement>> getMovements() async => [
    for (final row in jsonRows((await _inventory())['movements']))
      StockMovement(
        kind: switch (row['kind']) {
          'sale' => MovementKind.sold, 'return' => MovementKind.returned,
          'damage' || 'damaged' => MovementKind.damaged,
          _ => MovementKind.assigned,
        },
        title: row['product_name'] as String, subtitle: '${row['qty']} · ${row['ref']}',
        time: date(row, 'at'),
      ),
  ];

  @override
  Future<void> submitReturn(StockReturnDraft draft) async {
    final photo = draft.photoPath;
    final bytes = photo == null ? null : await XFile(photo).readAsBytes();
    final key = [draft.productId, draft.variant, draft.quantity, draft.reason, draft.note].join('|');
    var id = _pendingPhotos[key];
    if (id == null) {
      final row = jsonMap(await api.post('/seller/returns', {
        'product_id': draft.productId, 'variant': draft.variant, 'quantity': draft.quantity,
        'reason': draft.reason == ReturnReason.endOfDay ? 'end_of_day' : draft.reason.name,
        'note': draft.note,
      }));
      id = row['id'] as String;
    }
    if (bytes != null) {
      _pendingPhotos[key] = id;
      await api.upload('/seller/returns/$id/photo', bytes, name: 'return');
    }
    _pendingPhotos.remove(key);
  }
}

final pendingAssignmentsProvider = FutureProvider.autoDispose<List<Json>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  if (repository is! ApiInventoryRepository) return [];
  return jsonRows(await repository.api.get('/seller/assignments?status=pending_handover'));
});
