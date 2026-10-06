import '../constants/enums.dart';

/// فصل Auth حسب الدور:
/// 1. Admin Web -> فقط admin
/// 2. Reception Web -> فقط reception
/// 3. Mobile (Trainer+Trainee) -> trainer و trainee

enum AppEntry { admin, reception, mobile }

class RoleGuard {
  static List<UserRole> allowedRoles(AppEntry entry) {
    switch (entry) {
      case AppEntry.admin:
        return [UserRole.admin];
      case AppEntry.reception:
        return [UserRole.reception];
      case AppEntry.mobile:
        return [UserRole.trainer, UserRole.trainee];
    }
  }

  static bool isAllowed(UserRole role, AppEntry entry) {
    return allowedRoles(entry).contains(role);
  }

  static String allowedRolesLabel(AppEntry entry) {
    switch (entry) {
      case AppEntry.admin:
        return 'Admin فقط';
      case AppEntry.reception:
        return 'Reception فقط';
      case AppEntry.mobile:
        return 'Trainer / Trainee';
    }
  }

  static String errorMessage(UserRole actual, AppEntry entry) {
    return 'هذا الحساب (${actual.name}) غير مصرح له بالدخول هنا. هذه المنصة مخصصة لـ ${allowedRolesLabel(entry)}';
  }
}
