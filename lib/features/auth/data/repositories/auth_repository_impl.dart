import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      final data = await _dataSource.getUserFromFirestore(user.uid);
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

    final user = credential.user!;
    final existingData = await _dataSource.getUserFromFirestore(user.uid);

    if (existingData == null) {
      // مستخدم جديد — احفظه في Firestore
      final newUser = AppUserModel.newUserMap(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
      );
      await _dataSource.saveUserToFirestore(newUser);
      return AppUserModel.fromMap(newUser..['uid'] = user.uid);
    }

    return AppUserModel.fromMap(existingData);
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final authUser = _dataSource.authStateChanges.first;
    final user = await authUser;
    if (user == null) return null;
    final data = await _dataSource.getUserFromFirestore(user.uid);
    if (data == null) return null;
    return AppUserModel.fromMap(data);
  }
}