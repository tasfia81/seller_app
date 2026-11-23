/// App-wide configuration.
abstract final class AppConfig {
  static const String appName = 'স্ট্রিট সেলস · বিনিয়োগ';

  /// Server address. Default suits the Android emulator talking to a backend on
  /// the same computer. On a real phone or for production pass it at build time:
  /// `flutter run --dart-define=API_URL=https://api.example.com/api/v1`
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');

  /// Login and sign-up use the real server. The dashboard screens still read
  /// [DemoInvestorRepository] until they are connected (next phase); actions
  /// that need the server there say so honestly instead of pretending.
  static const bool demoMode = true;

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
