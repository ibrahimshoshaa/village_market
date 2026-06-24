import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../features/auth/domain/entities/user_role.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header الصورة والاسم =====
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0]
                              : '؟',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  user.phoneNumber,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                _RoleBadge(role: user.role),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ===== قسم الحساب =====
          _SectionHeader(title: 'الحساب'),
          _ProfileTile(
            icon: Icons.person_outline,
            label: 'تعديل الاسم',
            onTap: () => _showEditNameSheet(context, ref, user.displayName),
          ),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            label: 'طلباتي',
            onTap: () => context.push(AppRoutes.orders),
          ),
          _ProfileTile(
            icon: Icons.chat_bubble_outline,
            label: 'المحادثات',
            onTap: () => context.push(AppRoutes.chatList),
          ),

          // ===== قسم خاص بالتاجر =====
          if (user.role == UserRole.vendor) ...[
            const SizedBox(height: 8),
            _SectionHeader(title: 'إدارة المحل'),
            _ProfileTile(
              icon: Icons.dashboard_outlined,
              label: 'لوحة تحكم التاجر',
              onTap: () => context.go(AppRoutes.vendorHome),
            ),
            _ProfileTile(
              icon: Icons.inventory_2_outlined,
              label: 'إدارة المنتجات',
              onTap: () => context.push(AppRoutes.vendorProducts),
            ),
          ],

          // ===== قسم خاص بالسائق =====
          if (user.role == UserRole.driver) ...[
            const SizedBox(height: 8),
            _SectionHeader(title: 'التوصيل'),
            _ProfileTile(
              icon: Icons.delivery_dining_outlined,
              label: 'لوحة السائق',
              onTap: () => context.go(AppRoutes.driverHome),
            ),
          ],

          // ===== قسم الإعدادات =====
          const SizedBox(height: 8),
          _SectionHeader(title: 'إعدادات'),
          _ProfileTile(
            icon: Icons.info_outline,
            label: 'عن التطبيق',
            onTap: () => _showAboutDialog(context),
          ),

          // ===== تسجيل الخروج =====
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
          const SizedBox(height: 16),

          // version
          Center(
            child: Text(
              'سوق القرية v1.0.0',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameSheet(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعديل الاسم',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'اسمك'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(profileControllerProvider.notifier)
                      .updateDisplayName(controller.text);
                },
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileControllerProvider.notifier).signOut();
            },
            child: const Text('خروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'سوق القرية',
      applicationVersion: '1.0.0',
      applicationLegalese: 'جميع الحقوق محفوظة © 2026',
    );
  }
}

// ===== Helper Widgets =====

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.vendor => 'تاجر',
      UserRole.driver => 'سائق',
      UserRole.admin => 'أدمن',
      _ => 'زبون',
    };
    final color = switch (role) {
      UserRole.vendor => AppColors.secondary,
      UserRole.driver => const Color(0xFF1565C0),
      UserRole.admin => AppColors.error,
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing:
            const Icon(Icons.chevron_left, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
