import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.2/7.3 — paginated GridView/ListView of
/// approved & active shops, with category filter and prefix search
/// (collectionGroup query, Phase 2.7). This is the villager home screen.
class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'سوق القرية',
      icon: Icons.storefront_outlined,
    );
  }
}
