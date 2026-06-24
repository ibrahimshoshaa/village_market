import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../orders/domain/entities/order.dart';
import '../providers/driver_providers.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAvailable = true;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'طلبات متاحة'),
            Tab(text: 'توصيلاتي'),
          ],
        ),
        actions: [
          // زرار الـ availability
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  _isAvailable ? 'متاح' : 'غير متاح',
                  style: TextStyle(
                    color: _isAvailable ? AppColors.statusDelivered : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  activeColor: AppColors.statusDelivered,
                  onChanged: (val) {
                    setState(() => _isAvailable = val);
                    ref
                        .read(driverOrderControllerProvider.notifier)
                        .toggleAvailability(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableDeliveriesTab(),
          _MyDeliveriesTab(),
        ],
      ),
    );
  }
}

/// تاب الطلبات المتاحة
class _AvailableDeliveriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(availableDeliveriesProvider);

    return ordersAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) => orders.isEmpty
          ? _buildEmpty(context, 'مفيش طلبات متاحة دلوقتي')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _AvailableOrderCard(order: orders[i]),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delivery_dining_outlined,
              size: 72, color: AppColors.imagePlaceholderIcon),
          const SizedBox(height: 16),
          Text(msg, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// كارت طلب متاح
class _AvailableOrderCard extends ConsumerWidget {
  final AppOrder order;
  const _AvailableOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(driverOrderControllerProvider.notifier);
    final state = ref.watch(driverOrderControllerProvider);

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
          // رقم الطلب + المحل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderNumber,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(order.shopName,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),

          // العنوان
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.dropoffAddressLabel,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // الإجمالي + رسوم التوصيل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('إجمالي الطلب: ${formatEGP(order.pricing.totalAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('توصيل: ${formatEGP(order.pricing.deliveryFee)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // زرار قبول
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () => controller.acceptDelivery(order.orderId),
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('قبول التوصيل'),
            ),
          ),
        ],
      ),
    );
  }
}

/// تاب توصيلاتي النشطة
class _MyDeliveriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myActiveDeliveriesProvider);

    return ordersAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (orders) => orders.isEmpty
          ? Center(
              child: Text('مفيش توصيلات نشطة',
                  style: Theme.of(context).textTheme.bodyLarge),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ActiveDeliveryCard(order: orders[i]),
            ),
    );
  }
}

/// كارت التوصيل النشط
class _ActiveDeliveryCard extends ConsumerWidget {
  final AppOrder order;
  const _ActiveDeliveryCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(driverOrderControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: order.status.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الحالة
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: order.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.arabicLabel,
              style: TextStyle(
                color: order.status.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(order.orderNumber,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('من: ${order.shopName}',
              style: Theme.of(context).textTheme.bodyMedium),
          Text('إلى: ${order.dropoffAddressLabel}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),

          // اتصال بالزبون
          OutlinedButton.icon(
            onPressed: () => context.push(
              AppRoutes.orderTrackingPath(order.orderId),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('عرض تفاصيل الطلب'),
          ),
          const SizedBox(height: 8),

          // زرار تحديث الحالة
          if (order.status.name == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    controller.updateStatus(order.orderId, 'in_transit'),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('بدأت التوصيل'),
              ),
            ),

          if (order.status.name == 'inTransit')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusDelivered,
                ),
                onPressed: () =>
                    controller.updateStatus(order.orderId, 'delivered'),
                icon: const Icon(Icons.done_all),
                label: const Text('تم التوصيل'),
              ),
            ),
        ],
      ),
    );
  }
}
