import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 3.2 — Hive-backed cart list (CartNotifier),
/// totals breakdown (subtotal/delivery/total), and checkout button that
/// invokes the placeOrder callable Cloud Function.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'السلة',
      icon: Icons.shopping_cart_outlined,
    );
  }
}
