import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/intro/intro_screen.dart';
import '../../features/intro/splash_screen.dart';
import '../../features/intro/welcome_screen.dart';
import '../../features/ledger/ledger_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/portfolio/portfolio_screen.dart';
import '../../features/portfolio/product_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/sellers/sellers_screen.dart';
import '../../features/signup/signup_agreement_screen.dart';
import '../../features/signup/signup_info_screen.dart';
import '../../features/signup/signup_kyc_screen.dart';
import '../../features/signup/signup_mobile_screen.dart';
import '../../features/signup/signup_payout_screen.dart';
import '../../features/signup/signup_status_screen.dart';
import '../../features/withdraw/withdraw_screen.dart';
import 'app_routes.dart';
import 'main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Sends each user to the part of the app their account allows:
/// signed out → welcome/login/sign-up, applicant → application status,
/// approved investor → the investor app.
String? authRedirect(AuthState auth, String location) {
  switch (auth) {
    case AuthUnknown():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SignedOut():
      return AppRoutes.public.contains(location) ? null : AppRoutes.welcome;
    case SignedIn(:final user) when !user.isInvestor:
      return AppRoutes.applicant.contains(location) ? null : AppRoutes.signupStatus;
    case SignedIn():
      return AppRoutes.public.contains(location) || location == AppRoutes.signupStatus ? AppRoutes.home : null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the auth state changes, without rebuilding the router.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      // The splash itself moves on once the session is known (fonts + restore).
      if (state.matchedLocation == AppRoutes.splash && auth is! AuthUnknown) return null;
      return authRedirect(auth, state.matchedLocation);
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.intro, builder: (_, __) => const IntroScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),

      GoRoute(path: AppRoutes.signupMobile, builder: (_, __) => const SignupMobileScreen()),
      GoRoute(path: AppRoutes.signupInfo, builder: (_, __) => const SignupInfoScreen()),
      GoRoute(path: AppRoutes.signupKyc, builder: (_, __) => const SignupKycScreen()),
      GoRoute(path: AppRoutes.signupPayout, builder: (_, __) => const SignupPayoutScreen()),
      GoRoute(path: AppRoutes.signupAgreement, builder: (_, __) => const SignupAgreementScreen()),
      GoRoute(path: AppRoutes.signupStatus, builder: (_, __) => const SignupStatusScreen()),

      // Main app: 4 tabs, each keeps its own state and scroll position.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.portfolio, builder: (_, __) => const PortfolioScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.ledger, builder: (_, __) => const LedgerScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.report, builder: (_, __) => const ReportScreen())]),
        ],
      ),

      // Full-screen pages (no bottom bar).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.product,
        builder: (_, s) => ProductScreen(productId: s.pathParameters['id'] ?? ''),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: AppRoutes.sellers, builder: (_, __) => const SellersScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: AppRoutes.withdraw, builder: (_, __) => const WithdrawScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
    ],
  );
});
