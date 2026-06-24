import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

part 'order_repository_impl.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
}

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  OrderRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  @override
  Future<String> placeOrder(PlaceOrderRequest request) async {
    final callable = _functions.httpsCallable('placeOrder');
    final result = await callable.call(request.toMap());
    return result.data['orderId'] as String;
  }

  @override
  Stream<AppOrder> watchOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map(AppOrderModel.fromFirestore);
  }

  @override
  Stream<List<AppOrder>> watchCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map(AppOrderModel.fromFirestore).toList());
  }

  @override
  Stream<List<AppOrder>> watchShopOrders(
    String shopId, {
    String? statusFilter,
  }) {
    Query query = _firestore
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(AppOrderModel.fromFirestore).toList());
  }

  @override
  Stream<List<AppOrder>> watchAvailableDeliveries() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'accepted')
        .where('driverId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(AppOrderModel.fromFirestore).toList());
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': newStatus,
          'timestamp': Timestamp.now(),
          'changedBy': 'client',
          'note': null,
        },
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      if (newStatus == 'delivered') 'deliveredAt': FieldValue.serverTimestamp(),
      if (newStatus == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
    });
  }
}
