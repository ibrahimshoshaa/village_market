import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../providers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'cash';
  String _deliveryType = 'delivery';
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);

    ref.listen(checkoutControllerProvider, (_, next) {
      if (next is AsyncData<String?> && next.value != null) {
        context.go(AppRoutes.orderTrackingPath(next.value!));
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(next.error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'طريقة الاستلام'),
            _DeliveryTypeSelector(
              selected: _deliveryType,
              onChanged: (v) => setState(() => _deliveryType = v),
            ),
            const SizedBox(height: 20),
            if (_deliveryType == 'delivery') ...[
              _SectionTitle(title: 'عنوان التوصيل'),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'مثال: بجوار مسجد النور، شارع الجمهورية',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
            ],
            _SectionTitle(title: 'طريقة الدفع'),
            _PaymentMethodSelector(
              selected: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'ملاحظة للتاجر (اختياري)'),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'أي تعليمات خاصة؟',
              ),
            ),
            const SizedBox(height: 24),
            _PriceSummary(
              subtotal: cart.subtotal,
              deliveryFee: _deliveryType == 'delivery' ? 10.0 : 0,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: checkoutState.isLoading ? null : _submitOrder,
                child: checkoutState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('تأكيد الطلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitOrder() {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) return;

    if (_deliveryType == 'delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل عنوان التوصيل')),
      );
      return;
    }

    final request = PlaceOrderRequest(
      shopId: cart.shopId!,
      items: cart.items
          .map(
            (i) => OrderItemRequest(
              productId: i.productId,
              quantity: i.quantity,
            ),
          )
          .toList(),
      deliveryType: _deliveryType,
      dropoffLat: 30.0444,
      dropoffLng: 31.2357,
      dropoffAddressLabel: _addressController.text.trim().isEmpty
          ? 'استلام من المحل'
          : _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      customerNote: _noteController.text.trim(),
    );

    ref.read(checkoutControllerProvider.notifier).submitOrder(request);
  }

  String _errorMessage(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('failed-precondition')) return 'الكمية غير متوفرة';
    if (msg.contains('unauthenticated')) return 'يجب تسجيل الدخول أولاً';
    if (msg.contains('unavailable')) return 'تأكد من اتصالك بالإنترنت';
    return 'حدث خطأ، حاول مرة أخرى';
  }
}

// ===== Helper Widgets =====

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DeliveryTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DeliveryTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            label: 'توصيل للباب',
            icon: Icons.delivery_dining_outlined,
            selected: selected == 'delivery',
            onTap: () => onChanged('delivery'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeCard(
            label: 'استلام من المحل',
            icon: Icons.storefront_outlined,
            selected: selected == 'pickup',
            onTap: () => onChanged('pickup'),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentTile(
          label: 'كاش عند الاستلام',
          icon: Icons.payments_outlined,
          value: 'cash',
          selected: selected,
          onChanged: onChanged,
        ),
        _PaymentTile(
          label: 'دفع إلكتروني (قريباً)',
          icon: Icons.credit_card_outlined,
          value: 'gateway',
          selected: selected,
          onChanged: onChanged,
          disabled: true,
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool disabled;

  const _PaymentTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: selected,
      onChanged: disabled ? null : (v) => onChanged(v!),
      title: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  disabled ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      activeColor: AppColors.primary,
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;

  const _PriceSummary({required this.subtotal, required this.deliveryFee});

  @override
  Widget build(BuildContext context) {
    final total = subtotal + deliveryFee;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _PriceRow(label: 'المجموع الفرعي', amount: subtotal),
          if (deliveryFee > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(label: 'رسوم التوصيل', amount: deliveryFee),
          ],
          const Divider(height: 20),
          _PriceRow(
            label: 'الإجمالي',
            amount: total,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          formatEGP(amount),
          style: isTotal
              ? Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.primary)
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
