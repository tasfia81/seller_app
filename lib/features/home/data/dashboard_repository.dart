import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/seller_payload.dart';
import '../../../core/constants/app_config.dart';
import '../../auth/data/seller_session.dart';
import '../../../shared/models/finance.dart';
import '../../../shared/models/sale.dart';
import '../../../shared/models/seller.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary();
  Future<List<Sale>> getRecentSales();
  Future<SellerProfile> getSeller();
}

class PreviewDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async {
    DemoData.ensureEnabled();
    return DemoData.dashboard;
  }

  @override
  Future<List<Sale>> getRecentSales() async {
    DemoData.ensureEnabled();
    return DemoData.sales.take(3).toList();
  }

  @override
  Future<SellerProfile> getSeller() async {
    DemoData.ensureEnabled();
    return DemoData.profile;
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => AppConfig.previewAuth
    ? PreviewDashboardRepository()
    : ApiDashboardRepository(ref.watch(sellerSessionProvider).api));

class HomeData {
  const HomeData(this.summary, this.recent, this.seller);
  final DashboardSummary summary;
  final List<Sale> recent;
  final SellerProfile seller;
}

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final results = await Future.wait([repo.getSummary(), repo.getRecentSales(), repo.getSeller()]);
  return HomeData(
    results[0] as DashboardSummary,
    results[1] as List<Sale>,
    results[2] as SellerProfile,
  );
});

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this.api);
  final ApiClient api;

  Future<Json> _dashboard() async => jsonMap(await api.get('/seller/dashboard'));

  @override
  Future<DashboardSummary> getSummary() async {
    final row = await _dashboard();
    return DashboardSummary(
      todaySales: number(row, 'today_sales'),
      salesCount: number(row, 'sales_count').toInt(),
      itemsSold: number(row, 'items_sold').toInt(),
      todayEarnings: number(row, 'today_earnings'),
      availableStock: number(row, 'available_stock'),
      cashToSubmit: number(row, 'cash_to_submit'),
      unreadNotifications: number(row, 'unread_notifications').toInt(),
      lastSaleAt: row['last_sale_at'] == null ? null : date(row, 'last_sale_at'),
      lowStockNames: List<String>.from(row['low_stock'] as List),
    );
  }

  @override
  Future<List<Sale>> getRecentSales() async =>
      jsonRows((await _dashboard())['recent_sales']).map(parseSale).toList();

  @override
  Future<SellerProfile> getSeller() async => parseProfile(jsonMap(await api.get('/seller/profile')));
}
