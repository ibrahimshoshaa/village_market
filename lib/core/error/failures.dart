/// Sealed-style failure hierarchy for the domain layer. Repository methods
/// return Result&lt;T, Failure&gt; (see core/result/result.dart) rather than
/// throwing raw FirebaseException — this keeps the domain layer free of
/// Firebase-specific types, per the Clean Architecture rules in Phase 1.1.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'ليس لديك صلاحية للقيام بهذا الإجراء']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر المطلوب غير موجود']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم، حاول مرة أخرى']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع']);
}
