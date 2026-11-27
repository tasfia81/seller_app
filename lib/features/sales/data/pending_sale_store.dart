import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_config.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/sale.dart';
import '../../auth/data/seller_session.dart';

class PendingSale {
  const PendingSale(this.draft, this.productName, this.unit);

  final SaleDraft draft;
  final String productName;
  final UnitType unit;

  factory PendingSale.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return PendingSale(
      SaleDraft(
        productId: json['productId'] as String,
        variant: json['variant'] as String?,
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        payment: PaymentMethod.values.byName(json['payment'] as String),
        note: json['note'] as String?,
        clientRequestId: json['requestId'] as String,
      ),
      json['productName'] as String,
      UnitType.values.byName(json['unit'] as String),
    );
  }

  String encode() => jsonEncode({
        'productId': draft.productId,
        'productName': productName,
        'unit': unit.name,
        'variant': draft.variant,
        'quantity': draft.quantity,
        'unitPrice': draft.unitPrice,
        'payment': draft.payment.name,
        'note': draft.note,
        'requestId': draft.clientRequestId,
      });
}

class PendingSaleStore {
  const PendingSaleStore(this._key);

  final String _key;
  static const _storage = FlutterSecureStorage();

  Future<PendingSale?> read() async {
    final value = await _storage.read(key: _key);
    return value == null ? null : PendingSale.decode(value);
  }

  Future<void> save(PendingSale pending) =>
      _storage.write(key: _key, value: pending.encode());

  Future<void> clear() => _storage.delete(key: _key);
}

final pendingSaleStoreProvider = Provider.autoDispose((ref) {
  final id = AppConfig.previewAuth
      ? 'preview'
      : ref.watch(sellerSessionProvider).user?['id'];
  if (id == null) throw StateError('Missing seller session');
  return PendingSaleStore('pending-sale|${AppConfig.apiBaseUrl}|$id');
});

final pendingSaleProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(pendingSaleStoreProvider).read(),
);
