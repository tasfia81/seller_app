import 'enums.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.todaySales,
    required this.salesCount,
    required this.itemsSold,
    required this.todayEarnings,
    required this.availableStock,
    required this.cashToSubmit,
    required this.unreadNotifications,
    this.lastSaleAt,
    this.lowStockNames = const [],
  });

  final double todaySales;
  final int salesCount;
  final int itemsSold;
  final double todayEarnings;
  final double availableStock;
  final double cashToSubmit;
  final int unreadNotifications;
  final DateTime? lastSaleAt;
  final List<String> lowStockNames;
}

class EarningsSummary {
  const EarningsSummary({
    required this.model,
    required this.ruleText,
    required this.today,
    required this.thisMonth,
    required this.pending,
    required this.approved,
    required this.totalPaid,
    required this.outstanding,
  });

  final CompensationModel model;
  final String ruleText; // e.g. "আপনি বিক্রির লাভের ৫০% কমিশন পাবেন।"
  final double today;
  final double thisMonth;
  final double pending;
  final double approved;
  final double totalPaid;
  final double outstanding;
}

class EarningEntry {
  const EarningEntry({required this.date, required this.salesCount, required this.amount, required this.status});
  final DateTime date;
  final int salesCount;
  final double amount;
  final RequestStatus status;
}

class PayoutEntry {
  const PayoutEntry({required this.date, required this.amount, required this.method});
  final DateTime date;
  final double amount;
  final String method;
}

class CashSummary {
  const CashSummary({
    required this.collected,
    required this.verified,
    required this.pendingVerification,
    required this.remaining,
  });

  final double collected;
  final double verified;
  final double pendingVerification;
  final double remaining;
}

class CashHandover {
  const CashHandover({
    required this.id,
    required this.amount,
    required this.method,
    required this.submittedAt,
    required this.status,
    this.reference,
  });

  final String id;
  final double amount;
  final HandoverMethod method;
  final DateTime submittedAt;
  final RequestStatus status;
  final String? reference;
}

class ClosingRequirement {
  const ClosingRequirement({required this.text, required this.done, this.actionLabel, this.route});
  final String text;
  final bool done;
  final String? actionLabel;
  final String? route;
}

class DayClosingSummary {
  const DayClosingSummary({
    required this.date,
    required this.totalSales,
    required this.itemsSold,
    required this.cashCollected,
    required this.digitalCollected,
    required this.availableStock,
    required this.pendingReturns,
    required this.earned,
    required this.policy,
    required this.requirements,
  });

  final DateTime date;
  final double totalSales;
  final int itemsSold;
  final double cashCollected;
  final double digitalCollected;
  final double availableStock;
  final int pendingReturns;
  final double earned;
  final InventoryPolicy policy;
  final List<ClosingRequirement> requirements;

  bool get canSubmit => requirements.every((r) => r.done);
}
