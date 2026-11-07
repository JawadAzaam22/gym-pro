import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';

class SupabaseAttendanceDatasource {
  final SupabaseClient client;
  SupabaseAttendanceDatasource(this.client);

  /// Records an attendance row through the `record_attendance` RPC.
  /// Membership validity, the one-check-in-per-day rule and the timestamp are
  /// all decided by the database in a single atomic call.
  Future<AttendanceModel> recordAttendance(String traineeId, String method,
      {int? sessionId}) async {
    try {
      final data = await client.rpc('record_attendance', params: {
        'p_trainee_id': traineeId,
        'p_method': method,
        if (sessionId != null) 'p_session_id': sessionId,
      });
      return AttendanceModel.fromJson(Map<String, dynamic>.from(data as Map));
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException('فشل تسجيل الحضور: $e');
    }
  }

  /// Single-use QR check-in (`check_in_by_qr` RPC): the token is consumed and
  /// the attendance row written in one transaction.
  Future<({AttendanceModel attendance, String traineeName})> checkInByQr(
      String token,
      {int? sessionId}) async {
    try {
      final data = await client.rpc('check_in_by_qr', params: {
        'p_token': token,
        if (sessionId != null) 'p_session_id': sessionId,
      });
      final json = Map<String, dynamic>.from(data as Map);
      return (
        attendance: AttendanceModel.fromJson(json),
        traineeName: (json['trainee_name'] as String?) ?? '',
      );
    } on PostgrestException catch (e) {
      throw _mapRpcError(e);
    } catch (e) {
      throw ServerException('فشل تسجيل الحضور: $e');
    }
  }

  /// Translates the stable error codes raised by the attendance RPCs into
  /// the exceptions the rest of the app already understands.
  Exception _mapRpcError(PostgrestException e) {
    switch (e.message.trim()) {
      case 'ALREADY_CHECKED_IN':
        return ServerException('تم تسجيل حضور المتدرب مسبقًا اليوم');
      case 'MEMBERSHIP_EXPIRED':
        final endDate = DateTime.tryParse('${e.details ?? ''}');
        final endStr =
            endDate?.toIso8601String().split('T').first ?? 'غير معروف';
        return MembershipExpiredException(
            'العضوية منتهية — تاريخ الانتهاء: $endStr — لا يمكن تسجيل الدخول',
            endDate);
      case 'TRAINEE_NOT_FOUND_OR_INACTIVE':
        return ServerException('المتدرب غير موجود أو حسابه غير نشط');
      case 'INVALID_QR':
      case 'INVALID_OR_EXPIRED_QR':
        return ServerException('رمز QR غير صالح أو منتهي، اطلب من المتدرب تحديثه');
      case 'PERMISSION_DENIED':
        return ServerException('ليست لديك صلاحية تسجيل الحضور');
      default:
        return ServerException('فشل تسجيل الحضور (${e.code ?? 'خطأ'})');
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
