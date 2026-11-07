import 'package:equatable/equatable.dart';

import 'attendance.dart';

/// Result of a single-use QR check-in: the stored attendance row plus the
/// trainee's display name (used by reception to confirm who just checked in).
class QrCheckIn extends Equatable {
  final Attendance attendance;
  final String traineeName;

  const QrCheckIn({required this.attendance, required this.traineeName});

  @override
  List<Object?> get props => [attendance, traineeName];
}
