import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_data.dart';
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

final dashboardRepositoryProvider = Provider<DashboardRepository>((_) => PreviewDashboardRepository());

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
