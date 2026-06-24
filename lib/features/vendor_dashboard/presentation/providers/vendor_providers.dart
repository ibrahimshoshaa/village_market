import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';

part 'vendor_providers.g.dart';

/// shopId بتاع التاجر الحالي
@riverpod
Future<String?> myShopId(Ref ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return user.uid; // بنستخدم uid كـ shopId للتبسيط
}

/// الطلبات الجديدة (pending) على محل التاجر
@riverpod
Stream<List<AppOrder>> pendingOrders(Ref ref, String shopId) {
  return ref
      .watch(orderRepositoryProvider)
      .watchShopOrders(shopId, statusFilter: 'pending');
}

/// كل طلبات المحل (مش pending بس)
@riverpod
Stream<List<AppOrder>> allShopOrders(Ref ref, String shopId) {
  return ref.watch(orderRepositoryProvider).watchShopOrders(shopId);
}

/// Controller لقبول/رفض الطلبات
@riverpod
class VendorOrderController extends _$VendorOrderController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> acceptOrder(String orderId) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(orderId, 'accepted');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancellation': {
          'reason': reason,
          'cancelledBy': 'vendor',
          'cancelledAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markPreparing(String orderId) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(orderId, 'preparing');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// تفعيل/تعطيل المحل مؤقتاً
  Future<void> toggleShop(String shopId, bool isOpen) async {
    final firestore = ref.read(firestoreProvider);
    await firestore.collection('shops').doc(shopId).update({
      'isManuallyOverrideClosed': !isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
