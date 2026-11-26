import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/finance.dart';

abstract interface class DayClosingRepository {
  Future<DayClosingSummary> getToday();
  Future<void> submitClosing();
}

class PreviewDayClosingRepository implements DayClosingRepository {
  @override
  Future<DayClosingSummary> getToday() async {
    DemoData.ensureEnabled();
    return DemoData.dayClosing;
  }

  @override
  Future<void> submitClosing() async => throw const NotConnectedFailure();
}

final dayClosingRepositoryProvider = Provider<DayClosingRepository>((ref) => AppConfig.previewAuth
    ? PreviewDayClosingRepository()
    : ApiDayClosingRepository(ref.watch(sellerSessionProvider).api));
final dayClosingProvider =
    FutureProvider.autoDispose((ref) => ref.watch(dayClosingRepositoryProvider).getToday());

class ApiDayClosingRepository implements DayClosingRepository {
  ApiDayClosingRepository(this.api);
  final ApiClient api;

  @override
  Future<DayClosingSummary> getToday() async {
    final row = jsonMap(await api.get('/seller/day-closing'));
    final sales = jsonMap(row['sales']);
    final stock = jsonMap(row['stock']);
    final earnings = jsonMap(row['earnings']);
    return DayClosingSummary(
      date: date(row, 'date'), totalSales: number(sales, 'total'),
      itemsSold: number(sales, 'quantity').toInt(), cashCollected: number(sales, 'cash'),
      digitalCollected: number(sales, 'digital'), availableStock: number(stock, 'remaining_with_seller'),
      pendingReturns: number(stock, 'pending_returns').toInt(),
      earned: number(earnings, 'commission') + number(earnings, 'daily_wage'),
      policy: parsePolicy(row['policy']), requirements: [
        for (final item in jsonRows(row['requirements']))
          ClosingRequirement(text: item['text'] as String, done: item['done'] == true,
            actionLabel: switch (item['key']) {'cash' => 'ক্যাশ জমা', 'returns' => 'স্টক ফেরত', _ => null},
            route: switch (item['key']) {'cash' => '/cash-handover', 'returns' => '/stock-return', _ => null}),
      ],
    );
  }

  @override
  Future<void> submitClosing() async {
    await api.post('/seller/day-closing/submit');
  }
}
