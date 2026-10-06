/// جميع الأنواع المعدادية للنظام
library;

enum UserRole { admin, reception, trainer, trainee }

extension UserRoleX on UserRole {
  String get nameAr {
    switch (this) {
      case UserRole.admin:
        return 'أدمن';
      case UserRole.reception:
        return 'استقبال';
      case UserRole.trainer:
        return 'مدرب';
      case UserRole.trainee:
        return 'متدرب';
    }
  }

  static UserRole fromString(String value) {
    final v = value.trim().toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name == v,
      orElse: () => UserRole.trainee,
    );
  }
}

enum Gender { male, female }

extension GenderX on Gender {
  String get nameAr => this == Gender.male ? 'ذكر' : 'أنثى';
  static Gender fromString(String v) =>
      v == 'female' ? Gender.female : Gender.male;
}

enum MembershipStatus { active, expired, suspended }

enum SessionStatus { scheduled, cancelled, completed }

enum BookingStatus { confirmed, cancelled }

enum TrainerTraineeStatus { active, inactive }

enum PrivateSessionStatus { scheduled, cancelled, completed }

enum AttendanceMethod { qr, manual }

enum AccessType { mixed, women, maintenance, courseReserved }

extension AccessTypeX on AccessType {
  String get nameAr {
    switch (this) {
      case AccessType.mixed:
        return 'مختلط';
      case AccessType.women:
        return 'سيدات';
      case AccessType.maintenance:
        return 'صيانة';
      case AccessType.courseReserved:
        return 'محجوز لدورة';
    }
  }

  String toDbString() {
    switch (this) {
      case AccessType.mixed:
        return 'mixed';
      case AccessType.women:
        return 'women';
      case AccessType.maintenance:
        return 'maintenance';
      case AccessType.courseReserved:
        return 'course_reserved';
    }
  }

  static AccessType fromString(String v) {
    switch (v) {
      case 'women':
        return AccessType.women;
      case 'maintenance':
        return AccessType.maintenance;
      case 'course_reserved':
        return AccessType.courseReserved;
      default:
        return AccessType.mixed;
    }
  }
}

/// أنواع الإشعارات الداخلية (جدول notifications في Supabase)
enum NotificationType {
  membershipExpiry,
  sessionReminder,
  booking,
  payment,
  attendance,
  system,
}

extension NotificationTypeX on NotificationType {
  String get nameAr {
    switch (this) {
      case NotificationType.membershipExpiry:
        return 'عضوية';
      case NotificationType.sessionReminder:
        return 'موعد';
      case NotificationType.booking:
        return 'حجز';
      case NotificationType.payment:
        return 'مدفوعات';
      case NotificationType.attendance:
        return 'حضور';
      case NotificationType.system:
        return 'عام';
    }
  }

  static NotificationType fromString(String? v) {
    switch (v) {
      case 'membership_expiry':
        return NotificationType.membershipExpiry;
      case 'session_reminder':
        return NotificationType.sessionReminder;
      case 'booking':
        return NotificationType.booking;
      case 'payment':
        return NotificationType.payment;
      case 'attendance':
        return NotificationType.attendance;
      default:
        return NotificationType.system;
    }
  }

  String toDbString() {
    switch (this) {
      case NotificationType.membershipExpiry:
        return 'membership_expiry';
      case NotificationType.sessionReminder:
        return 'session_reminder';
      case NotificationType.booking:
        return 'booking';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.system:
        return 'system';
    }
  }
}

enum PaymentType { income, expense }

enum PaymentCategory {
  membership,
  salary,
  purchase,
  maintenance,
  privateSession,
  other
}

extension PaymentCategoryX on PaymentCategory {
  static PaymentCategory fromString(String v) {
    switch (v) {
      case 'salary':
        return PaymentCategory.salary;
      case 'purchase':
        return PaymentCategory.purchase;
      case 'maintenance':
        return PaymentCategory.maintenance;
      case 'private_session':
        return PaymentCategory.privateSession;
      case 'other':
        return PaymentCategory.other;
      default:
        return PaymentCategory.membership;
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentCategory.membership:
        return 'membership';
      case PaymentCategory.salary:
        return 'salary';
      case PaymentCategory.purchase:
        return 'purchase';
      case PaymentCategory.maintenance:
        return 'maintenance';
      case PaymentCategory.privateSession:
        return 'private_session';
      case PaymentCategory.other:
        return 'other';
    }
  }
}
