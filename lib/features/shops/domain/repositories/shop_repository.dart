import '../entities/shop.dart';

abstract class ShopRepository {
  /// جيب كل المحلات النشطة والمعتمدة
  Future<List<Shop>> getShops();

  /// جيب محل بالـ ID
  Future<Shop?> getShopById(String shopId);

  /// جيب محلات بالكاتيجوري
  Future<List<Shop>> getShopsByCategory(String category);

  /// ابحث عن محل بالاسم
  Future<List<Shop>> searchShops(String query);
}
