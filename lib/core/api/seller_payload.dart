import '../../shared/models/enums.dart';
import '../../shared/models/sale.dart';
import '../../shared/models/seller.dart';

typedef Json = Map<String, dynamic>;

Json jsonMap(dynamic value) => Map<String, dynamic>.from(value as Map);
List<Json> jsonRows(dynamic value) => (value as List).map(jsonMap).toList();
double number(Json row, String key) => (row[key] as num).toDouble();
DateTime date(Json row, String key) => DateTime.parse(row[key] as String).toLocal();
String dateParam(DateTime value) => value.toIso8601String().split('T').first;

UnitType parseUnit(Object? value) => UnitType.values.asNameMap()[value] ?? UnitType.piece;

InventoryPolicy parsePolicy(Object? value) =>
    value == 'daily_return' ? InventoryPolicy.dailyReturn : InventoryPolicy.carryForward;

RequestStatus parseRequest(Object? value) => switch (value) {
      'verified' || 'completed' => RequestStatus.completed,
      'approved' => RequestStatus.approved,
      'rejected' => RequestStatus.rejected,
      _ => RequestStatus.pending,
    };

Sale parseSale(Json row) => Sale(
      id: row['id'] as String,
      receiptNo: row['receipt_no'] as String?,
      productId: row['product_id'] as String,
      productName: row['product_name'] as String,
      unit: parseUnit(row['unit']),
      quantity: number(row, 'quantity'),
      unitPrice: number(row, 'unit_price'),
      payment: PaymentMethod.values.asNameMap()[row['payment']] ?? PaymentMethod.other,
      time: date(row, 'created_at'),
      status: row['status'] == 'correction_requested' ? SaleStatus.correctionRequested : SaleStatus.confirmed,
      variant: row['variant'] as String?,
      note: row['note'] as String?,
    );

String _place(Object? value) {
  if (value is String) return value;
  final address = jsonMap(value);
  return [address['detail'], address['upazila'], address['district']].whereType<String>().join(', ');
}

SellerProfile parseProfile(Json row) {
  final emergency = jsonMap(row['emergency']);
  return SellerProfile(
    name: row['name'] as String,
    mobile: row['mobile'] as String,
    presentAddress: _place(row['present_address']),
    permanentAddress: _place(row['permanent_address']),
    emergencyContact: [emergency['name'], emergency['relation'], emergency['mobile']]
        .whereType<String>()
        .join(' · '),
    maskedNid: row['nid_masked'] as String,
    isVerified: row['verified'] == true,
    isActive: row['status'] == 'active',
  );
}
