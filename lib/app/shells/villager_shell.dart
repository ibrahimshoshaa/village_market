import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

/// Shell for the villager (customer) role's main tabs. Bottom nav follows
/// the Phase 7.1 accessibility guideline: max 4 items, always labeled
/// (never icon-only) for a non-tech-savvy audience.
class VillagerShell extends StatelessWidget {
  final Widget child;
  const VillagerShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.cart)) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.cart);
            case 2:
              context.go('/orders');
            case 3:
              context.go(AppRoutes.profile);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'السلة'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}
