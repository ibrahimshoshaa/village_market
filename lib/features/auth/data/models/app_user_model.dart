import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.phoneNumber,
    required super.displayName,
    required super.role,
    super.profileImageUrl,
    super.isActive,
    super.isPhoneVerified,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.fromString(data['role']),
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
    );
  }

  factory AppUserModel.fromMap(Map<String, dynamic> data) {
    return AppUserModel(
      uid: data['uid'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.fromString(data['role']),
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'isPhoneVerified': isPhoneVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Used when creating a new user for the first time
  static Map<String, dynamic> newUserMap({
    required String uid,
    required String phoneNumber,
  }) {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': '',
      'role': UserRole.unknown.name,
      'isActive': true,
      'isPhoneVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}