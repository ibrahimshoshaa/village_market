import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/shop_remote_datasource.dart';
import '../../data/repositories/shop_repository_impl.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';

// --- DataSource ---
final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSource(firestore: FirebaseFirestore.instance);
});

// --- Repository ---
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepositoryImpl(
    dataSource: ref.read(shopRemoteDataSourceProvider),
  );
});

// --- Shops List ---
final shopsProvider = FutureProvider<List<Shop>>((ref) async {
  return ref.read(shopRepositoryProvider).getShops();
});

// --- Shop By ID ---
final shopByIdProvider =
    FutureProvider.family<Shop?, String>((ref, shopId) async {
  return ref.read(shopRepositoryProvider).getShopById(shopId);
});

// --- Search ---
final shopSearchQueryProvider = StateProvider<String>((ref) => '');

final shopSearchResultsProvider = FutureProvider<List<Shop>>((ref) async {
  final query = ref.watch(shopSearchQueryProvider);
  if (query.isEmpty) return ref.read(shopRepositoryProvider).getShops();
  return ref.read(shopRepositoryProvider).searchShops(query);
});

// --- Category Filter ---
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredShopsProvider = FutureProvider<List<Shop>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  if (category == null) return ref.read(shopRepositoryProvider).getShops();
  return ref.read(shopRepositoryProvider).getShopsByCategory(category);
});
