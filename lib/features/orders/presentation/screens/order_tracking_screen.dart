import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../providers/order_providers.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(watchOrderProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الطلب')),
      body: orderAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (order) => _OrderTrackingBody(order: order),
      ),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  final AppOrder order;
  const _OrderTrackingBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ===== بانر الحالة الكبير =====
          _StatusBanner(status: order.status),
          const SizedBox(height: 20),

          // ===== معلومات الطلب =====
          _InfoCard(
            children: [
              _InfoRow(label: 'رقم الطلب', value: order.orderNumber),
              _InfoRow(label: 'المحل', value: order.shopName),
              _InfoRow(label: 'طريقة الاستلام',
                  value: order.deliveryType == 'delivery'
                      ? 'توصيل للباب'
                      : 'استلام من المحل'),
              _InfoRow(label: 'العنوان', value: order.dropoffAddressLabel),
              if (order.customerNote.isNotEmpty)
                _InfoRow(label: 'ملاحظة', value: order.customerNote),
            ],
          ),
          const SizedBox(height: 16),

          // ===== المنتجات =====
          _InfoCard(
            title: 'المنتجات',
            children: [
              ...order.items.map((item) => _ItemRow(item: item)),
              const Divider(),
              _InfoRow(
                label: 'المجموع الفرعي',
                value: formatEGP(order.pricing.subtotal),
              ),
              if (order.pricing.deliveryFee > 0)
                _InfoRow(
                  label: 'التوصيل',
                  value: formatEGP(order.pricing.deliveryFee),
                ),
              _InfoRow(
                label: 'الإجمالي',
                value: formatEGP(order.pricing.totalAmount),
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== زرار إلغاء (لو الطلب لسه pending) =====
          if (order.status == OrderStatus.pending)
            _CancelButton(orderId: order.orderId),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(status.icon, size: 56, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            status.arabicLabel,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _InfoCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Divider(),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? AppColors.primary : AppColors.textPrimary,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('${item.quantity}×',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.productName,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(formatEGP(item.lineTotal),
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CancelButton extends ConsumerWidget {
  final String orderId;
  const _CancelButton({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          foregroundColor: AppColors.error,
        ),
        onPressed: () => _confirmCancel(context, ref),
        child: const Text('إلغاء الطلب'),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text(
            'هل تريد إلغاء الطلب؟ لن تتمكن من التراجع عن هذا.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لأ، ارجع'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(orderStatusControllerProvider.notifier)
                  .updateStatus(orderId, 'cancelled');
            },
            child: const Text('إلغاء الطلب',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
