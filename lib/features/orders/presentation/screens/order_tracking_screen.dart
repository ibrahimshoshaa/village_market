import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 3.2/7.1 — live order status via
/// watchOrder StreamProvider, with a large full-width colored status
/// banner (not small text) per the accessibility guidelines.
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'تتبع الطلب ($orderId)',
      icon: Icons.local_shipping_outlined,
    );
  }
}
