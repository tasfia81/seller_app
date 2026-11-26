import '../../core/constants/app_config.dart';
import '../../features/auth/data/seller_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/cash_handover/presentation/cash_handover_screen.dart';
import '../../features/day_closing/presentation/day_closing_screen.dart';
import '../../features/earnings/presentation/my_earnings_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/intro/presentation/intro_screen.dart';
import '../../features/intro/presentation/welcome_screen.dart';
import '../../features/inventory/presentation/my_inventory_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/application_status_screen.dart';
import '../../features/onboarding/presentation/application_submitted_screen.dart';
import '../../features/onboarding/presentation/registration_screen.dart';
import '../../features/products/presentation/my_products_screen.dart';
import '../../features/products/presentation/product_details_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/sales/presentation/quick_sale_screen.dart';
import '../../features/sales/presentation/sale_details_screen.dart';
import '../../features/sales/presentation/sale_success_screen.dart';
import '../../features/sales/presentation/sales_history_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/stock_returns/presentation/stock_return_screen.dart';
import '../../features/support/presentation/support_chat_screen.dart';
import '../../features/support/presentation/support_home_screen.dart';
import '../../shared/models/sale.dart';
import 'app_routes.dart';
import 'main_shell.dart';
import 'not_found_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sellerSessionProvider);
  final router = GoRouter(
    refreshListenable: AppConfig.previewAuth ? null : session,
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    redirect: (_, state) {
      if (AppConfig.previewAuth) return null;
      final path = state.uri.path;
      const public = {
        AppRoutes.splash, AppRoutes.intro, AppRoutes.welcome,
        AppRoutes.login, AppRoutes.forgotPassword, AppRoutes.register,
      };
      if (public.contains(path)) return null;
      if (session.user == null) return AppRoutes.login;
      if (!session.active && path != AppRoutes.applicationStatus &&
          path != AppRoutes.applicationSubmitted) {
        return AppRoutes.applicationStatus;
      }
      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.intro, builder: (_, __) => const IntroScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegistrationScreen()),
      GoRoute(
          path: AppRoutes.applicationSubmitted,
          builder: (_, __) => const ApplicationSubmittedScreen()),
      GoRoute(
          path: AppRoutes.applicationStatus, builder: (_, __) => const ApplicationStatusScreen()),

      // Main app: 4 tabs, each keeps its own state and scroll position.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.products, builder: (_, __) => const MyProductsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.sales, builder: (_, __) => const SalesHistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.account, builder: (_, __) => const AccountScreen()),
          ]),
        ],
      ),

      // Full-screen pages (root navigator, no bottom bar).
      GoRoute(
        path: AppRoutes.productDetails,
        builder: (_, s) => ProductDetailsScreen(productId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.quickSale,
        builder: (_, s) => QuickSaleScreen(productId: s.uri.queryParameters['productId']),
      ),
      GoRoute(
        path: AppRoutes.saleSuccess,
        builder: (_, s) => SaleSuccessScreen(sale: s.extra is Sale ? s.extra as Sale : null),
      ),
      GoRoute(
        path: AppRoutes.saleDetails,
        builder: (_, s) => SaleDetailsScreen(
          saleId: s.pathParameters['id']!,
          initial: s.extra is Sale ? s.extra as Sale : null,
        ),
      ),
      GoRoute(path: AppRoutes.earnings, builder: (_, __) => const MyEarningsScreen()),
      GoRoute(path: AppRoutes.inventory, builder: (_, __) => const MyInventoryScreen()),
      GoRoute(
        path: AppRoutes.stockReturn,
        builder: (_, s) => StockReturnScreen(productId: s.uri.queryParameters['productId']),
      ),
      GoRoute(path: AppRoutes.cashHandover, builder: (_, __) => const CashHandoverScreen()),
      GoRoute(path: AppRoutes.dayClosing, builder: (_, __) => const DayClosingScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.support, builder: (_, __) => const SupportHomeScreen()),
      GoRoute(
        path: AppRoutes.supportChat,
        builder: (_, s) => SupportChatScreen(
          threadId: s.uri.queryParameters['id'],
          topic: s.uri.queryParameters['topic'],
          topicLabel: s.uri.queryParameters['label'],
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
