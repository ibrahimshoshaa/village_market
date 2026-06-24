import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/data/models/order_model.dart';

part 'driver_providers.g.dart';

/// الطلبات المتاحة للسائق (accepted + دريفر id فاضي)
@riverpod
Stream<List<AppOrder>> availableDeliveries(Ref ref) {
  return ref.watch(orderRepositoryProvider).watchAvailableDeliveries();
}

/// الطلب النشط بتاع السائق ده بالذات
@riverpod
Stream<List<AppOrder>> myActiveDeliveries(Ref ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('orders')
      .where('driverId', isEqualTo: user.uid)
      .where('status', whereIn: ['accepted', 'in_transit'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrderModel.fromFirestore).toList());
}

/// Controller لقبول/تحديث الطلب
@riverpod
class DriverOrderController extends _$DriverOrderController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// السائق يقبل الطلب ويضيف اسمه عليه
  Future<void> acceptDelivery(String orderId) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('orders').doc(orderId).update({
        'driverId': user.uid,
        'driverName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// السائق يحدث الحالة (in_transit أو delivered)
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

  /// السائق يبدّل availability بتاعته
  Future<void> toggleAvailability(bool isAvailable) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final firestore = ref.read(firestoreProvider);
    await firestore.collection('users').doc(user.uid).update({
      'driverProfile.isAvailable': isAvailable,
    });
  }
}
