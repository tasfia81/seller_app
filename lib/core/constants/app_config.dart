/// App-wide configuration for the UI phase.
abstract final class AppConfig {
  /// When true, repositories return clearly labelled demo fixtures and a
  /// "ডেমো" banner is shown. Set to false once the FastAPI backend is wired:
  /// screens will then show "not connected yet" states instead of data.
  static const bool demoMode = true;

  /// UI phase: login, password reset and the seller application accept any
  /// input so every screen can be walked through. Set to false to turn all
  /// auth/onboarding validation back on (the rules are still in Validators).
  static const bool skipAuthValidation = true;

  /// Minimum seller age. Confirm with business policy and applicable law.
  static const int minimumSellerAge = 18;

  static const String appName = 'স্ট্রিট সেলস';
}
