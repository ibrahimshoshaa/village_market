import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 2.1 — display name, phone, address book
/// management, sign-out action, and (for vendors) a link to the vendor
/// dashboard.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'حسابي',
      icon: Icons.person_outline,
    );
  }
}
