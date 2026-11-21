/// Bangla formatting for numbers, money, dates and phone numbers.
abstract final class BnFormat {
  static const _bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  static const _months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];
  static const _weekdays = [
    'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার',
  ];

  /// English digits → Bangla digits.
  static String digits(String input) =>
      input.replaceAllMapped(RegExp('[0-9]'), (m) => _bn[int.parse(m[0]!)]);

  /// Bangla digits → English digits (for parsing user input).
  static String toAscii(String input) {
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final i = _bn.indexOf(ch);
      buffer.write(i >= 0 ? '$i' : ch);
    }
    return buffer.toString();
  }

  /// 1234567.5 → ১২,৩৪,৫৬৭.৫ (South Asian grouping).
  static String number(num value, {int decimals = 0}) {
    final negative = value < 0;
    final parts = value.abs().toStringAsFixed(decimals).split('.');
    var intPart = parts[0];
    String grouped;
    if (intPart.length <= 3) {
      grouped = intPart;
    } else {
      final last3 = intPart.substring(intPart.length - 3);
      intPart = intPart.substring(0, intPart.length - 3);
      final groups = <String>[];
      while (intPart.length > 2) {
        groups.insert(0, intPart.substring(intPart.length - 2));
        intPart = intPart.substring(0, intPart.length - 2);
      }
      if (intPart.isNotEmpty) groups.insert(0, intPart);
      grouped = '${groups.join(',')},$last3';
    }
    var out = grouped;
    if (parts.length > 1) {
      final dec = parts[1].replaceFirst(RegExp(r'0+$'), '');
      if (dec.isNotEmpty) out = '$out.$dec';
    }
    return digits('${negative ? '-' : ''}$out');
  }

  static String money(num value) => '৳${number(value, decimals: 2)}';
  static String qty(num value) => number(value, decimals: 2);

  static String date(DateTime d) => '${digits('${d.day}')} ${_months[d.month - 1]}';
  static String dateFull(DateTime d) => '${date(d)} ${digits('${d.year}')}';
  static String weekdayDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${date(d)}';

  static String time(DateTime d) {
    final h = d.hour;
    final period = h < 5
        ? 'রাত'
        : h < 12
            ? 'সকাল'
            : h < 15
                ? 'দুপুর'
                : h < 18
                    ? 'বিকাল'
                    : h < 20
                        ? 'সন্ধ্যা'
                        : 'রাত';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$period ${digits('$h12:${d.minute.toString().padLeft(2, '0')}')}';
  }

  static String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'শুভ সকাল';
    if (h < 17) return 'শুভ দুপুর';
    if (h < 20) return 'শুভ সন্ধ্যা';
    return 'শুভ রাত্রি';
  }

  /// 01712345678 → ০১৭১২-৩৪৫৬৭৮
  static String phone(String raw) {
    final p = toAscii(raw).replaceAll(RegExp(r'\D'), '');
    if (p.length != 11) return digits(p);
    return digits('${p.substring(0, 5)}-${p.substring(5)}');
  }

  /// Never show a full NID after onboarding.
  static String maskNid(String nid) {
    final p = toAscii(nid).replaceAll(RegExp(r'\D'), '');
    final last = p.length >= 4 ? p.substring(p.length - 4) : p;
    return '•••• •••• ${digits(last)}';
  }
}
