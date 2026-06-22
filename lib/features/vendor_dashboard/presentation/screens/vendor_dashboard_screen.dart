import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.4/6.1 — incoming orders queue (status ==
/// pending, vendorId == me), accept/reject actions, and a link to
/// manage_products_screen.
class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'لوحة تحكم التاجر',
      icon: Icons.dashboard_outlined,
    );
  }
}
