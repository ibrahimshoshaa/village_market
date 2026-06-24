import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// TODO: implement per Phase 3.1 — 6-digit OTP input feeding
/// AuthRemoteDataSource.verifyOtp(), then AuthRepositoryImpl.verifyOtpAndSync()
/// to auto-create the /users document on first sign-in.
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'رمز التحقق',
      icon: Icons.sms_outlined,
    );
  }
}
