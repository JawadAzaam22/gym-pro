import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/session_model.dart';

class SupabaseSessionDatasource {
  final SupabaseClient client;
  SupabaseSessionDatasource(this.client);

  Future<List<SessionModel>> getSessions() async {
    try {
      final data = await client.from('sessions').select().order('start_date');
      return (data as List).map((e) => SessionModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب الحصص: $e');
    }
  }

  Future<SessionModel> getSessionById(int id) async {
    try {
      final data = await client.from('sessions').select().eq('id', id).single();
      return SessionModel.fromJson(data);
    } catch (e) {
      throw ServerException('الحصة غير موجودة: $e');
    }
  }

  Future<List<SessionModel>> getSessionsByTrainer(String trainerId) async {
    try {
      final data = await client.from('sessions').select().eq('trainer_id', trainerId).order('start_date');
      return (data as List).map((e) => SessionModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب حصص المدرب: $e');
    }
  }

  Future<List<SessionModel>> getSessionsByHall(int hallId) async {
    try {
      final data = await client.from('sessions').select().eq('hall_id', hallId).order('start_date');
      return (data as List).map((e) => SessionModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب حصص القاعة: $e');
    }
  }

  Future<SessionModel> createSession(SessionModel session) async {
    try {
      final data = await client.from('sessions').insert(session.toInsertJson()).select().single();
      return SessionModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء الحصة: $e');
    }
  }

  Future<SessionModel> updateSession(SessionModel session) async {
    try {
      final map = session.toJson()..remove('id')..remove('created_at');
      final data = await client.from('sessions').update(map).eq('id', session.id).select().single();
      return SessionModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث الحصة: $e');
    }
  }

  Future<void> cancelSession(int id) async {
    try {
      await client.from('sessions').update({'status': 'cancelled'}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل إلغاء الحصة: $e');
    }
  }

  Future<void> createSessionPeriods(int sessionId, List<int> accessPeriodIds) async {
    try {
      final rows = accessPeriodIds
          .map((apId) => {'session_id': sessionId, 'access_period_id': apId})
          .toList();
      await client.from('session_periods').insert(rows);
    } catch (e) {
      throw ServerException('فشل إنشاء ربط الفترات: $e');
    }
  }

  Future<Map<int, Set<int>>> getAllSessionPeriods() async {
    try {
      final data = await client.from('session_periods').select('session_id, access_period_id');
      final result = <int, Set<int>>{};
      for (final row in (data as List)) {
        final sessionId = row['session_id'] as int;
        final apId = row['access_period_id'] as int;
        result.putIfAbsent(sessionId, () => {}).add(apId);
      }
      return result;
    } catch (e) {
      throw ServerException('فشل جلب ربط الفترات: $e');
    }
  }

  Future<Set<int>> getSessionPeriods(int sessionId) async {
    try {
      final data = await client
          .from('session_periods')
          .select('access_period_id')
          .eq('session_id', sessionId);
      return (data as List).map((e) => e['access_period_id'] as int).toSet();
    } catch (e) {
      throw ServerException('فشل جلب فترات الحصة: $e');
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await client.from('session_periods').delete().eq('session_id', id);
      await client.from('sessions').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الحصة: $e');
    }
  }
}
