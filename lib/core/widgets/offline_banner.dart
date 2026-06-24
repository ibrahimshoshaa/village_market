import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_banner.g.dart';

@riverpod
Stream<bool> isOnline(Ref ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.every((r) => r == ConnectivityResult.none));
}

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final offline = isOnlineAsync.valueOrNull == false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: offline ? 38 : 0,
      color: const Color(0xFFFFF3CD),
      child: offline
          ? const Center(
              child: Text(
                'أنت غير متصل بالإنترنت — سيتم المزامنة عند عودة الاتصال',
                style: TextStyle(fontSize: 13, color: Color(0xFF856404)),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}
