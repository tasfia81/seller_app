/// How a product is measured. Quantity controls adapt to [step] and [decimals],
/// so no category needs its own sale form.
enum UnitType {
  piece('পিস', 1, 0),
  kg('কেজি', 0.5, 2),
  gram('গ্রাম', 50, 0),
  liter('লিটার', 0.5, 2),
  packet('প্যাকেট', 1, 0),
  bottle('বোতল', 1, 0),
  box('বক্স', 1, 0);

  const UnitType(this.label, this.step, this.decimals);
  final String label;
  final double step;
  final int decimals;

  /// One-tap quantity presets shown under the stepper.
  List<double> get presets => switch (this) {
        UnitType.kg || UnitType.liter => [0.5, 1, 2, 5],
        UnitType.gram => [100, 250, 500, 1000],
        _ => [1, 2, 5, 10],
      };
}

enum PaymentMethod {
  cash('ক্যাশ'),
  bkash('বিকাশ'),
  nagad('নগদ'),
  other('অন্যান্য');

  const PaymentMethod(this.label);
  final String label;
}

enum SaleStatus {
  confirmed('নিশ্চিত'),
  pendingSync('পাঠানো বাকি'),
  correctionRequested('সংশোধনের অনুরোধ'),
  cancelled('বাতিল');

  const SaleStatus(this.label);
  final String label;
}

enum RequestStatus {
  pending('অপেক্ষমাণ'),
  approved('অনুমোদিত'),
  rejected('বাতিল'),
  completed('সম্পন্ন');

  const RequestStatus(this.label);
  final String label;
}

enum ApplicationStatus {
  draft('খসড়া'),
  submitted('জমা হয়েছে'),
  underReview('যাচাই চলছে'),
  moreInfoRequired('আরও তথ্য প্রয়োজন'),
  approved('অনুমোদিত'),
  rejected('বাতিল');

  const ApplicationStatus(this.label);
  final String label;
}

enum CompensationModel { profitPercentage, dailyWage, perUnitCommission, hybrid }

enum InventoryPolicy {
  dailyReturn('প্রতিদিন ফেরত', 'দিন শেষে বিক্রি না হওয়া সব পণ্য অফিসে ফেরত দিতে হবে।'),
  carryForward('পরের দিনে চলবে', 'বিক্রি না হওয়া পণ্য আপনার কাছেই থাকবে, পরের দিন বিক্রি করতে পারবেন।');

  const InventoryPolicy(this.label, this.description);
  final String label;
  final String description;
}

enum ReturnReason {
  endOfDay('দিন শেষের ফেরত'),
  damaged('ক্ষতিগ্রস্ত'),
  expired('মেয়াদ শেষ'),
  other('অন্যান্য');

  const ReturnReason(this.label);
  final String label;
}

enum HandoverMethod {
  inPerson('অফিসে হাতে হাতে'),
  bkash('বিকাশ'),
  nagad('নগদ'),
  bank('ব্যাংক');

  const HandoverMethod(this.label);
  final String label;
}

enum NotificationType {
  stockAssigned('স্টক'),
  priceChanged('দাম'),
  commissionUpdated('আয়'),
  cashVerified('টাকা'),
  returnUpdate('স্টক'),
  dayClosed('হিসাব'),
  announcement('ঘোষণা');

  const NotificationType(this.filterLabel);
  final String filterLabel;
}
