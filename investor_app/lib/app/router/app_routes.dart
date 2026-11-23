abstract final class AppRoutes {
  static const splash = '/';
  static const intro = '/intro';
  static const welcome = '/welcome';
  static const login = '/login';

  static const signupMobile = '/signup/mobile';
  static const signupInfo = '/signup/info';
  static const signupKyc = '/signup/kyc';
  static const signupPayout = '/signup/payout';
  static const signupAgreement = '/signup/agreement';
  static const signupStatus = '/signup/status';

  // Bottom-tab branches.
  static const home = '/home';
  static const portfolio = '/portfolio';
  static const ledger = '/ledger';
  static const report = '/report';

  // Full-screen pages.
  static const product = '/product/:id';
  static String productOf(String id) => '/product/$id';
  static const sellers = '/sellers';
  static const withdraw = '/withdraw';
  static const notifications = '/notifications';
  static const profile = '/profile';

  // Support chat (open to applicants too).
  static const support = '/support';
  static const supportChat = '/support/chat';
  static String supportThread(String id) => '$supportChat?id=${Uri.encodeQueryComponent(id)}';
  static String supportNew(String topic, String label) =>
      '$supportChat?topic=${Uri.encodeQueryComponent(topic)}&label=${Uri.encodeQueryComponent(label)}';

  /// Open to everyone who is not signed in.
  static const public = {splash, intro, welcome, login, signupMobile, signupInfo, signupKyc, signupPayout, signupAgreement};

  /// What a signed-in applicant (not yet approved) may see. The agreement step
  /// stays open so photo uploads can finish after the application is created.
  static const applicant = {signupAgreement, signupStatus, support, supportChat};
}
