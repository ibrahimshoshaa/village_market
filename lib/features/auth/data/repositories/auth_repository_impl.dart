import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final data = await _dataSource.getUserFromFirestore(firebaseUser.uid);
      if (data == null) return null;
      return AppUserModel.fromMap(data);
    });
  }

  @override
  Future<String> sendOtp(String phoneNumber) async {
    return await _dataSource.sendOtp(phoneNumber);
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    final credential = await _dataSource.verifyOtp(
      verificationId: verificationId,
      otpCode: otpCode,
    );

    final firebaseUser = credential.user!;

    // لو المستخدم جديد، نحفظه في Firestore
    final existing = await _dataSource.getUserFromFirestore(firebaseUser.uid);
    if (existing == null) {
      final newUserMap = AppUserModel.newUserMap(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
      );
      await _dataSource.saveUserToFirestore(newUserMap);
      // fromMap مش هيعرف يقرأ FieldValue — نرجع object مباشرة
      return AppUserModel(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        displayName: '',
        role: UserRole.unknown,
        isActive: true,
        isPhoneVerified: true,
      );
    }

    return AppUserModel.fromMap(existing);
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;
    final data = await _dataSource.getUserFromFirestore(firebaseUser.uid);
    if (data == null) return null;
    return AppUserModel.fromMap(data);
  }

  @override
  Future<void> updateUserRole(String role) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('مفيش يوزر logged in');
    await _dataSource.updateUserRole(firebaseUser.uid, role);
  }
}
