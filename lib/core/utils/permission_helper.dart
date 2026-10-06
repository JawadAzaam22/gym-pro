import '../constants/enums.dart';

/// Helper مركزي للتحقق من الصلاحيات حسب مصفوفة 04_PERMISSIONS.md
abstract class PermissionHelper {
  static bool canCreateUser(UserRole role) =>
      role == UserRole.admin || role == UserRole.reception;

  static bool canEditUser(UserRole role) => role == UserRole.admin;

  static bool canDeactivateUser(UserRole role) => role == UserRole.admin;

  static bool canViewAllUsers(UserRole role) =>
      role == UserRole.admin || role == UserRole.reception;

  // Halls
  static bool canManageHall(UserRole role) => role == UserRole.admin;
  static bool canViewHalls(UserRole role) => true;

  // Membership
  static bool canCreateMembership(UserRole role) =>
      role == UserRole.reception;
  static bool canRenewMembership(UserRole role) => role == UserRole.reception;

  // Sessions
  static bool canManageSession(UserRole role) => role == UserRole.admin;
  static bool canBookSession(UserRole role) =>
      role == UserRole.reception || role == UserRole.trainee;
  static bool canCancelBooking(UserRole role) =>
      role == UserRole.reception || role == UserRole.trainee;

  // Trainer-Trainee
  static bool canAssignTrainer(UserRole role) => role == UserRole.reception;
  static bool canSchedulePrivate(UserRole role) => role == UserRole.reception;

  // Attendance
  static bool canRecordAttendance(UserRole role) =>
      role == UserRole.reception;

  // Programs & Diets
  static bool canCreateProgram(UserRole role) => role == UserRole.trainer;
  static bool canCreateDiet(UserRole role) => role == UserRole.trainer;

  // Finance
  static bool canRecordPayment(UserRole role) => role == UserRole.reception;
  static bool canViewPayments(UserRole role) =>
      role == UserRole.admin || role == UserRole.reception;
  static bool canGenerateReport(UserRole role) => role == UserRole.admin;
}
