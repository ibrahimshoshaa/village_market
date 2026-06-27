import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/auth_providers.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'سوق القرية',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'سجّل دخولك برقم موبايلك',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(height: 48),

              // Phone input
              Text(
                'رقم الموبايل',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixText: '+20 ',
                  prefixStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Send OTP button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('إرسال رمز التحقق'),
                ),
              ),
              const Spacer(),

              Center(
                child: Text(
                  'بالمتابعة، أنت توافق على شروط الاستخدام',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    // Validate
    if (phone.isEmpty) {
      _showError('من فضلك أدخل رقم موبايلك');
      return;
    }

    // Remove any leading zeros or spaces then validate length
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      _showError('رقم الموبايل غير صحيح');
      return;
    }

    // Format to E.164: +20 + 10 digits (remove leading 0 if present)
    final normalized = digitsOnly.startsWith('0')
        ? digitsOnly.substring(1) // "01025269977" → "1025269977"
        : digitsOnly;
    final fullPhone = '+20$normalized'; // → "+201025269977"

    setState(() => _isLoading = true);

    await ref.read(otpControllerProvider.notifier).sendOtp(
      phoneNumber: fullPhone,
      onCodeSent: () {
        setState(() => _isLoading = false);
        context.push(
          AppRoutes.otpVerification,
          extra: fullPhone,
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        // نعرض الكود الفعلي في الـ debug — غيّره لـ _mapAuthError في الـ production
        debugPrint('🔴 Firebase Auth Error Code: $error');
        _showError(_mapAuthError(error));
      },
    );
  }

  String _mapAuthError(String code) => switch (code) {
        'invalid-phone-number' => 'رقم الموبايل غير صحيح',
        'too-many-requests' => 'محاولات كثيرة جداً، حاول بعد شوية',
        'network-request-failed' => 'تأكد من اتصالك بالإنترنت',
        // أكواد شائعة تانية من Firebase
        'missing-phone-number' => 'من فضلك أدخل رقم موبايلك',
        'quota-exceeded' => 'تم تجاوز الحد المسموح، حاول غداً',
        'user-disabled' => 'هذا الحساب معطّل',
        'operation-not-allowed' => 'تسجيل الدخول بالموبايل غير مفعّل حالياً',
        'app-not-authorized' => 'التطبيق غير مصرح له — تأكد من SHA-1',
        'invalid-app-credential' => 'مشكلة في إعدادات التطبيق (App Check / SHA-1)',
        'missing-client-identifier' => 'مشكلة في SHA-1 أو reCAPTCHA',
        // عرض الكود الخام لأي حاجة تانية عشان نعرف المشكلة
        _ => 'خطأ: $code',
      };

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
