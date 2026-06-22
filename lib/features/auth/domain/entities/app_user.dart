import 'user_role.dart';

/// Domain entity for a user. Pure Dart — no Firestore/Firebase imports here.
/// The data-layer `AppUserModel` (in features/auth/data/models/) extends
/// this and adds fromFirestore/toMap serialization. See Phase 1.1 of the
/// blueprint for the Clean Architecture layering rationale.
class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final UserRole role;
  final String? profileImageUrl;
  final bool isActive;
  final bool isPhoneVerified;

  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    required this.role,
    this.profileImageUrl,
    this.isActive = true,
    this.isPhoneVerified = false,
  });

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    String? profileImageUrl,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      phoneNumber: phoneNumber,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      isPhoneVerified: isPhoneVerified,
    );
  }
}
