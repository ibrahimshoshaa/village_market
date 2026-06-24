import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../orders/domain/entities/order.dart';
import '../providers/vendor_providers.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopIdAsync = ref.watch(myShopIdProvider);

    return shopIdAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (shopId) {
        if (shopId == null) {
          return const Center(child: Text('مفيش محل مرتبط بحسابك'));
        }
        return _VendorDashboardBody(shopId: shopId);
      },
    );
  }
}

class _VendorDashboardBody extends ConsumerStatefulWidget {
  final String shopId;
  const _VendorDashboardBody({required this.shopId});

  @override
  ConsumerState<_VendorDashboardBody> createState() =>
      _VendorDashboardBodyState();
}

class _VendorDashboardBodyState extends ConsumerState<_VendorDashboardBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingOrdersProvider(widget.shopId));
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التاجر'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('طلبات جديدة'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingCount),
                  ],
                ],
              ),
            ),
            const Tab(text: 'كل الطلبات'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push(AppRoutes.vendorProducts),
            tooltip: 'إدارة المنتجات',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingOrdersTab(shopId: widget.shopId),
          _AllOrdersTab(shopId: widget.shopId),
        ],
      ),
    );
  }
}

/// تاب الطلبات الجديدة
class _PendingOrdersTab extends ConsumerWidget {
  final String shopId;
  const _PendingOrdersTab({required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pendingOrdersProvider(shopId));

    return ordersAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) => orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 72, color: AppColors.imagePlaceholderIcon),
                  const SizedBox(height: 16),
                  Text('مفيش طلبات جديدة دلوقتي',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _PendingOrderCard(order: orders[i]),
            ),
    );
  }
}

/// كارت الطلب الجديد مع قبول/رفض
class _PendingOrderCard extends ConsumerWidget {
  final AppOrder order;
  const _PendingOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(vendorOrderControllerProvider.notifier);
    final state = ref.watch(vendorOrderControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الطلب + وقت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                _timeAgo(order.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // الزبون
          Text('الزبون: ${order.customerName}',
              style: Theme.of(context).textTheme.bodyMedium),
          Text('العنوان: ${order.dropoffAddressLabel}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),

          // المنتجات
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${item.quantity}× ${item.productName} — ${formatEGP(item.lineTotal)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
          const Divider(height: 16),

          // الإجمالي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                formatEGP(order.pricing.totalAmount),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),

          if (order.customerNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ملاحظة: ${order.customerNote}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),

          // أزرار قبول/رفض
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
                      : () => _showRejectDialog(context, ref),
                  child: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => controller.acceptOrder(order.orderId),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('قبول الطلب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'مثال: المنتج غير متوفر حالياً',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(vendorOrderControllerProvider.notifier).rejectOrder(
                    order.orderId,
                    controller.text.trim().isEmpty
                        ? 'رفض التاجر الطلب'
                        : controller.text.trim(),
                  );
            },
            child: const Text('رفض', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

/// تاب كل الطلبات
class _AllOrdersTab extends ConsumerWidget {
  final String shopId;
  const _AllOrdersTab({required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allShopOrdersProvider(shopId));

    return ordersAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) => orders.isEmpty
          ? Center(
              child: Text('مفيش طلبات',
                  style: Theme.of(context).textTheme.bodyLarge),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OrderSummaryTile(order: orders[i]),
            ),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final AppOrder order;
  const _OrderSummaryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      tileColor: AppColors.surface,
      title: Text(order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(order.customerName),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatEGP(order.pricing.totalAmount),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: order.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order.status.arabicLabel,
              style: TextStyle(
                fontSize: 11,
                color: order.status.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.push(AppRoutes.orderTrackingPath(order.orderId)),
    );
  }
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
