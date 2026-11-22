import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class InvestorApp extends ConsumerWidget {
  const InvestorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return ScreenUtilInit(
      // Same frame as the design canvas (390 × 844).
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
        locale: const Locale('bn', 'BD'),
        supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) {
          // Respect system text size, but cap it so layouts stay intact.
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.25)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
