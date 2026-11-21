import '../../shared/models/enums.dart';
import '../../shared/models/finance.dart';
import '../../shared/models/inventory.dart';
import '../../shared/models/product.dart';
import '../../shared/models/sale.dart';
import '../../shared/models/seller.dart';
import '../constants/app_config.dart';
import '../errors/failure.dart';

/// DEMO FIXTURES — UI preview only.
///
/// Used only while [AppConfig.demoMode] is true (a "ডেমো" banner is shown).
/// Contains no real people, NID numbers or transactions. Delete this file
/// when the FastAPI repositories are implemented.
abstract final class DemoData {
  static void ensureEnabled() {
    if (!AppConfig.demoMode) throw const NotConnectedFailure();
  }

  static DateTime _today(int h, int m) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  }

  static DateTime _daysAgo(int d, [int h = 18, int m = 0]) =>
      _today(h, m).subtract(Duration(days: d));

  static final products = <Product>[
    const Product(
      id: 'p1',
      name: 'জার্সি — বাংলাদেশ',
      category: 'জার্সি',
      unit: UnitType.piece,
      price: 450,
      availableQty: 12,
      variantLabel: 'সাইজ',
      variants: ['S', 'M', 'L', 'XL'],
    ),
    const Product(
      id: 'p2',
      name: 'পোলো টি-শার্ট',
      category: 'টি-শার্ট',
      unit: UnitType.piece,
      price: 380,
      minPrice: 350,
      maxPrice: 420,
      availableQty: 18,
      variantLabel: 'সাইজ',
      variants: ['M', 'L', 'XL'],
    ),
    const Product(
      id: 'p3',
      name: 'বেসিক টি-শার্ট (সাদা)',
      category: 'টি-শার্ট',
      unit: UnitType.piece,
      price: 250,
      availableQty: 25,
      variantLabel: 'সাইজ',
      variants: ['M', 'L', 'XL', 'XXL'],
    ),
    const Product(
      id: 'p4',
      name: 'জগার প্যান্ট',
      category: 'প্যান্ট',
      unit: UnitType.piece,
      price: 550,
      minPrice: 500,
      maxPrice: 600,
      availableQty: 8,
      variantLabel: 'সাইজ',
      variants: ['M', 'L', 'XL'],
    ),
    const Product(
      id: 'p5',
      name: 'ক্রিকেট ক্যাপ',
      category: 'অ্যাক্সেসরিজ',
      unit: UnitType.piece,
      price: 180,
      availableQty: 3,
    ),
    const Product(
      id: 'p6',
      name: 'মোজা (৩ জোড়া)',
      category: 'অ্যাক্সেসরিজ',
      unit: UnitType.packet,
      price: 150,
      availableQty: 0,
    ),
  ];

  static List<Sale> get sales => [
        Sale(
          id: 'বি-১০৪৮২',
          productId: 'p1',
          productName: 'জার্সি — বাংলাদেশ',
          variant: 'L',
          quantity: 2,
          unit: UnitType.piece,
          unitPrice: 450,
          payment: PaymentMethod.bkash,
          time: _today(10, 48),
          status: SaleStatus.confirmed,
        ),
        Sale(
          id: 'অপেক্ষমাণ-১',
          productId: 'p3',
          productName: 'বেসিক টি-শার্ট (সাদা)',
          variant: 'M',
          quantity: 3,
          unit: UnitType.piece,
          unitPrice: 250,
          payment: PaymentMethod.cash,
          time: _today(10, 35),
          status: SaleStatus.pendingSync,
        ),
        Sale(
          id: 'বি-১০৪৭৯',
          productId: 'p2',
          productName: 'পোলো টি-শার্ট',
          variant: 'XL',
          quantity: 1,
          unit: UnitType.piece,
          unitPrice: 380,
          payment: PaymentMethod.cash,
          time: _today(10, 20),
          status: SaleStatus.confirmed,
        ),
        Sale(
          id: 'বি-১০৪৭১',
          productId: 'p5',
          productName: 'ক্রিকেট ক্যাপ',
          quantity: 1,
          unit: UnitType.piece,
          unitPrice: 180,
          payment: PaymentMethod.nagad,
          time: _today(9, 52),
          status: SaleStatus.correctionRequested,
        ),
        Sale(
          id: 'বি-১০৪৫০',
          productId: 'p4',
          productName: 'জগার প্যান্ট',
          variant: 'L',
          quantity: 1,
          unit: UnitType.piece,
          unitPrice: 550,
          payment: PaymentMethod.cash,
          time: _daysAgo(1, 17, 15),
          status: SaleStatus.confirmed,
        ),
      ];

  static DashboardSummary get dashboard => DashboardSummary(
        todaySales: 4850,
        salesCount: 18,
        itemsSold: 21,
        todayEarnings: 620,
        availableStock: 66,
        cashToSubmit: 3200,
        unreadNotifications: 3,
        lastSaleAt: _today(10, 48),
        lowStockNames: const ['ক্রিকেট ক্যাপ'],
      );

  static const earnings = EarningsSummary(
    model: CompensationModel.profitPercentage,
    ruleText: 'আপনি বিক্রির লাভের ৫০% কমিশন পাবেন।',
    today: 620,
    thisMonth: 12480,
    pending: 1860,
    approved: 10620,
    totalPaid: 8000,
    outstanding: 2620,
  );

  static List<EarningEntry> get earningHistory => [
        EarningEntry(date: _daysAgo(0), salesCount: 18, amount: 620, status: RequestStatus.pending),
        EarningEntry(date: _daysAgo(1), salesCount: 24, amount: 880, status: RequestStatus.approved),
        EarningEntry(date: _daysAgo(2), salesCount: 21, amount: 740, status: RequestStatus.approved),
        EarningEntry(date: _daysAgo(3), salesCount: 15, amount: 510, status: RequestStatus.approved),
      ];

  static List<PayoutEntry> get payouts => [
        PayoutEntry(date: _daysAgo(7), amount: 5000, method: 'বিকাশ'),
        PayoutEntry(date: _daysAgo(14), amount: 3000, method: 'অফিসে হাতে হাতে'),
      ];

  static const inventory = InventorySummary(
    policy: InventoryPolicy.dailyReturn,
    totalAssigned: 90,
    sold: 21,
    available: 66,
    pendingReturn: 2,
    damaged: 1,
    disputed: 0,
  );

  static List<StockMovement> get movements => [
        StockMovement(
            kind: MovementKind.assigned,
            title: 'জার্সি বরাদ্দ +২০ পিস',
            subtitle: 'অ্যাডমিন',
            time: _today(8, 10)),
        StockMovement(
            kind: MovementKind.sold,
            title: 'জার্সি বিক্রি −২ পিস',
            subtitle: '#বি-১০৪৮২',
            time: _today(10, 48)),
        StockMovement(
            kind: MovementKind.returnRequested,
            title: 'পোলো টি-শার্ট ফেরত অনুরোধ ২ পিস',
            subtitle: 'অনুমোদনের অপেক্ষায়',
            time: _today(11, 5)),
      ];

  static const cash = CashSummary(collected: 4200, verified: 1000, pendingVerification: 0, remaining: 3200);

  static List<CashHandover> get handovers => [
        CashHandover(
            id: 'h2',
            amount: 3800,
            method: HandoverMethod.inPerson,
            submittedAt: _daysAgo(1, 19, 10),
            status: RequestStatus.approved),
        CashHandover(
            id: 'h1',
            amount: 2950,
            method: HandoverMethod.bkash,
            submittedAt: _daysAgo(2, 19, 30),
            status: RequestStatus.approved,
            reference: 'TX8K2'),
      ];

  static DayClosingSummary get dayClosing => DayClosingSummary(
        date: DateTime.now(),
        totalSales: 4850,
        itemsSold: 21,
        cashCollected: 4200,
        digitalCollected: 650,
        availableStock: 66,
        pendingReturns: 1,
        earned: 620,
        policy: InventoryPolicy.dailyReturn,
        requirements: const [
          ClosingRequirement(text: 'সব বিক্রি নিশ্চিত হয়েছে', done: true),
          ClosingRequirement(text: 'একটি বিক্রি এখনো সার্ভারে পাঠানো বাকি', done: false),
          ClosingRequirement(
              text: 'ক্যাশ ৳৩,২০০ জমা দিন', done: false, actionLabel: 'জমা দিন', route: '/cash-handover'),
          ClosingRequirement(
              text: 'বাকি ৬৬টি পণ্য ফেরত দিন', done: false, actionLabel: 'ফেরত', route: '/stock-return'),
        ],
      );

  static List<AppNotification> get notifications => [
        AppNotification(
            id: 'n1',
            type: NotificationType.stockAssigned,
            title: 'নতুন স্টক বরাদ্দ',
            body: 'আপনাকে ২০ পিস জার্সি দেওয়া হয়েছে।',
            time: _today(8, 10),
            isRead: false),
        AppNotification(
            id: 'n2',
            type: NotificationType.priceChanged,
            title: 'দাম পরিবর্তন',
            body: 'পোলো টি-শার্টের দাম ৳৪০০ থেকে ৳৩৮০ করা হয়েছে।',
            time: _today(7, 45),
            isRead: false),
        AppNotification(
            id: 'n3',
            type: NotificationType.cashVerified,
            title: 'ক্যাশ জমা যাচাই হয়েছে',
            body: 'গতকালের ৳৩,৮০০ গ্রহণ নিশ্চিত করা হয়েছে।',
            time: _today(7, 30),
            isRead: false),
        AppNotification(
            id: 'n4',
            type: NotificationType.returnUpdate,
            title: 'ফেরত অনুরোধ অনুমোদিত',
            body: '৪ প্যাকেট মোজা ফেরত নেওয়া হয়েছে।',
            time: _daysAgo(1, 18, 20),
            isRead: true),
        AppNotification(
            id: 'n5',
            type: NotificationType.announcement,
            title: 'অ্যাডমিনের ঘোষণা',
            body: 'শুক্রবার অফিস বন্ধ থাকবে।',
            time: _daysAgo(1, 16, 0),
            isRead: true),
      ];

  static const profile = SellerProfile(
    name: 'রাকিব হাসান',
    mobile: '01712345678',
    presentAddress: 'বাড়ি ১২, রোড ৩, মিরপুর, ঢাকা',
    permanentAddress: 'বাড়ি ১২, রোড ৩, মিরপুর, ঢাকা',
    emergencyContact: 'সালমা বেগম (মা) · ০১৮১৯-২২৩৩৪৪',
    maskedNid: '•••• •••• ৪৫২১',
    isVerified: true,
    isActive: true,
  );

  static ApplicationInfo get application => ApplicationInfo(
        id: '#আবে-০০৪৮',
        status: ApplicationStatus.moreInfoRequired,
        submittedAt: _today(9, 15),
        adminMessage: 'পরিচয়পত্রের পেছনের ছবিটি ঝাপসা। শুধু এই ছবিটি আবার দিন, বাকি তথ্য আর দিতে হবে না।',
        timeline: [
          ApplicationTimelineStep(title: 'আবেদন জমা হয়েছে', time: _today(9, 15), state: TimelineState.done),
          ApplicationTimelineStep(title: 'যাচাই শুরু হয়েছে', time: _today(12, 30), state: TimelineState.done),
          const ApplicationTimelineStep(title: 'আপনার কাছ থেকে তথ্য প্রয়োজন', state: TimelineState.attention),
          const ApplicationTimelineStep(title: 'অনুমোদন', state: TimelineState.upcoming),
        ],
      );
}
