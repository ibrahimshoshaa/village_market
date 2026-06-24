import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';

part 'admin_providers.g.dart';

// ===== Models =====

class PendingShop {
  final String shopId;
  final String shopName;
  final String ownerName;
  final String ownerId;
  final String category;
  final String logoUrl;
  final DateTime createdAt;

  const PendingShop({
    required this.shopId,
    required this.shopName,
    required this.ownerName,
    required this.ownerId,
    required this.category,
    required this.logoUrl,
    required this.createdAt,
  });

  static PendingShop fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PendingShop(
      shopId: doc.id,
      shopName: d['shopName'] ?? '',
      ownerName: d['ownerName'] ?? '',
      ownerId: d['ownerId'] ?? '',
      category: d['category'] ?? '',
      logoUrl: d['logoUrl'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AdminUser {
  final String uid;
  final String displayName;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const AdminUser({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  static AdminUser fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminUser(
      uid: doc.id,
      displayName: d['displayName'] ?? '',
      phoneNumber: d['phoneNumber'] ?? '',
      role: d['role'] ?? 'villager',
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AppStats {
  final int totalUsers;
  final int totalShops;
  final int totalOrders;
  final int pendingShops;

  const AppStats({
    required this.totalUsers,
    required this.totalShops,
    required this.totalOrders,
    required this.pendingShops,
  });
}

// ===== Providers =====

/// المحلات اللي لسه مش متوافق عليها
@riverpod
Stream<List<PendingShop>> pendingShops(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('shops')
      .where('isApproved', isEqualTo: false)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(PendingShop.fromDoc).toList());
}

/// كل المستخدمين
@riverpod
Stream<List<AdminUser>> allUsers(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(AdminUser.fromDoc).toList());
}

/// إحصائيات سريعة للـ dashboard
@riverpod
Future<AppStats> appStats(Ref ref) async {
  final firestore = ref.watch(firestoreProvider);

  final results = await Future.wait([
    firestore.collection('users').count().get(),
    firestore.collection('shops').where('isApproved', isEqualTo: true).count().get(),
    firestore.collection('orders').count().get(),
    firestore.collection('shops').where('isApproved', isEqualTo: false).count().get(),
  ]);

  return AppStats(
    totalUsers: results[0].count ?? 0,
    totalShops: results[1].count ?? 0,
    totalOrders: results[2].count ?? 0,
    pendingShops: results[3].count ?? 0,
  );
}

// ===== Admin Controller =====

@riverpod
class AdminController extends _$AdminController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// الموافقة على محل
  Future<void> approveShop(String shopId) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('shops').doc(shopId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// رفض محل (حذف ناعم)
  Future<void> rejectShop(String shopId) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('shops').doc(shopId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// تفعيل/تعطيل مستخدم
  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(uid).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// تغيير دور مستخدم
  Future<void> changeUserRole(String uid, String newRole) async {
    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
