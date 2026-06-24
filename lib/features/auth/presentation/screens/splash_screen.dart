import 'package:flutter/material.dart';

/// Shown while auth state is still resolving. See AuthGuard in
/// route_guards.dart (Phase 1.4) — this is the redirect target for
/// `authState.isLoading`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'سوق القرية',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
