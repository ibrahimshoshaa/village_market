import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 3.1 of the blueprint — phone number input
/// (E.164 format) feeding AuthRemoteDataSource.sendOtp(), then navigate to
/// AppRoutes.otpVerification on success.
class PhoneEntryScreen extends StatelessWidget {
  const PhoneEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'تسجيل الدخول',
      icon: Icons.phone_android_outlined,
    );
  }
}
