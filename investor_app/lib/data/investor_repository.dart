import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

/// Everything the investor app reads. The FastAPI client will implement this
/// same interface later; screens only talk to the providers below.
abstract interface class InvestorRepository {
  PortfolioSummary summary();
  List<ProductHolding> holdings();
  List<SellerHolding> sellers();
  List<LedgerEntry> ledger();
  List<MonthReport> months();
  List<InvestorNotice> notices();
}

/// Demo data — every number here agrees with the others (and with the design).
class DemoInvestorRepository implements InvestorRepository {
  const DemoInvestorRepository();

  @override
  PortfolioSummary summary() => const PortfolioSummary(
        investorName: 'তানভীর আহমেদ',
        totalInvested: 500000,
        withdrawn: 50000,
        totalProfit: 36260,
        profitPaid: 25460,
        profitPaidTimes: 3,
        profitThisMonth: 10800,
        nextPayoutLabel: '৫ ডিসে',
        uninvested: 20200,
        monthsActive: 4,
        todayPieces: 38,
        todayAmount: 15640,
        unreadUpdates: 3,
      );

  static const _rakib = 'রাকিব হাসান';
  static const _nusrat = 'নুসরাত জাহান';
  static const _sakib = 'সাকিব মাহমুদ';
  static const _mim = 'মিম আক্তার';

  @override
  List<ProductHolding> holdings() => const [
        ProductHolding(
          id: 'jersey',
          name: 'জার্সি — বাংলাদেশ',
          shortName: 'জার্সি',
          unitCost: 350,
          salePrice: 450,
          priceNote: '৳৪৫০ (নির্দিষ্ট)',
          bought: 428,
          sold: 296,
          withSellers: 84,
          inWarehouse: 42,
          damaged: 6,
          otherCost: 1240,
          batch: 'ব্যাচ-৮৮',
          purchasedOn: '১২ অক্টো ২০২৬',
          sellers: [
            SellerShare(name: _rakib, area: 'মিরপুর-১০', inHand: 32, sold: 120),
            SellerShare(name: _nusrat, area: 'ধানমন্ডি', inHand: 28, sold: 98),
            SellerShare(name: _sakib, area: 'উত্তরা', inHand: 24, sold: 78),
          ],
        ),
        ProductHolding(
          id: 'polo',
          name: 'পোলো টি-শার্ট',
          shortName: 'পোলো',
          unitCost: 260,
          salePrice: 380,
          priceNote: '৳৩৫০–৪২০ (গড় ৳৩৮০)',
          bought: 400,
          sold: 268,
          withSellers: 70,
          inWarehouse: 58,
          damaged: 4,
          otherCost: 896,
          batch: 'ব্যাচ-৮৪',
          purchasedOn: '১০ সেপ্টে ২০২৬',
          sellers: [
            SellerShare(name: _rakib, area: 'মিরপুর-১০', inHand: 24, sold: 100),
            SellerShare(name: _nusrat, area: 'ধানমন্ডি', inHand: 20, sold: 88),
            SellerShare(name: _sakib, area: 'উত্তরা', inHand: 26, sold: 80),
          ],
        ),
        ProductHolding(
          id: 'jogger',
          name: 'জগার প্যান্ট',
          shortName: 'জগার',
          unitCost: 360,
          salePrice: 550,
          priceNote: '৳৫০০–৬০০ (গড় ৳৫৫০)',
          bought: 250,
          sold: 141,
          withSellers: 52,
          inWarehouse: 55,
          damaged: 2,
          otherCost: 874,
          batch: 'ব্যাচ-৮৫',
          purchasedOn: '১৪ সেপ্টে ২০২৬',
          sellers: [
            SellerShare(name: _nusrat, area: 'ধানমন্ডি', inHand: 30, sold: 80),
            SellerShare(name: _mim, area: 'মোহাম্মদপুর', inHand: 22, sold: 61),
          ],
        ),
        ProductHolding(
          id: 'basic',
          name: 'বেসিক টি-শার্ট (সাদা)',
          shortName: 'বেসিক',
          unitCost: 160,
          salePrice: 250,
          priceNote: '৳২৫০ (নির্দিষ্ট)',
          bought: 400,
          sold: 322,
          withSellers: 48,
          inWarehouse: 26,
          damaged: 4,
          otherCost: 788,
          batch: 'ব্যাচ-৭৯',
          purchasedOn: '০৬ আগস্ট ২০২৬',
          sellers: [
            SellerShare(name: _rakib, area: 'মিরপুর-১০', inHand: 20, sold: 180),
            SellerShare(name: _mim, area: 'মোহাম্মদপুর', inHand: 28, sold: 142),
          ],
        ),
        ProductHolding(
          id: 'cap',
          name: 'ক্রিকেট ক্যাপ',
          shortName: 'ক্যাপ',
          unitCost: 110,
          salePrice: 180,
          priceNote: '৳১৮০ (নির্দিষ্ট)',
          bought: 200,
          sold: 150,
          withSellers: 30,
          inWarehouse: 18,
          damaged: 2,
          otherCost: 500,
          batch: 'ব্যাচ-৮০',
          purchasedOn: '০৮ আগস্ট ২০২৬',
          sellers: [
            SellerShare(name: _rakib, area: 'মিরপুর-১০', inHand: 16, sold: 85),
            SellerShare(name: _sakib, area: 'উত্তরা', inHand: 14, sold: 65),
          ],
        ),
      ];

