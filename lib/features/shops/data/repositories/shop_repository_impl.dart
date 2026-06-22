import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_remote_datasource.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopRemoteDataSource _dataSource;

  ShopRepositoryImpl({required ShopRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<Shop>> getShops() async {
    return await _dataSource.getShops();
  }

  @override
  Future<Shop?> getShopById(String shopId) async {
    return await _dataSource.getShopById(shopId);
  }

  @override
  Future<List<Shop>> getShopsByCategory(String category) async {
    return await _dataSource.getShopsByCategory(category);
  }

  @override
  Future<List<Shop>> searchShops(String query) async {
    return await _dataSource.searchShops(query);
  }
}