import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'failures.dart';

abstract class ErrorMapper {
  static Failure fromFirestoreException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const PermissionFailure(),
      'not-found' => const NotFoundFailure(),
      'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
      _ => ServerFailure(e.message ?? 'حدث خطأ في الخادم'),
    };
  }

  static Failure fromAuthException(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-verification-code' => const AuthFailure('رمز التحقق غير صحيح'),
      'invalid-phone-number' => const AuthFailure('رقم الهاتف غير صحيح'),
      'too-many-requests' =>
        const AuthFailure('محاولات كثيرة جداً، حاول لاحقاً'),
      'network-request-failed' => const NetworkFailure(),
      _ => AuthFailure(e.message ?? 'حدث خطأ أثناء تسجيل الدخول'),
    };
  }

  static Failure fromFunctionsException(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => const AuthFailure('يجب تسجيل الدخول أولاً'),
      'failed-precondition' =>
        ValidationFailure(e.message ?? 'الكمية غير متوفرة'),
      'invalid-argument' => ValidationFailure(e.message ?? 'بيانات غير صحيحة'),
      'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
      _ => ServerFailure(e.message ?? 'حدث خطأ في الخادم'),
    };
  }
}
