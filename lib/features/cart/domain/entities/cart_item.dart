import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String productId;
  final String shopId;
  final String shopName;
  final String productName;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [productId, shopId, quantity];
}
