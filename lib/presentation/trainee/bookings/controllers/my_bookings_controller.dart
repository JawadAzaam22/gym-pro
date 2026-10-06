import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/session.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class MyBookingsData {
  final List<Booking> bookings;
  final List<Session> sessions;
  const MyBookingsData({required this.bookings, required this.sessions});
}

final myBookingsProvider = FutureProvider<MyBookingsData>((ref) async {
  final currentUser = ref.read(authControllerProvider).value;
  final traineeId = currentUser?.id ?? '';
  final bookingsRes = await ref.read(bookingRepositoryProvider).getBookingsByTrainee(traineeId);
  final sessionsRes = await ref.read(sessionRepositoryProvider).getSessions();
  final failure = bookingsRes.fold((l) => l.message, (_) => null) ?? sessionsRes.fold((l) => l.message, (_) => null);
  if (failure != null) throw Exception(failure);
  final bookings = bookingsRes.getOrElse(() => <Booking>[]);
  final sessions = sessionsRes.getOrElse(() => <Session>[]);
  return MyBookingsData(bookings: bookings, sessions: sessions);
});

