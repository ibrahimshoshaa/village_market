import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.2 — CRUD for shops/{shopId}/products,
/// including the compress-before-upload flow from Phase 5.2.
class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'إدارة المنتجات',
      icon: Icons.inventory_2_outlined,
    );
  }
}
