import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.4/2.8 — paginated list of the customer's
/// past orders, using the [customerId ASC, status ASC, createdAt DESC]
/// composite index.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'طلباتي',
      icon: Icons.receipt_long_outlined,
    );
  }
}
