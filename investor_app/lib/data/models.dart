import '../core/constants/app_config.dart';

/// Totals shown on Home.
class PortfolioSummary {
  const PortfolioSummary({
    required this.investorName,
    required this.totalInvested,
    required this.withdrawn,
    required this.totalProfit,
    required this.profitPaid,
    required this.profitPaidTimes,
    required this.profitThisMonth,
    required this.nextPayoutLabel,
    required this.uninvested,
    required this.monthsActive,
    required this.todayPieces,
    required this.todayAmount,
    required this.unreadUpdates,
    this.inStock,
    this.preference = "cash",
    this.noticeDays = 30,
  });

  final String investorName;
  final int totalInvested;
  final int withdrawn;
  final int totalProfit;
  final int profitPaid;
  final int profitPaidTimes;
  final int profitThisMonth;
  final String nextPayoutLabel;
  final int uninvested;
  final int monthsActive;
  final int todayPieces;
  final int todayAmount;
  final int unreadUpdates;
  final int? inStock;
  final String preference;
  final int noticeDays;

  int get activeCapital => totalInvested - withdrawn;
  double get returnPercent => totalInvested == 0 ? 0 : totalProfit * 100 / totalInvested;
}

class SellerShare {
  const SellerShare({required this.name, required this.area, required this.inHand, required this.sold});
  final String name;
  final String area;
  final int inHand;
  final int sold;

  String get initial => name.characters2;
}

/// A product bought with the investor's money.
class ProductHolding {
  const ProductHolding({
    required this.id,
    required this.name,
    required this.shortName,
    required this.unitCost,
    required this.salePrice,
    required this.priceNote,
    required this.bought,
    required this.sold,
    required this.withSellers,
    required this.inWarehouse,
    required this.damaged,
    required this.otherCost,
    required this.batch,
    required this.purchasedOn,
    required this.sellers,
    this.productId,
    this.remainingValue,
    this.reportedInvested,
    this.reportedRevenue,
    this.reportedCost,
    this.reportedCommission,
    this.reportedNet,
    this.reportedShare,
  });

  final String id;
  final String name;
  final String shortName;
  final int unitCost;
  final int salePrice; // average selling price
  final String priceNote;
  final int bought;
  final int sold;
  final int withSellers;
  final int inWarehouse;
  final int damaged;
  final int otherCost;
  final String batch;
  final String purchasedOn;
  final List<SellerShare> sellers;

  final String? productId;
  final int? remainingValue;
  int get stockCost => remainingValue ?? invested;
  final int? reportedInvested, reportedRevenue, reportedCost, reportedCommission, reportedNet, reportedShare;

  int get invested => reportedInvested ?? unitCost * bought;
  int get remaining => bought - sold;
  double get soldRatio => bought == 0 ? 0 : sold / bought;

  int get revenue => reportedRevenue ?? sold * salePrice;
  int get costOfSold => reportedCost ?? sold * unitCost;
  int get grossProfit => revenue - costOfSold;
  int get sellerCommission => reportedCommission ?? (grossProfit * AppConfig.sellerCommissionPercent / 100).round();
  int get netProfit => reportedNet ?? grossProfit - sellerCommission - otherCost;
  int get investorShare => reportedShare ?? (netProfit * AppConfig.profitSharePercent / 100).round();
  int get damageLoss => damaged * unitCost;
}

class SellerHolding {
  const SellerHolding({
    required this.name,
    required this.area,
    required this.lastSale,
    required this.inHand,
    required this.soldToday,
    required this.soldWeek,
    required this.soldMonth,
    required this.todayAmount,
    required this.items,
    this.weekAmount,
    this.monthAmount,
  });

  final String name;
  final String area;
  final String lastSale;
  final int inHand;
  final int soldToday;
  final int soldWeek;
  final int soldMonth;
  final int todayAmount;

  final int? weekAmount, monthAmount;
  final String items;

  String get initial => name.characters2;
}

enum LedgerKind { invest, profit, withdraw }

class LedgerEntry {
  const LedgerEntry({
    required this.kind,
    required this.title,
    required this.date,
    required this.via,
    required this.amount,
    required this.reference,
  });

  final LedgerKind kind;
  final String title;
  final String date;
  final String via;
  final int amount;
  final String reference;
}

class MonthReport {
  const MonthReport({
    required this.shortLabel,
    required this.name,
    required this.closed,
    required this.paidNote,
    required this.pieces,
    required this.capitalChange,
    required this.revenue,
    required this.cost,
    required this.commission,
    required this.otherCost,
    this.reportedShare,
  });

  final String shortLabel;
  final String name;
  final bool closed;
  final String paidNote;
  final int pieces;
  final int capitalChange;
  final int revenue;
  final int cost;
  final int commission;
  final int otherCost;

  int get gross => revenue - cost;
  int get net => gross - commission - otherCost;
  final int? reportedShare;
  int get share => reportedShare ?? (net * AppConfig.profitSharePercent / 100).round();
}

enum NoticeTone { good, warn, bad }

enum NoticeIcon { money, stock, seller, alert, report, withdraw, contract }

class InvestorNotice {
  const InvestorNotice({
    required this.tone,
    required this.icon,
    required this.title,
    required this.time,
    required this.body,
    this.read = false,
  });

  final NoticeTone tone;
  final NoticeIcon icon;
  final String title;
  final String time;
  final String body;
  final bool read;
}

extension on String {
  /// First two characters (Bangla initials such as "রা").
  String get characters2 => length <= 2 ? this : substring(0, 2);
}
