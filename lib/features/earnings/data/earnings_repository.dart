import '../../../shared/models/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
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

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) => AppConfig.previewAuth
    ? PreviewEarningsRepository()
    : ApiEarningsRepository(ref.watch(sellerSessionProvider).api));
final earningsSummaryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getSummary());
final earningsHistoryProvider =
    FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getHistory());
final payoutsProvider = FutureProvider.autoDispose((ref) => ref.watch(earningsRepositoryProvider).getPayouts());

class ApiEarningsRepository implements EarningsRepository {
  ApiEarningsRepository(this.api);
  final ApiClient api;

  Future<Json> _earnings() async => jsonMap(await api.get('/seller/earnings'));

  @override
  Future<EarningsSummary> getSummary() async {
    final data = await _earnings();
    final row = jsonMap(data['summary']);
    final model = switch (jsonMap(data['rule'])['model']) {
      'daily' => CompensationModel.dailyWage,
      'per_unit' || 'per_unit_commission' => CompensationModel.perUnitCommission,
      'hybrid' => CompensationModel.hybrid,
      _ => CompensationModel.profitPercentage,
    };
    return EarningsSummary(model: model, ruleText: data['rule_text'] as String,
      today: number(row, 'today'), thisMonth: number(row, 'this_month'),
      pending: number(row, 'pending'), approved: number(row, 'approved'),
      totalPaid: number(row, 'total_paid'), outstanding: number(row, 'outstanding'));
  }

  @override
  Future<List<EarningEntry>> getHistory() async => [
    for (final row in jsonRows((await _earnings())['history']))
      EarningEntry(date: date(row, 'date'), salesCount: number(row, 'sales').toInt(),
        amount: number(row, 'amount'), status: parseRequest(row['status'])),
  ];

  @override
  Future<List<PayoutEntry>> getPayouts() async => [
    for (final row in jsonRows((await _earnings())['payouts']))
      PayoutEntry(date: date(row, 'at'), amount: number(row, 'amount'), method: row['method'] as String),
  ];
}
