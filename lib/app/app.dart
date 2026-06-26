import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_providers.dart';

class VillageMarketApp extends ConsumerStatefulWidget {
  const VillageMarketApp({super.key});

  @override
  ConsumerState<VillageMarketApp> createState() => _VillageMarketAppState();
}

class _VillageMarketAppState extends ConsumerState<VillageMarketApp> {
  @override
  void initState() {
    super.initState();
    // استمع لـ Firebase Auth stream وحدّث الـ authStateProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateStreamProvider.future).then((_) {}).ignore();
      // Subscribe للـ stream
      ref.listen(authStateStreamProvider, (_, next) {
        ref.read(authStateProvider.notifier).state = next;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'سوق القرية',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
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
