import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/finance.dart';

abstract interface class CashRepository {
  Future<CashSummary> getSummary();
  Future<List<CashHandover>> getHistory();

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
  @override
  Future<CashSummary> getSummary() async {
    DemoData.ensureEnabled();
    return DemoData.cash;
  }

  @override
  Future<List<CashHandover>> getHistory() async {
    DemoData.ensureEnabled();
    return DemoData.handovers;
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
    return CashHandover(
      id: 'ডেমো',
      amount: amount,
      method: method,
      submittedAt: DateTime.now(),
      status: RequestStatus.pending,
      reference: reference,
    );
  }
}

final cashRepositoryProvider = Provider<CashRepository>((ref) => AppConfig.previewAuth
    ? PreviewCashRepository()
    : ApiCashRepository(ref.watch(sellerSessionProvider).api));
final cashSummaryProvider = FutureProvider.autoDispose((ref) => ref.watch(cashRepositoryProvider).getSummary());
final cashHistoryProvider = FutureProvider.autoDispose((ref) => ref.watch(cashRepositoryProvider).getHistory());

class ApiCashRepository implements CashRepository {
  ApiCashRepository(this.api);
  final ApiClient api;

  Future<Json> _cash() async => jsonMap(await api.get('/seller/cash'));

  CashHandover _handover(Json row) => CashHandover(
    id: row['id'] as String, amount: number(row, 'amount'),
    method: HandoverMethod.values.asNameMap()[row['method']] ?? HandoverMethod.inPerson,
    submittedAt: date(row, 'submitted_at'), status: parseRequest(row['status']),
    reference: row['reference'] as String?,
  );

  @override
  Future<CashSummary> getSummary() async {
    final row = jsonMap((await _cash())['summary']);
    return CashSummary(collected: number(row, 'collected'), verified: number(row, 'verified'),
      pendingVerification: number(row, 'pending_verification'), remaining: number(row, 'to_submit'));
  }

  @override
  Future<List<CashHandover>> getHistory() async =>
      jsonRows((await _cash())['history']).map(_handover).toList();

  @override
  Future<CashHandover> submit({required double amount, required HandoverMethod method, String? reference, String? note}) async =>
      _handover(jsonMap(await api.post('/seller/cash/handovers', {
        'amount': amount, 'method': method == HandoverMethod.inPerson ? 'in_person' : method.name,
        'reference': reference, 'note': note,
      })));
}
