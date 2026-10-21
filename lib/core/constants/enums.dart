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
///
/// [bookingConfirmed] .. [membershipExpiringSoon] هي الأنواع التي يُنشئها
/// السيرفر (الـ triggers والـ cron) وفق عقد الجدول المُوثّق؛ القيم القديمة
/// محفوظة للتوافق مع أي صفوف موجودة.
enum NotificationType {
  bookingConfirmed,
  membershipCreated,
  trainerAssigned,
  traineeAssigned,
  fixedScheduleCreated,
  membershipExpiringSoon,
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
      case NotificationType.bookingConfirmed:
        return 'حجز';
      case NotificationType.membershipCreated:
        return 'عضوية';
      case NotificationType.trainerAssigned:
        return 'مدرب';
      case NotificationType.traineeAssigned:
        return 'متدرب';
      case NotificationType.fixedScheduleCreated:
        return 'جدول ثابت';
      case NotificationType.membershipExpiringSoon:
        return 'عضوية';
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
      case 'booking_confirmed':
        return NotificationType.bookingConfirmed;
      case 'membership_created':
        return NotificationType.membershipCreated;
      case 'trainer_assigned':
        return NotificationType.trainerAssigned;
      case 'trainee_assigned':
        return NotificationType.traineeAssigned;
      case 'fixed_schedule_created':
        return NotificationType.fixedScheduleCreated;
      case 'membership_expiring_soon':
        return NotificationType.membershipExpiringSoon;
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
      case NotificationType.bookingConfirmed:
        return 'booking_confirmed';
      case NotificationType.membershipCreated:
        return 'membership_created';
      case NotificationType.trainerAssigned:
        return 'trainer_assigned';
      case NotificationType.traineeAssigned:
        return 'trainee_assigned';
      case NotificationType.fixedScheduleCreated:
        return 'fixed_schedule_created';
      case NotificationType.membershipExpiringSoon:
        return 'membership_expiring_soon';
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
