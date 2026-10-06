class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, [this.statusCode]);
  @override
  String toString() => 'ServerException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

/// تُرمى عند محاولة تسجيل حضور لعضوية منتهية/غير نشطة (SRS 5.2).
/// تحمل تاريخ الانتهاء لعرضه في الحوار التحذيري للاستقبال.
class MembershipExpiredException implements Exception {
  final String message;
  final DateTime? endDate;
  MembershipExpiredException(this.message, [this.endDate]);
  @override
  String toString() => 'MembershipExpiredException: $message';
}

/// تُرمى عند تعارض جلسة خاصة مع فترة المدرب أو جلسة أخرى مجدولة.
class ScheduleConflictException implements Exception {
  final String message;
  ScheduleConflictException(this.message);
  @override
  String toString() => 'ScheduleConflictException: $message';
}