  @override
  List<SellerHolding> sellers() => const [
        SellerHolding(
            name: _rakib, area: 'মিরপুর-১০', lastSale: '১০ মিনিট আগে', inHand: 92,
            soldToday: 12, soldWeek: 74, soldMonth: 98, todayAmount: 4980,
            items: 'জার্সি ৩২ · পোলো ২৪ · বেসিক ২০ · ক্যাপ ১৬'),
        SellerHolding(
            name: _nusrat, area: 'ধানমন্ডি', lastSale: '২৫ মিনিট আগে', inHand: 78,
            soldToday: 10, soldWeek: 68, soldMonth: 82, todayAmount: 4120,
            items: 'জার্সি ২৮ · জগার ৩০ · পোলো ২০'),
        SellerHolding(
            name: _sakib, area: 'উত্তরা', lastSale: '১ ঘণ্টা আগে', inHand: 64,
            soldToday: 9, soldWeek: 55, soldMonth: 66, todayAmount: 3690,
            items: 'জার্সি ২৪ · পোলো ২৬ · ক্যাপ ১৪'),
        SellerHolding(
            name: _mim, area: 'মোহাম্মদপুর', lastSale: '২ ঘণ্টা আগে', inHand: 50,
            soldToday: 7, soldWeek: 41, soldMonth: 49, todayAmount: 2850,
            items: 'জগার ২২ · বেসিক ২৮'),
      ];

  @override
  List<LedgerEntry> ledger() => const [
        LedgerEntry(kind: LedgerKind.withdraw, title: 'মূলধন ফেরত', date: '১৮ নভে ২০২৬', via: 'ব্যাংক ••৪৮২১', amount: 50000, reference: 'W-০০১২'),
        LedgerEntry(kind: LedgerKind.profit, title: 'অক্টোবরের লাভ', date: '০৫ নভে ২০২৬', via: 'বিকাশ ••৭৭০২', amount: 11460, reference: 'P-০০৩১'),
        LedgerEntry(kind: LedgerKind.invest, title: 'বিনিয়োগ (৩য় কিস্তি)', date: '১২ অক্টো ২০২৬', via: 'ব্যাংক ট্রান্সফার', amount: 150000, reference: 'I-০০২৪'),
        LedgerEntry(kind: LedgerKind.profit, title: 'সেপ্টেম্বরের লাভ', date: '০৫ অক্টো ২০২৬', via: 'বিকাশ ••৭৭০২', amount: 8600, reference: 'P-০০২২'),
        LedgerEntry(kind: LedgerKind.invest, title: 'বিনিয়োগ (২য় কিস্তি)', date: '১০ সেপ্টে ২০২৬', via: 'ব্যাংক ট্রান্সফার', amount: 150000, reference: 'I-০০১৭'),
        LedgerEntry(kind: LedgerKind.profit, title: 'আগস্টের লাভ', date: '০৫ সেপ্টে ২০২৬', via: 'বিকাশ ••৭৭০২', amount: 5400, reference: 'P-০০১১'),
        LedgerEntry(kind: LedgerKind.invest, title: 'প্রথম বিনিয়োগ', date: '০৪ আগস্ট ২০২৬', via: 'ব্যাংক ট্রান্সফার', amount: 200000, reference: 'I-০০০৯'),
      ];

