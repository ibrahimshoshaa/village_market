import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

part 'auth_providers.g.dart';

// ===== Auth State (stream من Firebase) =====

/// Stream حقيقي من Firebase Auth
/// بيتحدث أوتوماتيك لما المستخدم يسجل دخول أو خروج
@riverpod
Stream<AppUser?> authStateStream(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);

  return auth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;

    // اجيب بيانات المستخدم من Firestore
    final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return AppUser(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.fromString(data['role']),
      profileImageUrl: data['profileImageUrl'],
      isActive: data['isActive'] ?? true,
      isPhoneVerified: true,
    );
  });
}

/// Provider مبسط للاستخدام في الـ router و guards
final authStateProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  return const AsyncLoading();
});

/// دور المستخدم الحالي
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.role ?? UserRole.unknown;
});

// ===== OTP Controller =====

@riverpod
class OtpController extends _$OtpController {
  String? _verificationId;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// إرسال الـ OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function() onCodeSent,
    required void Function(String errorCode) onError,
  }) async {
    state = const AsyncLoading();

    try {
      final auth = ref.read(firebaseAuthProvider);

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        // Android auto-retrieval
        verificationCompleted: (credential) async {
          await _signInWithCredential(credential);
        },

        verificationFailed: (e) {
          state = const AsyncData(null);
          onError(e.code);
        },

        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          state = const AsyncData(null);
          onCodeSent();
        },

        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e, st) {
      state = AsyncError(e, st);
      onError('unknown');
    }
  }

  /// التحقق من الـ OTP
  Future<void> verifyOtp({
    required String smsCode,
    required void Function(String errorCode) onError,
  }) async {
    if (_verificationId == null) {
      onError('no-verification-id');
      return;
    }

    state = const AsyncLoading();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = const AsyncData(null);
      onError(e.code);
    } catch (e, st) {
      state = AsyncError(e, st);
      onError('unknown');
    }
  }

  /// تسجيل الدخول وإنشاء/تحديث مستند المستخدم
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);

    final result = await auth.signInWithCredential(credential);
    final firebaseUser = result.user!;

    // تحقق إذا كان المستخدم موجود
    final userDoc = await firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) {
      // مستخدم جديد — أنشئ مستنده
      await firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'phoneNumber': firebaseUser.phoneNumber,
        'displayName': 'مستخدم جديد',
        'role': 'unknown',
        'profileImageUrl': null,
        'fcmTokens': [],
        'isActive': true,
        'isPhoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // حدّث الـ auth state
    final data = (await firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get())
        .data()!;

    final appUser = AppUser(
      uid: firebaseUser.uid,
      phoneNumber: firebaseUser.phoneNumber ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.fromString(data['role']),
      isActive: data['isActive'] ?? true,
      isPhoneVerified: true,
    );

    ref.read(authStateProvider.notifier).state = AsyncData(appUser);
    state = const AsyncData(null);
  }

  /// تعيين دور المستخدم بعد التسجيل
  Future<void> setRole(UserRole role) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(user.uid).update({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // حدّث الـ state بالدور الجديد
      ref.read(authStateProvider.notifier).state = AsyncData(
        user.copyWith(role: role),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    ref.read(authStateProvider.notifier).state = const AsyncData(null);
  }
}
