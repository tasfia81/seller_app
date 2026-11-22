/// App-wide configuration for the UI phase.
abstract final class AppConfig {
  static const String appName = 'স্ট্রিট সেলস · বিনিয়োগ';

  /// Data comes from [DemoInvestorRepository] while true. Actions that would
  /// need the server (withdraw request, PDF, new investment) say so honestly
  /// instead of pretending to succeed.
  static const bool demoMode = true;

  /// UI phase: sign-up steps accept any input so every screen can be walked
  /// through. Set to false to turn validation on.
  static const bool skipValidation = true;

  /// Business terms shown in the app — confirm with the final contract.
  static const int profitSharePercent = 50;
  static const int sellerCommissionPercent = 40;
  static const int payoutDayOfMonth = 5;
  static const int capitalNoticeDays = 30;

  /// Placeholders until the real details are provided.
  static const String tradeLicense = '[ট্রেড লাইসেন্স নম্বর]';
  static const String officeAddress = '[অফিসের ঠিকানা]';
  static const String helpline = '[হেল্পলাইন নম্বর]';
  static const String minimumInvestment = '[সর্বনিম্ন বিনিয়োগ]';
}
