import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.2 — shop header (logo, hours, rating),
/// product grid (Phase 7.2/7.3), and "اتصل بالتاجر" call button
/// (Phase 7.1 — trusted/prominent for this audience).
class ShopDetailScreen extends StatelessWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'تفاصيل المحل ($shopId)',
      icon: Icons.store_outlined,
    );
  }
}
