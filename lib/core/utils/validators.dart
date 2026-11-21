import '../constants/app_config.dart' show AppConfig;
import 'bn_format.dart';

/// Local form validation. Messages are Bangla and user-facing.
abstract final class Validators {
  /// Wraps a validator used on auth/onboarding screens. Returns null (no
  /// validation) while [AppConfig.skipAuthValidation] is on.
  static String? Function(String?)? auth(String? Function(String?) v) =>
      AppConfig.skipAuthValidation ? null : v;

  static String? required(String? v, [String message = 'এই ঘরটি পূরণ করুন।']) =>
      (v == null || v.trim().isEmpty) ? message : null;

  static String normalizePhone(String v) =>
      BnFormat.toAscii(v).replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^\+?88'), '');

  /// Bangladeshi mobile: 01[3-9]XXXXXXXX
  static String? mobile(String? v) {
    if (v == null || v.trim().isEmpty) return 'মোবাইল নম্বর দিন।';
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(normalizePhone(v))
        ? null
        : 'সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।';
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
        ? null
        : 'সঠিক ইমেইল ঠিকানা দিন।';
  }

  static String? nid(String? v) {
    if (v == null || v.trim().isEmpty) return 'জাতীয় পরিচয়পত্র নম্বর দিন।';
    final d = BnFormat.toAscii(v).replaceAll(RegExp(r'\D'), '');
    return const [10, 13, 17].contains(d.length) ? null : '১০, ১৩ বা ১৭ সংখ্যার নম্বর দিন।';
  }

  static String? dateOfBirth(DateTime? dob, {DateTime? now}) {
    if (dob == null) return 'জন্মতারিখ দিন।';
    final today = now ?? DateTime.now();
    if (dob.isAfter(today)) return 'ভবিষ্যতের তারিখ দেওয়া যাবে না।';
    var age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    if (age < AppConfig.minimumSellerAge) {
      return 'আবেদনের জন্য বয়স কমপক্ষে ${BnFormat.digits('${AppConfig.minimumSellerAge}')} বছর হতে হবে।';
    }
    return null;
  }

  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasDigit(String v) => RegExp(r'\d').hasMatch(BnFormat.toAscii(v));
  static bool hasSymbol(String v) => RegExp(r'[^A-Za-z0-9ঀ-৿\s]').hasMatch(v);

  /// 0–4 strength score.
  static int passwordScore(String v) {
    var s = 0;
    if (hasMinLength(v)) s++;
    if (hasDigit(v)) s++;
    if (hasSymbol(v)) s++;
    if (v.length >= 12) s++;
    return s;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'পাসওয়ার্ড দিন।';
    if (!hasMinLength(v)) return 'কমপক্ষে ৮টি অক্ষর দিন।';
    if (!hasDigit(v)) return 'অন্তত একটি সংখ্যা দিন।';
    return null;
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'পাসওয়ার্ড আবার লিখুন।';
    return v == original ? null : 'দুটি পাসওয়ার্ড মিলছে না।';
  }
}
