import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../../domain/entities/user.dart';

class CheckinController extends AsyncNotifier<List<Attendance>> {
  final Set<String> _inFlightTrainees = {};

  @override
  Future<List<Attendance>> build() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final res = await ref
        .read(attendanceRepositoryProvider)
        .getAllAttendance(from: todayStart, to: todayEnd);
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  Future<Either<Failure, Attendance>> checkin(String traineeId, String method,
      {int? sessionId}) async {
    if (traineeId.trim().isEmpty) {
      return Left(const ValidationFailure('معرّف المتدرب غير صالح'));
    }
    if (sessionId != null && sessionId <= 0) {
      return Left(
          const ValidationFailure('رقم الحصة يجب أن يكون رقماً صحيحاً'));
    }
    if (!_inFlightTrainees.add(traineeId)) {
      return Left(
          const ValidationFailure('جاري تسجيل حضور المتدرب، انتظر قليلاً'));
    }
    try {
      final res = await ref
          .read(attendanceRepositoryProvider)
          .recordAttendance(traineeId, method, sessionId: sessionId);
      return res.fold(
        (l) {
          state = AsyncValue.error(l.message, StackTrace.current);
          return Left(l);
        },
        (a) {
          state = AsyncValue.data([...state.value ?? [], a]);
          return Right(a);
        },
      );
    } finally {
      _inFlightTrainees.remove(traineeId);
    }
  }
}

final checkinControllerProvider =
    AsyncNotifierProvider<CheckinController, List<Attendance>>(
        CheckinController.new);

final receptionTraineesProvider = FutureProvider<List<User>>((ref) async {
  try {
    final res = await ref
        .read(userRepositoryProvider)
        .getAllUsers()
        .timeout(const Duration(seconds: 15));
    return res.fold(
      (l) => throw Exception(l.message),
      (users) => users.where((u) => u.role == UserRole.trainee).toList(),
    );
  } on TimeoutException {
    throw Exception(
        'انتهت مهلة الاتصال بالخادم. تحقق من اتصال الشبكة وحاول مرة أخرى.');
  }
});

final receptionSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredReceptionTraineesProvider =
    Provider<AsyncValue<List<User>>>((ref) {
  final traineesAsync = ref.watch(receptionTraineesProvider);
  final query = ref.watch(receptionSearchQueryProvider).toLowerCase();
  return traineesAsync.whenData(
    (users) => users.where((u) {
      if (query.isEmpty) return true;
      return u.name.toLowerCase().contains(query) || u.phone.contains(query);
    }).toList(),
  );
});
