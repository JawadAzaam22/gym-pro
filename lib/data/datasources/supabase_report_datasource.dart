import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/report_model.dart';

class SupabaseReportDatasource {
  final SupabaseClient client;
  SupabaseReportDatasource(this.client);

  Future<ReportModel> generateReport(
    String type,
    String title,
    String? description,
    String generatedBy, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final row = await client.from('reports').insert({
        'type': type,
        'title': title,
        'description': description,
        'generated_by': generatedBy,
        if (data != null) 'data': data,
      }).select().single();
      return ReportModel.fromJson(row);
    } catch (e) {
      throw ServerException('فشل إنشاء التقرير: $e');
    }
  }

  Future<List<ReportModel>> getReports() async {
    try {
      final data = await client
          .from('reports')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب التقارير: $e');
    }
  }

  Future<void> deleteReport(int id) async {
    try {
      await client.from('reports').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف التقرير: $e');
    }
  }

  /// حذف كل التقارير المحفوظة دفعة واحدة (زر "مسح كل التقارير").
  Future<void> deleteAllReports() async {
    try {
      // شرط .neq('id', 0) مطلوب لأن Supabase يرفض DELETE بدون شرط WHERE.
      await client.from('reports').delete().neq('id', 0);
    } catch (e) {
      throw ServerException('فشل حذف كل التقارير: $e');
    }
  }

  Future<Map<String, dynamic>> getFinancialSummary(
      DateTime from, DateTime to) async {
    try {
      final payments = await client
          .from('payment_costs')
          .select('type, amount, category')
          .gte('payment_date', from.toIso8601String().split('T').first)
          .lte('payment_date', to.toIso8601String().split('T').first);
      double income = 0, expense = 0;
      final Map<String, double> byCategory = {};
      for (final row in payments as List) {
        final amt = (row['amount'] as num).toDouble();
        final cat = row['category'] as String;
        byCategory[cat] = (byCategory[cat] ?? 0) + amt;
        if (row['type'] == 'income') {
          income += amt;
        } else {
          expense += amt;
        }
      }
      return {
        'income': income,
        'expense': expense,
        'net': income - expense,
        'by_category': byCategory,
      };
    } catch (e) {
      throw ServerException('فشل ملخص المالية: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(
      DateTime from, DateTime to) async {
    try {
      final data = await client
          .from('attendance')
          .select('id, trainee_id, check_in_time')
          .gte('check_in_time', from.toIso8601String())
          .lte('check_in_time', to.toIso8601String());
      final list = data as List;
      final uniqueTrainees = <String>{};
      final Map<String, int> daily = {};
      for (final row in list) {
        uniqueTrainees.add(row['trainee_id'] as String);
        final day =
            (row['check_in_time'] as String).substring(0, 10);
        daily[day] = (daily[day] ?? 0) + 1;
      }
      final days = daily.length;
      return {
        'total_checkins': list.length,
        'unique_trainees': uniqueTrainees.length,
        'daily': daily,
        'avg_per_day': days > 0 ? (list.length / days).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      throw ServerException('فشل ملخص الحضور: $e');
    }
  }

  Future<Map<String, dynamic>> getOperationalSummary(
      DateTime from, DateTime to) async {
    try {
      final halls = await client
          .from('halls')
          .select('id, name')
          .eq('is_active', true);
      final allPeriods = await client
          .from('access_periods')
          .select('id, hall_id, day_of_week')
          .eq('is_active', true);
      final sessions = await client
          .from('sessions')
          .select('id, hall_id, capacity, status, start_date')
          .gte('start_date', from.toIso8601String().split('T').first)
          .lte('start_date', to.toIso8601String().split('T').first)
          .neq('status', 'cancelled');
      final allBookings = await client
          .from('bookings')
          .select('session_id')
          .eq('status', 'confirmed');
      final memberships = await client
          .from('memberships')
          .select('start_date, end_date, status');

      final bookingCounts = <int, int>{};
      for (final b in allBookings as List) {
        final sid = b['session_id'] as int;
        bookingCounts[sid] = (bookingCounts[sid] ?? 0) + 1;
      }

      final hallOccupancy = <String, double>{};
      for (final hall in halls as List) {
        final hallId = hall['id'] as int;
        final hallName = hall['name'] as String;
        final periodCount = (allPeriods as List)
            .where((p) => p['hall_id'] == hallId)
            .length;
        final sessionCount = (sessions as List)
            .where((s) => s['hall_id'] == hallId)
            .length;
        hallOccupancy[hallName] = periodCount > 0
            ? (sessionCount / periodCount * 100).clamp(0, 100)
            : 0.0;
      }

      int newMemberships = 0;
      int expiringSoon = 0;
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      for (final m in memberships as List) {
        final startDate = m['start_date'] as String;
        final endDate = m['end_date'] as String;
        if (startDate.compareTo(from.toIso8601String().split('T').first) >=
            0 &&
            startDate.compareTo(to.toIso8601String().split('T').first) <=
                0) {
          newMemberships++;
        }
        if (endDate.compareTo(now.toIso8601String().split('T').first) >=
            0 &&
            endDate.compareTo(sevenDaysLater.toIso8601String().split('T').first) <=
                0) {
          expiringSoon++;
        }
      }

      double totalCapacity = 0;
      double totalBooked = 0;
      for (final s in sessions as List) {
        final cap = (s['capacity'] as num).toDouble();
        final sid = s['id'] as int;
        totalCapacity += cap;
        totalBooked += (bookingCounts[sid] ?? 0).toDouble();
      }

      return {
        'hall_occupancy': hallOccupancy,
        'new_memberships': newMemberships,
        'expiring_soon': expiringSoon,
        'course_fill_rate': totalCapacity > 0
            ? (totalBooked / totalCapacity * 100).toStringAsFixed(1)
            : '0',
        'total_sessions': (sessions as List).length,
      };
    } catch (e) {
      throw ServerException('فشل الملخص التشغيلي: $e');
    }
  }
}
