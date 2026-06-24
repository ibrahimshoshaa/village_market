import 'package:hive_ce/hive.dart';
import '../../domain/entities/cart_item.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 0)
class CartItemModel extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String shopId;

  @HiveField(2)
  final String shopName;

  @HiveField(3)
  final String productName;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final double unitPrice;

  @HiveField(6)
  int quantity;

  CartItemModel({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.productName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  factory CartItemModel.fromEntity(CartItem item) => CartItemModel(
        productId: item.productId,
        shopId: item.shopId,
        shopName: item.shopName,
        productName: item.productName,
        imageUrl: item.imageUrl,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
      );

  CartItem toEntity() => CartItem(
        productId: productId,
        shopId: shopId,
        shopName: shopName,
        productName: productName,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        quantity: quantity,
      );
}
