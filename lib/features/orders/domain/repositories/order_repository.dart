import '../entities/order.dart';

abstract class OrderRepository {
  /// يبعت الطلب للـ Cloud Function
  Future<String> placeOrder(PlaceOrderRequest request);

  /// Stream لمتابعة حالة طلب معين
  Stream<AppOrder> watchOrder(String orderId);

  /// قائمة طلبات الزبون
  Stream<List<AppOrder>> watchCustomerOrders(String customerId);

  /// قائمة طلبات المحل (للتاجر)
  Stream<List<AppOrder>> watchShopOrders(String shopId, {String? statusFilter});

  /// الطلبات المتاحة للسائق
  Stream<List<AppOrder>> watchAvailableDeliveries();

  /// تحديث حالة الطلب (للتاجر والسائق)
  Future<void> updateOrderStatus(String orderId, String newStatus);
}

class PlaceOrderRequest {
  final String shopId;
  final List<OrderItemRequest> items;
  final String deliveryType;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddressLabel;
  final String paymentMethod;
  final String customerNote;

  const PlaceOrderRequest({
    required this.shopId,
    required this.items,
    required this.deliveryType,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddressLabel,
    required this.paymentMethod,
    this.customerNote = '',
  });

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'items': items.map((i) => i.toMap()).toList(),
        'deliveryType': deliveryType,
        'dropoffGeopoint': {'lat': dropoffLat, 'lng': dropoffLng},
        'dropoffAddressLabel': dropoffAddressLabel,
        'paymentMethod': paymentMethod,
        'customerNote': customerNote,
      };
}

class OrderItemRequest {
  final String productId;
  final int quantity;

  const OrderItemRequest({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'quantity': quantity,
      };
}
