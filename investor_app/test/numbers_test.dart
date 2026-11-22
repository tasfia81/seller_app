import 'package:flutter_test/flutter_test.dart';
import 'package:investor_app/core/utils/money.dart';
import 'package:investor_app/data/investor_repository.dart';

void main() {
  const repo = DemoInvestorRepository();

  test('money is shown in Bangla with South-Asian grouping', () {
    expect(tk(450000), '৳৪,৫০,০০০');
    expect(tk(-50000), '−৳৫০,০০০');
    expect(tkSigned(11460), '+৳১১,৪৬০');
  });

  test('every product: sold + with sellers + warehouse + damaged = bought', () {
    for (final h in repo.holdings()) {
      expect(h.sold + h.withSellers + h.inWarehouse + h.damaged, h.bought, reason: h.name);
      expect(h.sellers.fold(0, (s, x) => s + x.inHand), h.withSellers, reason: h.name);
      expect(h.sellers.fold(0, (s, x) => s + x.sold), h.sold, reason: h.name);
    }
  });

  test('product profit shares add up to the total profit', () {
    final total = repo.holdings().fold(0, (s, h) => s + h.investorShare);
    expect(total, repo.summary().totalProfit);
    expect(repo.months().fold(0, (s, m) => s + m.share), repo.summary().totalProfit);
  });

  test('money in stock + not invested = active capital', () {
    final inStock = repo.holdings().fold(0, (s, h) => s + h.invested);
    final summary = repo.summary();
    expect(inStock + summary.uninvested, summary.activeCapital);
  });

  test('seller stock on Home matches the products', () {
    final bySeller = repo.sellers().fold(0, (s, x) => s + x.inHand);
    final byProduct = repo.holdings().fold(0, (s, h) => s + h.withSellers);
    expect(bySeller, byProduct);
  });
}
