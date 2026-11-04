import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/private_training_session.dart';
import '../../../../domain/entities/trainer_trainee.dart';

class BookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async => [];

  Future<bool> book(String traineeId, int sessionId) async {
    final res =
        await ref.read(bookSessionUcProvider).call(traineeId, sessionId);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      // تحديث الأعداد والقوائم المعروضة بعد الحجز الناجح.
      ref.invalidate(sessionBookingCountsProvider);
      ref.invalidate(traineeBookingsProvider);
      return true;
    });
  }

  /// إلغاء حجز (يُسجَّل كـ cancelled) — يبقى السجل ويمكن إعادة الحجز لاحقاً.
  Future<bool> cancel(int bookingId) async {
    final res = await ref.read(cancelBookingUcProvider).call(bookingId);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        state = AsyncValue.data(
            (state.value ?? []).where((e) => e.id != bookingId).toList());
        ref.invalidate(sessionBookingCountsProvider);
        ref.invalidate(traineeBookingsProvider);
        return true;
      },
    );
  }

  Future<bool> deleteBooking(int id) async {
    final res = await ref.read(bookingUseCasesProvider).deleteBooking(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        state = AsyncValue.data(
            (state.value ?? []).where((e) => e.id != id).toList());
        ref.invalidate(sessionBookingCountsProvider);
        return true;
      },
    );
  }

  Future<bool> deletePrivateSession(int id) async {
    final res =
        await ref.read(bookingUseCasesProvider).deletePrivateSession(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(privateSessionsProvider);
        return true;
      },
    );
  }

  Future<bool> deleteTrainerTraineeRelation(int id) async {
    final res = await ref
        .read(bookingUseCasesProvider)
        .deleteTrainerTraineeRelation(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        ref.invalidate(trainerTraineesProvider);
        return true;
      },
    );
  }
}

final bookingsControllerProvider =
    AsyncNotifierProvider<BookingsController, List<Booking>>(
        BookingsController.new);

/// أعداد الحجوزات المؤكدة لكل حصة — تُجلب بطلب واحد (بديل N+1).
final sessionBookingCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final res = await ref.read(bookingUseCasesProvider).getBookingCounts();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// حجوزات متدرب بعينه — تُعاد قراءتها عبر invalidate بعد الحجز/الإلغاء عند الاستقبال.
final traineeBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, traineeId) async {
  final res =
      await ref.read(bookingUseCasesProvider).getBookingsByTrainee(traineeId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// قائمة الجلسات الخاصة (للاستقبال) — تُعاد قراءتها عبر invalidate بعد الجدولة.
final privateSessionsProvider =
    FutureProvider<List<PrivateTrainingSession>>((ref) async {
  final res = await ref.read(getPrivateTrainingSessionsProvider).call();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});

/// علاقات مدرب-متدرب للـ Reception
final trainerTraineesProvider =
    FutureProvider<List<TrainerTrainee>>((ref) async {
  final res = await ref.read(getTrainerTraineesProvider).call();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});
