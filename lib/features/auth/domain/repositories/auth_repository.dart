import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Stream of the current user — null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Send OTP to [phoneNumber]. Returns verificationId.
  Future<String> sendOtp(String phoneNumber);

  /// Verify OTP and sign in. Returns the authenticated user.
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Get current user from Firestore (null if not found).
  Future<AppUser?> getCurrentUser();

  /// Update the role of the current user in Firestore.
  Future<void> updateUserRole(String role);
}