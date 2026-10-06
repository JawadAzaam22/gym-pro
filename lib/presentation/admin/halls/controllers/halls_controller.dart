import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/hall.dart';
import '../../../../domain/entities/access_period.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/time_slot_generator.dart';

class HallsController extends AsyncNotifier<List<Hall>> {
  @override
  Future<List<Hall>> build() async {
    final res = await ref.read(hallRepositoryProvider).getHalls();
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  Future<bool> createHall(Hall hall) async {
    final res = await ref.read(hallRepositoryProvider).createHall(hall);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      // توليد فترات القاعة تلقائيًا من ساعات عملها فور إنشائها (كل الأيام
      // السبعة، بفترات ساعة واحدة ثابتة لا تتغير — هذا هو المصدر الوحيد
      // لإنشاء الفترات الآن؛ لم تعد شاشة "الفترات" تنشئ فترات يدويًا بمدد
      // متفاوتة، بل تعرض فقط ما تولّد هنا وتسمح بتعيين مدرب أو الحذف).
      _generateHallPeriods(r);
      return true;
    });
  }

  Future<bool> updateHall(Hall hall) async {
    final res = await ref.read(hallRepositoryProvider).updateHall(hall);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      final list = state.value ?? [];
      state = AsyncValue.data([for (final h in list) h.id == r.id ? r : h]);
      // إن تغيّرت ساعات العمل، نضيف أي فترات جديدة مفقودة ضمن المدى الجديد
      // (بدون حذف الفترات الحالية تلقائيًا، حفاظًا على أي مدرّبين أو حجوزات
      // مرتبطة بها بالفعل). يمكن حذف الفترات غير المرغوبة يدويًا من شاشة
      // الفترات.
      _generateHallPeriods(r);
      return true;
    });
  }

  /// يولّد فترات ساعة واحدة ثابتة لكل الأيام السبعة ضمن ساعات عمل القاعة،
  /// ويتخطى أي فترة موجودة مسبقًا بنفس اليوم والوقت (آمن عند الاستدعاء
  /// المتكرر بعد كل تعديل لساعات القاعة).
  Future<void> _generateHallPeriods(Hall hall) async {
    final repo = ref.read(hallRepositoryProvider);
    final slots = generateTimeSlots(
      openTime: hall.openTime,
      closeTime: hall.closeTime,
      slotMinutes: hall.defaultSlotMinutes,
    );
    if (slots.isEmpty) return;
    final existingRes = await repo.getAccessPeriods(hall.id);
    final existing = existingRes.getOrElse(() => []);
    for (int day = 0; day < 7; day++) {
      for (final slot in slots) {
        final exists = existing.any((p) =>
            p.dayOfWeek == day &&
            p.startTime == slot.start &&
            p.endTime == slot.end);
        if (exists) continue;
        await repo.createAccessPeriod(AccessPeriod(
          id: 0,
          hallId: hall.id,
          dayOfWeek: day,
          startTime: slot.start,
          endTime: slot.end,
          accessType: AccessType.mixed,
          isActive: true,
        ));
      }
    }
    ref.invalidate(accessPeriodsProvider(hall.id));
  }

  Future<bool> toggleStatus(Hall hall) async {
    // ملاحظة: كان هذا يبني Hall جديدًا بدون نقل openTime/closeTime/
    // defaultSlotMinutes، فيعيدها لقيمها الافتراضية (08:00-22:00) بصمت عند
    // كل تفعيل/تعطيل — خلل حقيقي أصلحناه بنقل كل الحقول كما هي.
    final updated = Hall(
        id: hall.id,
        name: hall.name,
        capacity: hall.capacity,
        isActive: !hall.isActive,
        openTime: hall.openTime,
        closeTime: hall.closeTime,
        defaultSlotMinutes: hall.defaultSlotMinutes);
    final res = await ref.read(hallRepositoryProvider).updateHall(updated);
    return res.fold((l) => false, (_) {
      state = AsyncValue.data(
          [for (final h in state.value ?? []) h.id == hall.id ? updated : h]);
      return true;
    });
  }
}

final hallsControllerProvider =
    AsyncNotifierProvider<HallsController, List<Hall>>(HallsController.new);

final accessPeriodsProvider =
    FutureProvider.family<List<AccessPeriod>, int>((ref, hallId) async {
  final res = await ref.read(hallRepositoryProvider).getAccessPeriods(hallId);
  return res.fold((l) => throw Exception(l.message), (r) => r);
});
