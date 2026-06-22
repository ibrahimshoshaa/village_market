import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 6.1 — shop/craftsman approval queue,
/// user management (isActive toggle), and dispute resolution.
/// Consider building this as a separate Flutter Web target sharing the
/// domain/data layers, per the blueprint's closing build-order notes.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'لوحة تحكم الإدارة',
      icon: Icons.admin_panel_settings_outlined,
    );
  }
}
