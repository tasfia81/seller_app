import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
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

final cashRepositoryProvider = Provider<CashRepository>((_) => PreviewCashRepository());
final cashSummaryProvider = FutureProvider.autoDispose((ref) => ref.watch(cashRepositoryProvider).getSummary());
final cashHistoryProvider = FutureProvider.autoDispose((ref) => ref.watch(cashRepositoryProvider).getHistory());
