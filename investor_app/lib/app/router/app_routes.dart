abstract final class AppRoutes {
  static const splash = '/';
  static const intro = '/intro';
  static const welcome = '/welcome';

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
}
