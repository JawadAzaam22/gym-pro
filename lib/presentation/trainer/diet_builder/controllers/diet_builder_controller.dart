import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/diet_day_model.dart';
import '../../../../data/models/diet_meal_model.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/diet.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class DietBuilderController extends AsyncNotifier<List<Diet>> {
  @override
  Future<List<Diet>> build() async {
    final trainerId = ref.read(authControllerProvider).value?.id ?? '';
    final res =
        await ref.read(dietUseCasesProvider).getDietsByTrainer(trainerId);
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  Future<bool> create(String name, String traineeId, String? desc) async {
    final trainerId = ref.read(authControllerProvider).value?.id ?? '';
    final d = Diet(
        id: 0,
        trainerId: trainerId,
        traineeId: traineeId,
        name: name,
        description: desc,
        startDate: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now());
    final res = await ref.read(createDietPlanUcProvider).call(d);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      return true;
    });
  }

  Future<bool> editDiet(Diet diet) async {
    final res = await ref.read(dietUseCasesProvider).updateDiet(diet);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      final list = state.value ?? [];
      state = AsyncValue.data([for (final d in list) d.id == r.id ? r : d]);
      return true;
    });
  }

  Future<bool> deactivate(int id) async {
    final res = await ref.read(dietUseCasesProvider).deactivateDiet(id);
    return res.fold((l) => false, (_) {
      final list = state.value ?? [];
      state = AsyncValue.data(
          [for (final d in list) d.id == id ? d.copyWith(isActive: false) : d]);
      return true;
    });
  }

  Future<bool> delete(int id) async {
    final res = await ref.read(dietUseCasesProvider).deleteDiet(id);
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

final dietBuilderProvider =
    AsyncNotifierProvider<DietBuilderController, List<Diet>>(
        DietBuilderController.new);

/// أيام خطة غذائية معيّنة — invalidation بعد الإضافة يعيد الجلب تلقائيًا.
final dietDaysProvider =
    FutureProvider.family<List<DietDayModel>, int>((ref, dietId) async {
  final result = await ref.read(dietContentUseCasesProvider).getDays(dietId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (days) => days.map(DietDayModel.fromEntity).toList(),
  );
});

/// وجبات يوم معيّن في خطة غذائية.
final dietMealsProvider =
    FutureProvider.family<List<DietMealModel>, int>((ref, dayId) async {
  final result = await ref.read(dietContentUseCasesProvider).getMeals(dayId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (meals) => meals.map(DietMealModel.fromEntity).toList(),
  );
});
