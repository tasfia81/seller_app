import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../shared/models/finance.dart';

abstract interface class EarningsRepository {
  Future<EarningsSummary> getSummary();
  Future<List<EarningEntry>> getHistory();
  Future<List<PayoutEntry>> getPayouts();
}

class PreviewEarningsRepository implements EarningsRepository {
  @override
  Future<EarningsSummary> getSummary() async {
    DemoData.ensureEnabled();
    return DemoData.earnings;
  }

  @override
  Future<List<EarningEntry>> getHistory() async {
    DemoData.ensureEnabled();
    return DemoData.earningHistory;
  }

  @override
  Future<List<PayoutEntry>> getPayouts() async {
    DemoData.ensureEnabled();
    return DemoData.payouts;
  }
}

final earningsRepositoryProvider = Provider<EarningsRepository>((_) => PreviewEarningsRepository());
final earningsSummaryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getSummary());
final earningsHistoryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getHistory());
final payoutsProvider = FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getPayouts());
