import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingShopsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'الإحصائيات'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('موافقات'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingCount),
                  ],
                ],
              ),
            ),
            const Tab(text: 'المستخدمين'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StatsTab(),
          _ShopApprovalTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(appStatsProvider);

    return statsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (stats) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'إجمالي المستخدمين',
                    value: '${stats.totalUsers}',
                    icon: Icons.people_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'المحلات النشطة',
                    value: '${stats.totalShops}',
                    icon: Icons.storefront_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'إجمالي الطلبات',
                    value: '${stats.totalOrders}',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'محلات بانتظار الموافقة',
                    value: '${stats.pendingShops}',
                    icon: Icons.pending_outlined,
                    color: stats.pendingShops > 0
                        ? AppColors.error
                        : const Color(0xFF1B7A43),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الإحصائيات بتتحدث كل مرة تفتح الشاشة.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ShopApprovalTab extends ConsumerWidget {
  const _ShopApprovalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(pendingShopsProvider);

    return shopsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (shops) => shops.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: Color(0xFF1B7A43),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مفيش محلات بانتظار الموافقة',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ShopApprovalCard(shop: shops[i]),
            ),
    );
  }
}

class _ShopApprovalCard extends ConsumerWidget {
  final PendingShop shop;
  const _ShopApprovalCard({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminControllerProvider.notifier);
    final state = ref.watch(adminControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.shopName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shop.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'صاحب المحل: ${shop.ownerName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: state.isLoading
                      ? null
                      : () => _confirmReject(context, controller),
                  child: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => controller.approveShop(shop.shopId),
                  child: const Text('الموافقة'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رفض المحل'),
        content: Text('هل تريد رفض "${shop.shopName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.rejectShop(shop.shopId);
            },
            child: const Text('رفض', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (users) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _UserTile(user: users[i]),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AdminUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminControllerProvider.notifier);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
        child: Text(
          user.displayName.isNotEmpty ? user.displayName[0] : '؟',
          style: TextStyle(
            color: _roleColor(user.role),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          color:
              user.isActive ? AppColors.textPrimary : AppColors.textSecondary,
          decoration: user.isActive ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Text('${user.phoneNumber} · ${_roleLabel(user.role)}'),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'toggle') {
            controller.toggleUserStatus(user.uid, user.isActive);
          } else {
            controller.changeUserRole(user.uid, action);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'toggle',
            child: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'villager', child: Text('زبون')),
          const PopupMenuItem(value: 'vendor', child: Text('تاجر')),
          const PopupMenuItem(value: 'driver', child: Text('سائق')),
          const PopupMenuItem(value: 'admin', child: Text('أدمن')),
        ],
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
        'vendor' => AppColors.secondary,
        'driver' => const Color(0xFF1565C0),
        'admin' => AppColors.error,
        _ => AppColors.primary,
      };

  String _roleLabel(String role) => switch (role) {
        'vendor' => 'تاجر',
        'driver' => 'سائق',
        'admin' => 'أدمن',
        _ => 'زبون',
      };
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
