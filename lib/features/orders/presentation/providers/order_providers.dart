import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

part 'order_providers.g.dart';

/// Stream لطلب معين — للـ tracking screen
@riverpod
Stream<AppOrder> watchOrder(Ref ref, String orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
}

/// طلبات الزبون الحالي
@riverpod
Stream<List<AppOrder>> customerOrders(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchCustomerOrders(user.uid);
}

/// طلبات المحل (للتاجر)
@riverpod
Stream<List<AppOrder>> shopOrders(Ref ref, String shopId) {
  return ref.watch(orderRepositoryProvider).watchShopOrders(shopId);
}

/// طلبات التوصيل المتاحة (للسائق)
@riverpod
Stream<List<AppOrder>> availableDeliveries(Ref ref) {
  return ref.watch(orderRepositoryProvider).watchAvailableDeliveries();
}

/// Checkout Controller — يتحكم في عملية إرسال الطلب
@riverpod
class CheckoutController extends _$CheckoutController {
  @override
  AsyncValue<String?> build() => const AsyncData(null); // null = no order yet

  Future<void> submitOrder(PlaceOrderRequest request) async {
    state = const AsyncLoading();
    try {
      final orderId =
          await ref.read(orderRepositoryProvider).placeOrder(request);
      // امسح الكارت بعد ما الطلب ينجح
      ref.read(cartNotifierProvider.notifier).clear();
      state = AsyncData(orderId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() => state = const AsyncData(null);
}

/// تحديث حالة الطلب (للتاجر والسائق)
@riverpod
class OrderStatusController extends _$OrderStatusController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateStatus(String orderId, String newStatus) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(orderId, newStatus);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
