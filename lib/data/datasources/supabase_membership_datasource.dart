import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/membership_model.dart';

class SupabaseMembershipDatasource {
  final SupabaseClient client;
  SupabaseMembershipDatasource(this.client);

  /// يحوّل العضويات منتهية المدة إلى 'expired' في القاعدة قبل أي قراءة.
  /// best-effort: إذا لم تُطبَّق هجرة 008 بعد، نتابع ويعتمد التطبيق على
  /// التطبيع داخل MembershipModel.fromJson.
  Future<void> _expireDueMemberships() async {
    try {
      await client.rpc('expire_due_memberships');
    } catch (_) {
      // الهجرة غير مطبقة/غير متاحة — لا نفشل العملية بسببها.
    }
  }

  Future<List<MembershipModel>> getAllMemberships() async {
    try {
      await _expireDueMemberships();
      final data = await client
          .from('memberships')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => MembershipModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب الاشتراكات: $e');
    }
  }

  Future<List<MembershipModel>> getMembershipsByTrainee(
      String traineeId) async {
    try {
      await _expireDueMemberships();
      final data = await client
          .from('memberships')
          .select()
          .eq('trainee_id', traineeId)
          .order('start_date', ascending: false);
      return (data as List).map((e) => MembershipModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب اشتراكات المتدرب: $e');
    }
  }

  Future<MembershipModel?> getActiveMembership(String traineeId) async {
    try {
      await _expireDueMemberships();
      final data = await client
          .from('memberships')
          .select()
          .eq('trainee_id', traineeId)
          .eq('status', 'active')
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return MembershipModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل جلب الاشتراك النشط: $e');
    }
  }

  /// آخر عضوية للمتدرب مهما كانت حالتها (للعرض: نشطة أو منتهية).
  Future<MembershipModel?> getLatestMembership(String traineeId) async {
    try {
      await _expireDueMemberships();
      final data = await client
          .from('memberships')
          .select()
          .eq('trainee_id', traineeId)
          .order('end_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return MembershipModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل جلب آخر اشتراك: $e');
    }
  }

  Future<MembershipModel> createMembership(MembershipModel membership) async {
    try {
      if (!membership.endDate.isAfter(membership.startDate)) {
        throw ServerException('تاريخ الانتهاء يجب أن يكون بعد تاريخ البداية');
      }
      final overlap = await client
          .from('memberships')
          .select('id')
          .eq('trainee_id', membership.traineeId)
          .eq('status', 'active')
          .gte('end_date',
              membership.startDate.toIso8601String().split('T').first)
          .lte('start_date',
              membership.endDate.toIso8601String().split('T').first);
      if ((overlap as List).isNotEmpty) {
        throw ServerException('توجد عضوية نشطة متداخلة مع هذه الفترة');
      }
      final data = await client
          .from('memberships')
          .insert(membership.toInsertJson())
          .select()
          .single();
      return MembershipModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء الاشتراك: $e');
    }
  }

  Future<MembershipModel> renewMembership(
      String traineeId, DateTime newEndDate, String recordedBy) async {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final normalizedEnd =
          DateTime(newEndDate.year, newEndDate.month, newEndDate.day);
      if (!normalizedEnd.isAfter(normalizedToday)) {
        throw ServerException(
            'تاريخ الانتهاء الجديد يجب أن يكون بعد تاريخ اليوم');
      }
      final active = await getActiveMembership(traineeId);
      if (active == null) {
        final toInsert = {
          'trainee_id': traineeId,
          'start_date': normalizedToday.toIso8601String().split('T').first,
          'end_date': normalizedEnd.toIso8601String().split('T').first,
          'status': 'active',
          'recorded_by': recordedBy,
        };
        final data =
            await client.from('memberships').insert(toInsert).select().single();
        return MembershipModel.fromJson(data);
      }
      if (!newEndDate.isAfter(active.endDate)) {
        throw ServerException(
          'تاريخ الانتهاء الجديد (${normalizedEnd.toIso8601String().split('T').first}) يجب أن يكون بعد تاريخ الانتهاء الحالي (${active.endDate.toIso8601String().split('T').first})',
        );
      }
      final data = await client
          .from('memberships')
          .update(
              {'end_date': normalizedEnd.toIso8601String().split('T').first})
          .eq('id', active.id)
          .select()
          .single();
      return MembershipModel.fromJson(data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('فشل تجديد الاشتراك: $e');
    }
  }

  Future<MembershipModel> checkStatus(String traineeId) async {
    final active = await getActiveMembership(traineeId);
    if (active == null) throw ServerException('لا يوجد اشتراك نشط');
    return active;
  }

  Future<void> deleteMembership(int id) async {
    try {
      await client.from('memberships').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الاشتراك: $e');
    }
  }
}
