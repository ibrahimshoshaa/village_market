import 'package:equatable/equatable.dart';
import 'order_status.dart';

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class OrderPricing extends Equatable {
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;

  const OrderPricing({
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [subtotal, deliveryFee, totalAmount];
}

class AppOrder extends Equatable {
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String shopId;
  final String shopName;
  final String vendorId;
  final String? driverId;
  final String? driverName;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final OrderStatus status;
  final String deliveryType; // 'delivery' | 'pickup'
  final String dropoffAddressLabel;
  final String paymentMethod;
  final String customerNote;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const AppOrder({
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.shopId,
    required this.shopName,
    required this.vendorId,
    this.driverId,
    this.driverName,
    required this.items,
    required this.pricing,
    required this.status,
    required this.deliveryType,
    required this.dropoffAddressLabel,
    required this.paymentMethod,
    this.customerNote = '',
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
  });

  @override
  List<Object?> get props => [orderId, status];
}
