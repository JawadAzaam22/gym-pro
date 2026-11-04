import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/errors/failures.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/membership.dart';

class MembershipController extends AsyncNotifier<List<Membership>> {
  @override
  Future<List<Membership>> build() async => [];

  Future<bool> create(
      String traineeId, DateTime start, DateTime end, String recordedBy) async {
    state = const AsyncValue.loading();
    final m = Membership(
        id: 0,
        traineeId: traineeId,
        startDate: start,
        endDate: end,
        status: MembershipStatus.active,
        recordedBy: recordedBy,
        createdAt: DateTime.now());
    final res = await ref.read(createMembershipProvider).call(m);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      return true;
    });
  }

  Future<Either<Failure, Membership>> renew(
      String traineeId, DateTime newEnd, String recordedBy) async {
    state = const AsyncValue.loading();
    final res = await ref.read(renewMembershipProvider).call(
          traineeId: traineeId,
          newEndDate: newEnd,
          recordedBy: recordedBy,
        );
    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (membership) => state = AsyncValue.data([membership]),
    );
    return res;
  }

  Future<bool> delete(int id) async {
    final res = await ref.read(deleteMembershipProvider).call(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        state = AsyncValue.data(
            (state.value ?? []).where((e) => e.id != id).toList());
        return true;
      },
    );
  }
}

final membershipControllerProvider =
    AsyncNotifierProvider<MembershipController, List<Membership>>(
        MembershipController.new);

/// جميع العضويات (للاستقبال/الأدمن) — تُعاد قراءتها عبر invalidate بعد الحذف.
final allMembershipsProvider = FutureProvider<List<Membership>>((ref) async {
  final res = await ref.read(membershipUseCasesProvider).getAllMemberships();
  return res.fold((l) => throw Exception(l.message), (r) => r);
});
