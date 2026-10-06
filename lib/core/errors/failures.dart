import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// فشل تسجيل الحضور بسبب عضوية منتهية/غير نشطة (SRS 5.2).
/// تحمل تاريخ الانتهاء لعرضه في الحوار التحذيري للاستقبال.
class MembershipExpiredFailure extends Failure {
  final DateTime? endDate;
  const MembershipExpiredFailure(super.message, [this.endDate]);

  @override
  List<Object?> get props => [message, endDate];
}

/// فشل جدولة جلسة خاصة بسبب تعارض مع فترة المدرب أو جلسة أخرى.
class ScheduleConflictFailure extends Failure {
  const ScheduleConflictFailure(super.message);
}
