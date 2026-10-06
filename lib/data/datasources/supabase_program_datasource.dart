import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/training_program_model.dart';
import '../models/program_day_model.dart';
import '../models/program_exercise_model.dart';

class SupabaseProgramDatasource {
  final SupabaseClient client;
  SupabaseProgramDatasource(this.client);

  Future<TrainingProgramModel> createProgram(TrainingProgramModel program) async {
    try {
      final data = await client.from('training_programs').insert(program.toInsertJson()).select().single();
      return TrainingProgramModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء البرنامج: $e');
    }
  }

  Future<TrainingProgramModel> updateProgram(TrainingProgramModel program) async {
    try {
      final map = program.toJson()..remove('id')..remove('created_at');
      final data = await client.from('training_programs').update(map).eq('id', program.id).select().single();
      return TrainingProgramModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث البرنامج: $e');
    }
  }

  Future<void> deactivateProgram(int id) async {
    try {
      await client.from('training_programs').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تعطيل البرنامج: $e');
    }
  }

  Future<TrainingProgramModel> getProgramById(int id) async {
    try {
      final data = await client.from('training_programs').select().eq('id', id).single();
      return TrainingProgramModel.fromJson(data);
    } catch (e) {
      throw ServerException('البرنامج غير موجود: $e');
    }
  }

  Future<List<TrainingProgramModel>> getProgramsByTrainee(String traineeId) async {
    try {
      final data = await client.from('training_programs').select().eq('trainee_id', traineeId).eq('is_active', true).order('created_at', ascending: false);
      return (data as List).map((e) => TrainingProgramModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب برامج المتدرب: $e');
    }
  }

  Future<List<TrainingProgramModel>> getProgramsByTrainer(String trainerId) async {
    try {
      final data = await client.from('training_programs').select().eq('trainer_id', trainerId).order('created_at', ascending: false);
      return (data as List).map((e) => TrainingProgramModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب برامج المدرب: $e');
    }
  }

  // Days
  Future<ProgramDayModel> addDay(ProgramDayModel day) async {
    try {
      final data = await client.from('program_days').insert(day.toInsertJson()).select().single();
      return ProgramDayModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إضافة يوم للبرنامج: $e');
    }
  }

  Future<List<ProgramDayModel>> getDays(int programId) async {
    try {
      final data = await client.from('program_days').select().eq('program_id', programId).order('order_index');
      return (data as List).map((e) => ProgramDayModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب أيام البرنامج: $e');
    }
  }

  Future<void> deleteDay(int id) async {
    try {
      await client.from('program_days').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف يوم البرنامج: $e');
    }
  }

  // Exercises
  Future<ProgramExerciseModel> addExercise(ProgramExerciseModel ex) async {
    try {
      final data = await client.from('program_exercises').insert(ex.toInsertJson()).select().single();
      return ProgramExerciseModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إضافة تمرين: $e');
    }
  }

  Future<List<ProgramExerciseModel>> getExercises(int dayId) async {
    try {
      final data = await client.from('program_exercises').select().eq('day_id', dayId).order('order_index');
      return (data as List).map((e) => ProgramExerciseModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب تمارين اليوم: $e');
    }
  }

  Future<void> deleteExercise(int id) async {
    try {
      await client.from('program_exercises').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف التمرين: $e');
    }
  }

  Future<ProgramExerciseModel> updateExercise(ProgramExerciseModel ex) async {
    try {
      final map = ex.toJson()..remove('id');
      final data = await client.from('program_exercises').update(map).eq('id', ex.id).select().single();
      return ProgramExerciseModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث التمرين: $e');
    }
  }

  Future<void> deleteProgram(int id) async {
    try {
      await client.from('program_exercises').delete().eq('day_id', id);
      await client.from('program_days').delete().eq('program_id', id);
      await client.from('training_programs').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف البرنامج: $e');
    }
  }
}
