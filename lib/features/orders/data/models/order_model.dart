import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

class AppOrderModel {
  static AppOrder fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((i) => OrderItem(
              productId: i['productId'] ?? '',
              productName: i['productName'] ?? '',
              imageUrl: i['imageUrl'],
              unitPrice: (i['unitPrice'] as num).toDouble(),
              quantity: (i['quantity'] as num).toInt(),
              lineTotal: (i['lineTotal'] as num).toDouble(),
            ),)
        .toList();

    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final delivery = data['delivery'] as Map<String, dynamic>? ?? {};

    return AppOrder(
      orderId: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      vendorId: data['vendorId'] ?? '',
      driverId: data['driverId'],
      driverName: data['driverName'],
      items: itemsList,
      pricing: OrderPricing(
        subtotal: (pricing['subtotal'] as num? ?? 0).toDouble(),
        deliveryFee: (pricing['deliveryFee'] as num? ?? 0).toDouble(),
        totalAmount: (pricing['totalAmount'] as num? ?? 0).toDouble(),
      ),
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      deliveryType: delivery['type'] ?? 'delivery',
      dropoffAddressLabel: delivery['dropoffAddressLabel'] ?? '',
      paymentMethod: (data['payment'] as Map?)
              ?.entries
              .firstWhere((e) => e.key == 'method',
                  orElse: () => const MapEntry('method', 'cash'),)
              .value ??
          'cash',
      customerNote: data['customerNote'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }
}
