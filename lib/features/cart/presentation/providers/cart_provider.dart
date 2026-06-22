import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../data/models/cart_item_model.dart';

part 'cart_provider.g.dart';

/// الكارت محلي بالكامل (Hive) — مش بيلمس Firestore
/// لحد ما المستخدم يدوس "تأكيد الطلب"، عندها بس
/// بنبعت للـ placeOrder Cloud Function.
@riverpod
class CartNotifier extends _$CartNotifier {
  static const _boxName = 'cart';
  late Box<CartItemModel> _box;

  @override
  Cart build() {
    _box = Hive.box<CartItemModel>(_boxName);
    return _buildCart();
  }

  Cart _buildCart() {
    final items = _box.values.map((m) => m.toEntity()).toList();
    return Cart(items: items);
  }

  // ===== Actions =====

  /// إضافة منتج للكارت
  /// لو المنتج من محل تاني → نرجع false (المستخدم يتسأل يفضي الكارت الأول)
  bool addItem(CartItem item) {
    if (!state.canAddFromShop(item.shopId)) return false;

    final existing = _box.get(item.productId);
    if (existing != null) {
      existing.quantity += item.quantity;
      existing.save();
    } else {
      _box.put(item.productId, CartItemModel.fromEntity(item));
    }
    state = _buildCart();
    return true;
  }

  void increment(String productId) {
    final item = _box.get(productId);
    if (item == null) return;
    item.quantity++;
    item.save();
    state = _buildCart();
  }

  void decrement(String productId) {
    final item = _box.get(productId);
    if (item == null) return;
    if (item.quantity <= 1) {
      removeItem(productId);
    } else {
      item.quantity--;
      item.save();
      state = _buildCart();
    }
  }

  void removeItem(String productId) {
    _box.delete(productId);
    state = _buildCart();
  }

  void clear() {
    _box.clear();
    state = const Cart();
  }

  void setDeliveryFee(double fee) {
    state = Cart(items: state.items, deliveryFee: fee);
  }
}

/// الكمية الكلية في الكارت — عشان تظهر على أيقونة الـ bottom nav
@riverpod
int cartItemCount(Ref ref) {
  return ref.watch(cartNotifierProvider).totalItems;
}
