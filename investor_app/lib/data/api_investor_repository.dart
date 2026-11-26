import '../core/api/api_client.dart';
import '../core/utils/bn_format.dart';
import 'models.dart';

typedef _Json = Map<String, dynamic>;
_Json _map(dynamic value) => Map<String, dynamic>.from(value as Map);
Iterable<_Json> _rows(dynamic value) => (value as List).map(_map);
int _amount(_Json row, String key) => (row[key] as num?)?.round() ?? 0;
String _text(_Json row, String key) => row[key] as String? ?? '—';

class ApiInvestorRepository {
  ApiInvestorRepository(this.api);
  final ApiClient api;

  Future<PortfolioSummary> summary() async {
    final row = _map(await api.get('/investor/dashboard'));
    final today = _map(row['today']);
    final terms = _map(row['terms']);
    final joined = DateTime.tryParse(row['joined_at'] as String? ?? '');
    final now = DateTime.now();
    return PortfolioSummary(
      investorName: _text(row, 'name'),
      totalInvested: _amount(row, 'invested'), withdrawn: _amount(row, 'withdrawn'),
      totalProfit: _amount(row, 'profit_total'), profitPaid: _amount(row, 'profit_paid'),
      profitPaidTimes: _amount(row, 'profit_paid_count'), profitThisMonth: _amount(row, 'profit_this_month'),
      nextPayoutLabel: 'মাসের ${BnFormat.digits('${_amount(terms, 'payout_day')}')} তারিখে',
      uninvested: _amount(row, 'uninvested'), inStock: _amount(row, 'in_stock'),
      monthsActive: joined == null ? 0 : (now.year - joined.year) * 12 + now.month - joined.month + 1,
      todayPieces: _amount(today, 'pieces'), todayAmount: _amount(today, 'amount'),
      unreadUpdates: _amount(row, 'unread_notifications'),
      preference: _text(row, 'preference'), noticeDays: _amount(terms, 'notice_days'),
    );
  }

  ProductHolding _lot(_Json row, [List<SellerShare> sellers = const []]) {
    final sold = _amount(row, 'sold');
    final revenue = _amount(row, 'revenue');
    final fraction = (row['fraction'] as num?)?.toDouble() ?? 0;
    final fundedSold = (row['sold'] as num? ?? 0) * fraction;
    return ProductHolding(
      id: _text(row, 'lot_id'), productId: _text(row, 'product_id'),
      name: _text(row, 'product_name'), shortName: _text(row, 'product_name'),
      unitCost: _amount(row, 'unit_cost'), salePrice: fundedSold == 0 ? 0 : (revenue / fundedSold).round(),
      priceNote: 'ব্যাচের গড় বিক্রয় মূল্য',
      bought: _amount(row, 'bought'), sold: sold, withSellers: 0, inWarehouse: 0, damaged: 0,
      otherCost: revenue - _amount(row, 'cost') - _amount(row, 'commission') - _amount(row, 'net'),
      batch: _text(row, 'batch'), purchasedOn: _displayDate(row['received_at']), sellers: sellers,
      remainingValue: _amount(row, 'remaining_value'),
      reportedInvested: _amount(row, 'invested'), reportedRevenue: revenue,
      reportedCost: _amount(row, 'cost'), reportedCommission: _amount(row, 'commission'),
      reportedNet: _amount(row, 'net'), reportedShare: _amount(row, 'share'),
    );
  }

  Future<List<ProductHolding>> holdings() async =>
      _rows(_map(await api.get('/investor/portfolio'))['holdings']).map((row) => _lot(row)).toList();

  Future<ProductHolding?> holding(ProductHolding item) async {
    final result = _map(await api.get('/investor/products/${Uri.encodeComponent(item.productId!)}'));
    final sellers = [
      for (final row in _rows(result['sellers']))
        SellerShare(name: _text(row, 'name'), area: _text(row, 'area'),
          inHand: _amount(row, 'in_hand'), sold: _amount(row, 'sold')),
    ];
    for (final row in _rows(result['lots'])) {
      if (row['lot_id'] == item.id) return _lot(row, sellers);
    }
    return null;
  }

  Future<List<SellerHolding>> sellers() async => [
    for (final row in _rows(await api.get('/investor/sellers')))
      SellerHolding(
        name: _text(row, 'name'), area: _text(row, 'area'), lastSale: _displayDate(row['last_sale_at']),
        inHand: _amount(row, 'in_hand'), soldToday: _amount(row, 'sold_today'),
        soldWeek: _amount(row, 'sold_week'), soldMonth: _amount(row, 'sold_month'), todayAmount: _amount(row, 'amount_today'),
        weekAmount: _amount(row, 'amount_week'), monthAmount: _amount(row, 'amount_month'),
        items: _rows(row['items']).map((item) => '${item['product_name']} ${BnFormat.digits('${item['qty']}')}').join(' · '),
      ),
  ];

  Future<List<LedgerEntry>> ledger() async => [
    for (final row in _rows(await api.get('/investor/ledger')))
      LedgerEntry(kind: switch (row['kind']) {'withdraw' => LedgerKind.withdraw, 'profit' => LedgerKind.profit, _ => LedgerKind.invest},
        title: _text(row, 'label'), date: _displayDate(row['at']), via: _text(row, 'method'),
        amount: _amount(row, 'amount'), reference: _text(row, 'receipt')),
  ];

  Future<List<MonthReport>> months() async => [
    for (final row in _rows(await api.get('/investor/reports')).toList().reversed)
      MonthReport(shortLabel: BnFormat.digits(_text(row, 'month')), name: BnFormat.digits(_text(row, 'month')),
        closed: row['status'] != 'draft',
        paidNote: switch (row['status']) {'paid' => 'লাভ দেওয়া হয়েছে', 'approved' => 'পরিশোধের অপেক্ষায়', _ => 'হিসাব চলমান'},
        pieces: _amount(row, 'pieces'), capitalChange: _amount(row, 'capital_change'),
        revenue: _amount(row, 'revenue'), cost: _amount(row, 'cost'), commission: _amount(row, 'commission'),
        otherCost: _amount(row, 'revenue') - _amount(row, 'cost') - _amount(row, 'commission') - _amount(row, 'net'),
        reportedShare: _amount(row, 'share')),
  ];

  Future<List<InvestorNotice>> notices() async => [
    for (final row in _rows(await api.get('/investor/notifications')))
      InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.alert, title: _text(row, 'title'),
        time: _displayDate(row['at']), body: _text(row, 'body'), read: row['read'] == true),
  ];

  Future<Map<String, dynamic>> profile() async => _map(await api.get('/investor/profile'));

  Future<List<Map<String, dynamic>>> withdrawals() async =>
      _rows(await api.get('/investor/withdrawals')).toList();

  Future<void> markNoticesRead() async {
    await api.post('/investor/notifications/read');
  }

  Future<void> setPreference(String preference) async {
    await api.put('/investor/preferences', {'preference': preference});
  }

  Future<void> requestWithdrawal(int amount, String reason, String requestId) async {
    await api.post('/investor/withdrawals', {
      'amount': amount, 'reason': reason, 'client_request_id': requestId,
    });
  }

  static String _displayDate(Object? value) {
    if (value is! String) return '—';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '—';
    return BnFormat.digits('${date.day}/${date.month}/${date.year}');
  }
}
