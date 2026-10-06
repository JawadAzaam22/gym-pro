import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/program_day_model.dart';
import '../../../../data/models/program_exercise_model.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/training_program.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

class ProgramBuilderController extends AsyncNotifier<List<TrainingProgram>> {
  @override
  Future<List<TrainingProgram>> build() async {
    final trainerId = ref.read(authControllerProvider).value?.id ?? '';
    final res = await ref.read(programRepositoryProvider).getProgramsByTrainer(trainerId);
    return res.fold((l) => throw Exception(l.message), (r) => r);
  }

  Future<bool> create(String name, String traineeId, String? desc) async {
    final trainerId = ref.read(authControllerProvider).value?.id ?? '';
    final p = TrainingProgram(id: 0, trainerId: trainerId, traineeId: traineeId, name: name, description: desc, startDate: DateTime.now(), isActive: true, createdAt: DateTime.now());
    final res = await ref.read(programRepositoryProvider).createProgram(p);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      state = AsyncValue.data([...state.value ?? [], r]);
      return true;
    });
  }

  Future<bool> editProgram(TrainingProgram program) async {
    final res = await ref.read(programRepositoryProvider).updateProgram(program);
    return res.fold((l) {
      state = AsyncValue.error(l.message, StackTrace.current);
      return false;
    }, (r) {
      final list = state.value ?? [];
      state = AsyncValue.data([for (final p in list) p.id == r.id ? r : p]);
      return true;
    });
  }

  Future<bool> deactivate(int id) async {
    final res = await ref.read(programRepositoryProvider).deactivateProgram(id);
    return res.fold((l) => false, (_) {
      final list = state.value ?? [];
      state = AsyncValue.data([for (final p in list) p.id == id ? p.copyWith(isActive: false) : p]);
      return true;
    });
  }

  Future<bool> delete(int id) async {
    final res = await ref.read(programRepositoryProvider).deleteProgram(id);
    return res.fold(
      (l) {
        state = AsyncValue.error(l.message, StackTrace.current);
        return false;
      },
      (_) {
        state = AsyncValue.data((state.value ?? []).where((e) => e.id != id).toList());
        return true;
      },
    );
  }
}

final programBuilderProvider = AsyncNotifierProvider<ProgramBuilderController, List<TrainingProgram>>(ProgramBuilderController.new);

/// أيام برنامج معيّن — invalidation بعد الإضافة/الحذف يعيد الجلب تلقائيًا.
final programDaysProvider = FutureProvider.family<List<ProgramDayModel>, int>((ref, programId) async {
  return ref.read(programDatasourceProvider).getDays(programId);
});

/// تمارين يوم معيّن في برنامج.
final programExercisesProvider = FutureProvider.family<List<ProgramExerciseModel>, int>((ref, dayId) async {
  return ref.read(programDatasourceProvider).getExercises(dayId);
});

