import 'bn_format.dart';

/// Same rules as the server, so mistakes are caught before a round trip.
abstract final class Validators {
  static String digitsOnly(String v) => BnFormat.toAscii(v).replaceAll(RegExp(r'\D'), '');

  /// Bangladeshi mobile → `01XXXXXXXXX`, or null when invalid.
  static String? mobile(String v) {
    var d = digitsOnly(v);
    if (d.startsWith('880')) d = d.substring(2);
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(d) ? d : null;
  }

  static String? nid(String v) {
    final d = digitsOnly(v);
    return const [10, 13, 17].contains(d.length) ? d : null;
  }

  static String? password(String v) {
    if (v.length < 8) return 'কমপক্ষে ৮ অক্ষর দিন';
    if (!RegExp(r'\d').hasMatch(v)) return 'অন্তত একটি সংখ্যা দিন';
    return null;
  }

  static bool email(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  /// Amount typed with Bangla/English digits and commas → number, or null.
  static double? amount(String v) {
    final s = BnFormat.toAscii(v).replaceAll(',', '').trim();
    final n = double.tryParse(s);
    return n != null && n > 0 ? n : null;
  }

  static int age(DateTime dob, DateTime now) {
    var a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
    return a;
  }
}
