import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/router/app_routes.dart';
import '../../core/widgets/offline_banner.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

class VillagerShell extends ConsumerWidget {
  final Widget child;
  const VillagerShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.cart) ||
        location.startsWith(AppRoutes.checkout)) return 1;
    if (location.startsWith(AppRoutes.orders) ||
        location.startsWith('/order/')) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: Column(
        children: [
          // بانر الأوف لاين — يظهر فقط لما يكون مش متصل
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.cart);
            case 2:
              context.go(AppRoutes.orders);
            case 3:
              context.go(AppRoutes.profile);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'السلة',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'طلباتي',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
