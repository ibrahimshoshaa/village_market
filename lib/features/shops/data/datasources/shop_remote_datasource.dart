import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

class ShopRemoteDataSource {
  final FirebaseFirestore _firestore;

  ShopRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<List<ShopModel>> getShops() async {
    final snapshot = await _firestore
        .collection('shops')
        .where('isActive', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<ShopModel?> getShopById(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (!doc.exists) return null;
    return ShopModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<ShopModel>> getShopsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('shops')
        .where('isActive', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs
        .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<ShopModel>> searchShops(String query) async {
    final snapshot = await _firestore
        .collection('shops')
        .where('isActive', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();

    return snapshot.docs
        .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}