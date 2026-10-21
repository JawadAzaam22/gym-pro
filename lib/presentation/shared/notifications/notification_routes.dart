import '../../../core/constants/enums.dart';
import '../../../domain/entities/notification_item.dart';

/// خريطة `data.screen` (من حمولة jsonb في جدول `notifications`) إلى مسار
/// go_router حقيقي **لدور المستلم**. أي قيمة مفقودة أو مجهولة تُرجع null
/// ولا تُغيّر الشاشة.
///
/// العقد (ينشئه السيرفر فقط):
/// | screen                 | الدور   | المسار                       |
/// |------------------------|---------|------------------------------|
/// | my_bookings            | trainee | /trainee/bookings            |
/// | membership             | trainee | /trainee/membership          |
/// | my_trainer             | trainee | /trainee/trainer             |
/// | trainees               | trainer | /trainer/trainees            |
/// | fixed_schedule         | trainer | /trainer/schedule            |
/// | fixed_schedule         | trainee | /trainee/private-sessions    |
String? notificationRouteFor(AppNotification n, UserRole? role) {
  final screen = n.dataString('screen');
  if (screen == null) return null;
  switch (screen) {
    case 'my_bookings':
      return role == UserRole.trainee ? '/trainee/bookings' : null;
    case 'membership':
      return role == UserRole.trainee ? '/trainee/membership' : null;
    case 'my_trainer':
      return role == UserRole.trainee ? '/trainee/trainer' : null;
    case 'trainees':
      return role == UserRole.trainer ? '/trainer/trainees' : null;
    case 'fixed_schedule':
      if (role == UserRole.trainer) return '/trainer/schedule';
      if (role == UserRole.trainee) return '/trainee/private-sessions';
      return null;
    default:
      return null;
  }
}
