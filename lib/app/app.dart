import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
// import '../l10n/app_localizations.dart'; // uncomment once `flutter gen-l10n` has run

/// Root widget. Forces RTL directionality regardless of device locale,
/// since Arabic is the app's primary (and currently only fully-supported)
/// language — see Phase 1.5 of the blueprint for the full localization strategy.
class VillageMarketApp extends ConsumerWidget {
  const VillageMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'سوق القرية',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
        // AppLocalizations.delegate, // uncomment once generated
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.light,
    );
  }
}
