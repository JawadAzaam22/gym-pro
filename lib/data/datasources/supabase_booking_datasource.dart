import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/booking_model.dart';
import '../models/trainer_trainee_model.dart';
import '../models/private_training_session_model.dart';
import '../models/private_training_schedule_model.dart';

class SupabaseBookingDatasource {
  final SupabaseClient client;
  SupabaseBookingDatasource(this.client);

  // Group bookings
  Future<List<BookingModel>> getBookingsBySession(int sessionId) async {
    try {
      final data = await client
          .from('bookings')
          .select()
          .eq('session_id', sessionId)
          .order('created_at');
      return (data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب حجوزات الحصة: $e');
    }
  }

  Future<List<BookingModel>> getBookingsByTrainee(String traineeId) async {
    try {
      final data = await client
          .from('bookings')
          .select()
          .eq('trainee_id', traineeId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب حجوزات المتدرب: $e');
    }
  }

  Future<BookingModel> bookSession(String traineeId, int sessionId) async {
    try {
      // تحقق السعة
      final session = await client
          .from('sessions')
          .select('capacity')
          .eq('id', sessionId)
          .single();
      final capacity = session['capacity'] as int;
      final countRes = await client
          .from('bookings')
          .select('id')
          .eq('session_id', sessionId)
          .eq('status', 'confirmed');
      final currentCount = (countRes as List).length;
      if (currentCount >= capacity) throw ServerException('الحصة ممتلئة');

      // تحقق عدم التكرار (لرسالة أوضح)
      final existing = await client
          .from('bookings')
          .select()
          .eq('trainee_id', traineeId)
          .eq('session_id', sessionId)
          .eq('status', 'confirmed')
          .maybeSingle();
      if (existing != null) {
        throw ServerException('أنت محجوز مسبقًا في هذه الحصة');
      }

      try {
        final data = await client
            .from('bookings')
            .insert({
              'trainee_id': traineeId,
              'session_id': sessionId,
              'status': 'confirmed'
            })
            .select()
            .single();
        return BookingModel.fromJson(data);
      } catch (e) {
        // القيد الفريد في القاعدة: UNIQUE (trainee_id, session_id) WHERE status='confirmed'
        // يمنع التكرار فعليًا حتى مع تزامن الطلبات — نحوّله لرسالة صريحة.
        if (e.toString().contains('23505') ||
            e.toString().contains('duplicate') ||
            e.toString().contains('unique')) {
          throw ServerException('أنت محجوز مسبقًا في هذه الحصة');
        }
        rethrow;
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل الحجز: $e');
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      await client
          .from('bookings')
          .update({'status': 'cancelled'}).eq('id', bookingId);
    } catch (e) {
      throw ServerException('فشل إلغاء الحجز: $e');
    }
  }

  Future<int> getBookingCount(int sessionId) async {
    try {
      final data = await client
          .from('bookings')
          .select('id')
          .eq('session_id', sessionId)
          .eq('status', 'confirmed');
      return (data as List).length;
    } catch (e) {
      throw ServerException('U?O?U, O?U,O" O?U,U-O?U?O?O?U? O?U,O-O?O?: $e');
    }
  }

  /// يجلب أعداد الحجوزات المؤكدة لكل الحصص بطلب واحد (بديل N+1).
  /// يعيد خريطة sessionId -> count.
  Future<Map<int, int>> getAllBookingCounts() async {
    try {
      final data = await client
          .from('bookings')
          .select('session_id')
          .eq('status', 'confirmed');
      final counts = <int, int>{};
      for (final row in (data as List)) {
        final sid = (row as Map)['session_id'] as int?;
        if (sid != null) counts[sid] = (counts[sid] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      throw ServerException('تعذر جلب أعداد الحجوزات: $e');
    }
  }

  // Trainer-Trainee relations
  Future<List<TrainerTraineeModel>> getTrainerTrainees(
      {String? trainerId, String? traineeId}) async {
    try {
      var query = client
          .from('trainer_trainees')
          .select('*, trainer:profiles!trainer_trainees_trainer_id_fkey(name), trainee:profiles!trainer_trainees_trainee_id_fkey(name)');
      if (trainerId != null) {
        final data = await query
            .eq('trainer_id', trainerId)
            .eq('status', 'active')
            .order('assigned_at');
        return (data as List)
            .map((e) => TrainerTraineeModel.fromJson(e))
            .toList();
      }
      if (traineeId != null) {
        final data = await query
            .eq('trainee_id', traineeId)
            .eq('status', 'active')
            .order('assigned_at');
        return (data as List)
            .map((e) => TrainerTraineeModel.fromJson(e))
            .toList();
      }
      final data = await query.order('assigned_at');
      return (data as List)
          .map((e) => TrainerTraineeModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerException('فشل جلب علاقات المدربين: $e');
    }
  }

  Future<TrainerTraineeModel> assignTrainer(
      String trainerId, String traineeId, String assignedBy) async {
    try {
      final data = await client
          .from('trainer_trainees')
          .insert({
            'trainer_id': trainerId,
            'trainee_id': traineeId,
            'status': 'active',
            'assigned_by': assignedBy
          })
          .select()
          .single();
      return TrainerTraineeModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تعيين المدرب: $e');
    }
  }

  Future<TrainerTraineeModel> changeTrainerAssignment(
      int assignmentId, String newTrainerId) async {
    try {
      final data = await client
          .from('trainer_trainees')
          .update({'trainer_id': newTrainerId})
          .eq('id', assignmentId)
          .select()
          .single();
      return TrainerTraineeModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تغيير تعيين المدرب: $e');
    }
  }

  Future<void> deactivateTrainerAssignment(int assignmentId) async {
    try {
      await client
          .from('trainer_trainees')
          .update({'status': 'inactive'}).eq('id', assignmentId);
    } catch (e) {
      throw ServerException('فشل تعطيل التعيين: $e');
    }
  }

  // Private sessions
  Future<List<PrivateTrainingSessionModel>> getPrivateSessions(
      {int? trainerTraineeId}) async {
    try {
      final data = await client
          .from('private_training_sessions')
          .select('*, trainer_trainees!inner(trainer:profiles!trainer_trainees_trainer_id_fkey(name), trainee:profiles!trainer_trainees_trainee_id_fkey(name))')
          .order('session_date');
      var sessions = (data as List)
          .map((e) => PrivateTrainingSessionModel.fromJson(e))
          .toList();
      if (trainerTraineeId != null) {
        sessions = sessions.where((s) => s.trainerTraineeId == trainerTraineeId).toList();
      }
      return sessions;
    } catch (e) {
      throw ServerException('فشل جلب الجلسات الخاصة: $e');
    }
  }

  Future<PrivateTrainingSessionModel> schedulePrivateSession(
      PrivateTrainingSessionModel session) async {
    try {
      await _assertTrainerTraineeRelation(session);
      final conflict = await client
          .from('private_training_sessions')
          .select('id')
          .eq('trainer_trainee_id', session.trainerTraineeId)
          .eq('status', 'scheduled')
          .eq('session_date', session.sessionDate.toIso8601String());
      if ((conflict as List).isNotEmpty) {
        throw ServerException('يوجد جلسة خاصة مجدولة في هذا الموعد');
      }
      final data = await client
          .from('private_training_sessions')
          .insert(session.toInsertJson())
          .select()
          .single();
      return PrivateTrainingSessionModel.fromJson(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('فشل جدولة الجلسة الخاصة: $e');
    }
  }

  Future<PrivateTrainingSessionModel> updatePrivateSession(
    int sessionId,
    PrivateTrainingSessionModel session,
  ) async {
    try {
      await _assertTrainerTraineeRelation(session);
      final conflict = await client
          .from('private_training_sessions')
          .select('id')
          .neq('id', sessionId)
          .eq('trainer_trainee_id', session.trainerTraineeId)
          .eq('status', 'scheduled')
          .eq('session_date', session.sessionDate.toIso8601String());
      if ((conflict as List).isNotEmpty) {
        throw ServerException('يوجد جلسة خاصة مجدولة في هذا الموعد');
      }
      final data = await client
          .from('private_training_sessions')
          .update({
            'trainer_trainee_id': session.trainerTraineeId,
            'session_date': session.sessionDate.toIso8601String(),
            'status': session.status.name,
            'recorded_by': session.recordedBy,
          })
          .eq('id', sessionId)
          .select()
          .single();
      return PrivateTrainingSessionModel.fromJson(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('فشل تعديل الجلسة الخاصة: $e');
    }
  }

  Future<void> _assertTrainerTraineeRelation(
      PrivateTrainingSessionModel session) async {
    final relData = await client
        .from('trainer_trainees')
        .select('trainer_id')
        .eq('id', session.trainerTraineeId)
        .maybeSingle();
    if (relData == null) {
      throw ServerException('علاقة المدرب-المتدرب غير موجودة');
    }
  }

  Future<void> cancelPrivateSession(int id) async {
    try {
      await client
          .from('private_training_sessions')
          .update({'status': 'cancelled'}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل إلغاء الجلسة الخاصة: $e');
    }
  }

  Future<void> deleteBooking(int id) async {
    try {
      await client.from('bookings').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الحجز: $e');
    }
  }

  Future<void> deletePrivateSession(int id) async {
    try {
      await client.from('private_training_sessions').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الجلسة الخاصة: $e');
    }
  }

  Future<void> deleteTrainerTraineeRelation(int id) async {
    try {
      await client.from('trainer_trainees').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف علاقة المدرب-المتدرب: $e');
    }
  }

  // Private Training Schedule (weekly fixed appointments)
  Future<List<PrivateTrainingScheduleModel>> getScheduleForTrainerTrainee(
      int trainerTraineeId) async {
    try {
      final data = await client
          .from('private_training_schedule')
          .select('*, trainer_trainees!inner(trainer:profiles!trainer_trainees_trainer_id_fkey(name), trainee:profiles!trainer_trainees_trainee_id_fkey(name))')
          .eq('trainer_trainee_id', trainerTraineeId)
          .eq('is_active', true)
          .order('day_of_week')
          .order('start_time');
      return (data as List)
          .map((e) => PrivateTrainingScheduleModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerException('فشل جلب الموعد الثابت: $e');
    }
  }

  Future<List<PrivateTrainingScheduleModel>> getScheduleForTrainer(
      String trainerId) async {
    try {
      final data = await client
          .from('private_training_schedule')
          .select('*, trainer_trainees!inner(trainer:profiles!trainer_trainees_trainer_id_fkey(name), trainee:profiles!trainer_trainees_trainee_id_fkey(name))')
          .eq('trainer_trainees.trainer_id', trainerId)
          .eq('is_active', true)
          .order('day_of_week')
          .order('start_time');
      return (data as List)
          .map((e) => PrivateTrainingScheduleModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerException('فشل جلب مواعيد المدرب الثابتة: $e');
    }
  }

  Future<List<PrivateTrainingScheduleModel>> getScheduleForTrainee(
      String traineeId) async {
    try {
      final data = await client
          .from('private_training_schedule')
          .select('*, trainer_trainees!inner(trainer:profiles!trainer_trainees_trainer_id_fkey(name), trainee:profiles!trainer_trainees_trainee_id_fkey(name))')
          .eq('trainer_trainees.trainee_id', traineeId)
          .eq('is_active', true)
          .order('day_of_week')
          .order('start_time');
      return (data as List)
          .map((e) => PrivateTrainingScheduleModel.fromJson(e))
          .toList();
    } catch (e) {
      throw ServerException('فشل جلب مواعيد المتدرب الثابتة: $e');
    }
  }

  Future<PrivateTrainingScheduleModel> addScheduleSlot(
      PrivateTrainingScheduleModel slot) async {
    try {
      final data = await client
          .from('private_training_schedule')
          .insert(slot.toInsertJson())
          .select()
          .single();
      return PrivateTrainingScheduleModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إضافة الموعد الثابت: $e');
    }
  }

  Future<PrivateTrainingScheduleModel> updateScheduleSlot(
      int id, PrivateTrainingScheduleModel slot) async {
    try {
      final data = await client
          .from('private_training_schedule')
          .update({
            'day_of_week': slot.dayOfWeek,
            'start_time': slot.startTime,
            'end_time': slot.endTime,
            'is_active': slot.isActive,
          })
          .eq('id', id)
          .select()
          .single();
      return PrivateTrainingScheduleModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تعديل الموعد الثابت: $e');
    }
  }

  Future<void> deleteScheduleSlot(int id) async {
    try {
      await client.from('private_training_schedule').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الموعد الثابت: $e');
    }
  }
}
