import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 1.4/3.1 — first-time users with role ==
/// UserRole.unknown land here. Choosing villager/vendor/driver writes the
/// role field to /users/{uid}, which triggers the onUserWrite Cloud
/// Function (Phase 4.4) to sync the custom claim, then the router redirects
/// to the appropriate role home.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'اختر نوع الحساب',
      icon: Icons.how_to_reg_outlined,
    );
  }
}
