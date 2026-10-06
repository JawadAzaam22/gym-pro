import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/hall_model.dart';
import '../models/access_period_model.dart';

class SupabaseHallDatasource {
  final SupabaseClient client;
  SupabaseHallDatasource(this.client);

  // Halls
  Future<List<HallModel>> getHalls() async {
    try {
      final data = await client.from('halls').select().order('name');
      return (data as List).map((e) => HallModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب القاعات: $e');
    }
  }

  Future<HallModel> getHallById(int id) async {
    try {
      final data = await client.from('halls').select().eq('id', id).single();
      return HallModel.fromJson(data);
    } catch (e) {
      throw ServerException('القاعة غير موجودة: $e');
    }
  }

  Future<HallModel> createHall(HallModel hall) async {
    try {
      final data = await client.from('halls').insert(hall.toInsertJson()).select().single();
      return HallModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء القاعة: $e');
    }
  }

  Future<HallModel> updateHall(HallModel hall) async {
    try {
      final map = hall.toJson()..remove('id');
      final data = await client.from('halls').update(map).eq('id', hall.id).select().single();
      return HallModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث القاعة: $e');
    }
  }

  Future<void> deactivateHall(int id) async {
    try {
      await client.from('halls').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تعطيل القاعة: $e');
    }
  }

  // Access Periods
  Future<List<AccessPeriodModel>> getAccessPeriods(int hallId) async {
    try {
      final data = await client.from('access_periods').select().eq('hall_id', hallId).order('day_of_week').order('start_time');
      return (data as List).map((e) => AccessPeriodModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب فترات الوصول: $e');
    }
  }

  Future<List<AccessPeriodModel>> getAllAccessPeriods() async {
    try {
      final data = await client.from('access_periods').select().order('hall_id');
      return (data as List).map((e) => AccessPeriodModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب كل فترات الوصول: $e');
    }
  }

  Future<AccessPeriodModel> createAccessPeriod(AccessPeriodModel period) async {
    try {
      final data = await client.from('access_periods').insert(period.toInsertJson()).select().single();
      return AccessPeriodModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء فترة الوصول: $e');
    }
  }

  Future<AccessPeriodModel> updateAccessPeriod(AccessPeriodModel period) async {
    try {
      final map = period.toJson()..remove('id');
      final data = await client.from('access_periods').update(map).eq('id', period.id).select().single();
      return AccessPeriodModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث فترة الوصول: $e');
    }
  }

  Future<void> deleteAccessPeriod(int id) async {
    try {
      await client.from('access_periods').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف فترة الوصول: $e');
    }
  }
}
