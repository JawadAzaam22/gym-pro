import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';

class SupabaseAttendanceDatasource {
  final SupabaseClient client;
  SupabaseAttendanceDatasource(this.client);

  Future<AttendanceModel> recordAttendance(String traineeId, String method,
      {int? sessionId}) async {
    try {
      // SRS 5.2: فحص حالة العضوية قبل تسجيل الحضور — العضوية المنتهية
      // تمنع الدخول ويُعرض تنبيه للاستقبال بدل إدراج الحضور.
      await _assertMembershipActive(traineeId);
      final dayStart = DateTime.now();
      final day = DateTime(dayStart.year, dayStart.month, dayStart.day);
      var existingQuery = client
          .from('attendance')
          .select('id')
          .eq('trainee_id', traineeId)
          .gte('check_in_time', day.toIso8601String())
          .lt('check_in_time',
              day.add(const Duration(days: 1)).toIso8601String());
      final existing = sessionId == null
          ? await existingQuery.isFilter('session_id', null)
          : await existingQuery.eq('session_id', sessionId);
      if ((existing as List).isNotEmpty) {
        throw ServerException('تم تسجيل حضور المتدرب مسبقًا اليوم');
      }
      final payload = {
        'trainee_id': traineeId,
        'check_in_time': DateTime.now().toIso8601String(),
        'method': method,
        if (sessionId != null) 'session_id': sessionId
      };
      final data =
          await client.from('attendance').insert(payload).select().single();
      return AttendanceModel.fromJson(data);
    } on MembershipExpiredException {
      rethrow;
    } catch (e) {
      throw ServerException('فشل تسجيل الحضور: $e');
    }
  }

  /// يتحقق أن آخر عضوية للمتدرب نشطة وغير منتهية:
  /// status == 'active' AND end_date >= اليوم.
  Future<void> _assertMembershipActive(String traineeId) async {
    try {
      final data = await client
          .from('memberships')
          .select('status, end_date')
          .eq('trainee_id', traineeId)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();
      DateTime? endDate;
      if (data != null && data['end_date'] != null) {
        endDate = DateTime.tryParse(data['end_date'] as String);
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final valid = data != null &&
          (data['status'] as String?) == 'active' &&
          endDate != null &&
          !endDate.isBefore(today);
      if (!valid) {
        final endStr =
            endDate?.toIso8601String().split('T').first ?? 'غير معروف';
        throw MembershipExpiredException(
            'العضوية منتهية — تاريخ الانتهاء: $endStr — لا يمكن تسجيل الدخول',
            endDate);
      }
    } on MembershipExpiredException {
      rethrow;
    } catch (e) {
      if (e is MembershipExpiredException) rethrow;
      throw ServerException('فشل التحقق من العضوية: $e');
    }
  }

  Future<List<AttendanceModel>> getAttendanceByTrainee(String traineeId) async {
    try {
      final data = await client
          .from('attendance')
          .select()
          .eq('trainee_id', traineeId)
          .order('check_in_time', ascending: false);
      return (data as List).map((e) => AttendanceModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب سجل الحضور: $e');
    }
  }

  Future<List<AttendanceModel>> getAllAttendance(
      {DateTime? from, DateTime? to}) async {
    try {
      dynamic data;
      if (from != null && to != null) {
        data = await client
            .from('attendance')
            .select()
            .gte('check_in_time', from.toIso8601String())
            .lte('check_in_time', to.toIso8601String())
            .order('check_in_time', ascending: false);
      } else if (from != null) {
        data = await client
            .from('attendance')
            .select()
            .gte('check_in_time', from.toIso8601String())
            .order('check_in_time', ascending: false);
      } else if (to != null) {
        data = await client
            .from('attendance')
            .select()
            .lte('check_in_time', to.toIso8601String())
            .order('check_in_time', ascending: false);
      } else {
        data = await client
            .from('attendance')
            .select()
            .order('check_in_time', ascending: false);
      }
      return (data as List).map((e) => AttendanceModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب كل الحضور: $e');
    }
  }

  Stream<List<AttendanceModel>> watchAttendance() {
    return client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .order('check_in_time')
        .map((list) => list.map((e) => AttendanceModel.fromJson(e)).toList());
  }
}
