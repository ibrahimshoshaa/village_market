import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Cart extends Equatable {
  final List<CartItem> items;
  final double deliveryFee;

  const Cart({
    this.items = const [],
    this.deliveryFee = 0,
  });

  // ===== Computed Properties =====

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// كل الأيتمز من نفس المحل (شرط أساسي)
  String? get shopId => items.isEmpty ? null : items.first.shopId;
  String? get shopName => items.isEmpty ? null : items.first.shopName;

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  double get totalAmount => subtotal + deliveryFee;

  /// هل الأيتم الجديد من نفس المحل؟
  bool canAddFromShop(String newShopId) {
    if (isEmpty) return true;
    return shopId == newShopId;
  }

  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((i) => i.productId == productId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [items, deliveryFee];
}
