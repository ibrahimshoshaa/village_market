import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.4/6.1 — available deliveries (status ==
/// accepted, driverId == null), self-assign action, and active delivery
/// tracking with map.
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'لوحة تحكم السائق',
      icon: Icons.delivery_dining_outlined,
    );
  }
}
