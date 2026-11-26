import 'package:flutter/foundation.dart' show kReleaseMode;

/// App-wide configuration for the UI phase.
abstract final class AppConfig {
  static const bool demoMode = previewAuth;

  /// Local UI preview. Release builds always use the backend for auth.
  static const bool previewAuth = !kReleaseMode && bool.fromEnvironment('PREVIEW_AUTH');
  static const bool skipAuthValidation = previewAuth;
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Minimum seller age. Confirm with business policy and applicable law.
  static const int minimumSellerAge = 18;

  static const String appName = 'স্ট্রিট সেলস';
}