  @override
  List<MonthReport> months() => const [
        MonthReport(shortLabel: 'আগস্ট', name: 'আগস্ট ২০২৬', closed: true, paidNote: '৫ সেপ্টেম্বর বিকাশে দেওয়া হয়েছে · রসিদ P-০০১১', pieces: 180, capitalChange: 200000, revenue: 76000, cost: 57000, commission: 7600, otherCost: 600),
        MonthReport(shortLabel: 'সেপ্টে', name: 'সেপ্টেম্বর ২০২৬', closed: true, paidNote: '৫ অক্টোবর বিকাশে দেওয়া হয়েছে · রসিদ P-০০২২', pieces: 290, capitalChange: 150000, revenue: 120000, cost: 90000, commission: 12000, otherCost: 800),
        MonthReport(shortLabel: 'অক্টো', name: 'অক্টোবর ২০২৬', closed: true, paidNote: '৫ নভেম্বর বিকাশে দেওয়া হয়েছে · রসিদ P-০০৩১', pieces: 412, capitalChange: 150000, revenue: 162000, cost: 122000, commission: 16000, otherCost: 1080),
        MonthReport(shortLabel: 'নভে', name: 'নভেম্বর ২০২৬', closed: false, paidNote: 'চলমান — ৩০ নভেম্বর হিসাব বন্ধ, ৫ ডিসেম্বর দেওয়া হবে', pieces: 295, capitalChange: -50000, revenue: 148000, cost: 111000, commission: 14800, otherCost: 600),
      ];

  @override
  List<InvestorNotice> notices() => const [
        InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.money, title: 'লাভ জমা হয়েছে', time: '৫ নভে', body: 'অক্টোবরের লাভ ৳১১,৪৬০ বিকাশ ••৭৭০২-এ পাঠানো হয়েছে · রসিদ P-০০৩১'),
        InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.seller, title: 'স্টক নতুন সেলারের কাছে', time: '২ ঘণ্টা আগে', body: '২৪ পিস জার্সি সাকিব মাহমুদের (উত্তরা) দায়িত্বে দেওয়া হলো'),
        InvestorNotice(tone: NoticeTone.bad, icon: NoticeIcon.alert, title: 'নষ্ট পণ্যের রিপোর্ট', time: 'গতকাল', body: '৬ পিস জার্সি নষ্ট হিসেবে জমা হয়েছে — তদন্ত চলছে, ফল জানানো হবে'),
        InvestorNotice(tone: NoticeTone.warn, icon: NoticeIcon.withdraw, title: 'মূলধন ফেরত সম্পন্ন', time: '১৮ নভে', body: '৳৫০,০০০ ব্যাংক ••৪৮২১-এ পাঠানো হয়েছে · রসিদ W-০০১২'),
        InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.report, title: 'অক্টোবরের রিপোর্ট প্রস্তুত', time: '১ নভে', body: '৪১২ পিস বিক্রি, আপনার ভাগ ৳১১,৪৬০ — বিস্তারিত দেখুন'),
        InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.stock, title: 'নতুন স্টক কেনা হয়েছে', time: '১২ অক্টো', body: 'আপনার টাকায় ৪২৮ পিস জার্সি কেনা হলো · ব্যাচ-৮৮ · রহমান গার্মেন্টস'),
        InvestorNotice(tone: NoticeTone.good, icon: NoticeIcon.contract, title: 'চুক্তিতে কোম্পানির সই', time: '১০ সেপ্টে', body: '২য় কিস্তির চুক্তিতে কোম্পানির সই হয়েছে — অ্যাপে কপি আছে'),
      ];
}

final investorRepositoryProvider = Provider<InvestorRepository>((_) => const DemoInvestorRepository());

final summaryProvider = Provider((ref) => ref.watch(investorRepositoryProvider).summary());
final holdingsProvider = Provider((ref) => ref.watch(investorRepositoryProvider).holdings());
final sellersProvider = Provider((ref) => ref.watch(investorRepositoryProvider).sellers());
final ledgerProvider = Provider((ref) => ref.watch(investorRepositoryProvider).ledger());
final monthsProvider = Provider((ref) => ref.watch(investorRepositoryProvider).months());
final noticesProvider = Provider((ref) => ref.watch(investorRepositoryProvider).notices());

final holdingProvider = Provider.family<ProductHolding?, String>((ref, id) {
  for (final h in ref.watch(holdingsProvider)) {
    if (h.id == id) return h;
  }
  return null;
});

/// Side menu open/closed (animated by the main shell).
final sideMenuOpenProvider = StateProvider<bool>((_) => false);
