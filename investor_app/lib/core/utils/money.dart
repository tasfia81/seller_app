import 'bn_format.dart';

/// ৳ with Bangla digits and South-Asian grouping: 450000 → ৳৪,৫০,০০০.
String tk(num value) => value < 0 ? '−৳${BnFormat.number(-value)}' : '৳${BnFormat.number(value)}';

/// Signed amount: +৳১১,৪৬০ / −৳৫০,০০০.
String tkSigned(num value) => value < 0 ? '−৳${BnFormat.number(-value)}' : '+৳${BnFormat.number(value)}';

/// Bangla integer: 1177 → ১,১৭৭.
String bn(num value) => BnFormat.number(value);

/// Bangla percent with one decimal: 7.25 → ৭.৩%.
String pct(num value, {int decimals = 1}) => '${BnFormat.number(value, decimals: decimals)}%';
