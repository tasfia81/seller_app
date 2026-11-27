import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../support/data/support_repository.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/finance.dart';

typedef CashSnapshot = ({CashSummary summary, List<CashHandover> history});

abstract interface class CashRepository {
  Future<CashSnapshot> getCash();

  /// Submits a handover. It stays "pending verification" until an admin
  /// confirms receipt — the app never marks cash as received by itself.
  Future<CashHandover> submit({
    required double amount,
    required HandoverMethod method,
    String? reference,
    String? note,
  });
}

class PreviewCashRepository implements CashRepository {
  final _submitted = <CashHandover>[];

  @override
  Future<CashSnapshot> getCash() async {
    DemoData.ensureEnabled();
    final cash = DemoData.cash;
    final submitted = _submitted.fold<double>(0, (sum, item) => sum + item.amount);
    return (
      summary: CashSummary(
        collected: cash.collected,
        verified: cash.verified,
        pendingVerification: cash.pendingVerification + submitted,
        remaining: (cash.remaining - submitted).clamp(0, double.infinity).toDouble(),
      ),
      history: [..._submitted, ...DemoData.handovers],
    );
  }

  @override
  Future<CashHandover> submit({
    required double amount,
    required HandoverMethod method,
    String? reference,
    String? note,
  }) async {
    DemoData.ensureEnabled();
    if (amount <= 0) throw const ValidationFailure('সঠিক পরিমাণ দিন।');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Preview: recorded as pending verification, never as received.
    final handover = CashHandover(
      id: 'preview-${_submitted.length + 1}',
      amount: amount,
      method: method,
      submittedAt: DateTime.now(),
      status: RequestStatus.pending,
      reference: reference,
    );
    _submitted.insert(0, handover);
    return handover;
  }
}

final cashRepositoryProvider = Provider<CashRepository>((ref) => AppConfig.previewAuth
    ? PreviewCashRepository()
    : ApiCashRepository(ref.watch(sellerSessionProvider).api));
final cashSnapshotProvider = FutureProvider.autoDispose((ref) {
  ref.listen(supportUpdatesProvider, (_, next) {
    if (next.hasValue) ref.invalidateSelf();
  });
  return ref.watch(cashRepositoryProvider).getCash();
});

final cashSummaryProvider = Provider.autoDispose(
  (ref) => ref.watch(cashSnapshotProvider).whenData((cash) => cash.summary),
);

class ApiCashRepository implements CashRepository {
  ApiCashRepository(this.api);
  final ApiClient api;

  CashHandover _handover(Json row) => CashHandover(
    id: row['id'] as String, amount: number(row, 'amount'),
    method: HandoverMethod.values.asNameMap()[row['method']] ?? HandoverMethod.inPerson,
    submittedAt: date(row, 'submitted_at'), status: parseRequest(row['status']),
    reference: row['reference'] as String?,
  );

  @override
  Future<CashSnapshot> getCash() async {
    final cash = jsonMap(await api.get('/seller/cash'));
    final row = jsonMap(cash['summary']);
    return (
      summary: CashSummary(
        collected: number(row, 'collected'),
        verified: number(row, 'verified'),
        pendingVerification: number(row, 'pending_verification'),
        remaining: number(row, 'to_submit'),
      ),
      history: jsonRows(cash['history']).map(_handover).toList(),
    );
  }

  @override
  Future<CashHandover> submit({required double amount, required HandoverMethod method, String? reference, String? note}) async =>
      _handover(jsonMap(await api.post('/seller/cash/handovers', {
        'amount': amount, 'method': method == HandoverMethod.inPerson ? 'in_person' : method.name,
        'reference': reference, 'note': note,
      })));
}
