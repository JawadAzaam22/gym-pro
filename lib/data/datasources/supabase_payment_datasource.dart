import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/payment_cost_model.dart';

class SupabasePaymentDatasource {
  final SupabaseClient client;
  SupabasePaymentDatasource(this.client);

  Future<PaymentCostModel> recordPayment(PaymentCostModel payment) async {
    try {
      final data = await client.from('payment_costs').insert(payment.toInsertJson()).select().single();
      return PaymentCostModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تسجيل الدفع: $e');
    }
  }

  Future<List<PaymentCostModel>> getPayments({String? userId, String? type, DateTime? from, DateTime? to}) async {
    try {
      // بناء تراكمي - يدعم فلترة مركبة
      // supabase_flutter لا يدعم chaining بعد eq بشكل تراكمي بسهولة، لذلك نبني الحالات الأكثر شيوعاً
      dynamic data;
      if (userId != null && type != null && from != null && to != null) {
        data = await client.from('payment_costs').select().eq('user_id', userId).eq('type', type).gte('payment_date', from.toIso8601String().split('T').first).lte('payment_date', to.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else if (userId != null && type != null) {
        data = await client.from('payment_costs').select().eq('user_id', userId).eq('type', type).order('payment_date', ascending: false);
      } else if (userId != null && from != null && to != null) {
        data = await client.from('payment_costs').select().eq('user_id', userId).gte('payment_date', from.toIso8601String().split('T').first).lte('payment_date', to.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else if (type != null && from != null && to != null) {
        data = await client.from('payment_costs').select().eq('type', type).gte('payment_date', from.toIso8601String().split('T').first).lte('payment_date', to.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else if (userId != null) {
        data = await client.from('payment_costs').select().eq('user_id', userId).order('payment_date', ascending: false);
      } else if (type != null) {
        data = await client.from('payment_costs').select().eq('type', type).order('payment_date', ascending: false);
      } else if (from != null && to != null) {
        data = await client.from('payment_costs').select().gte('payment_date', from.toIso8601String().split('T').first).lte('payment_date', to.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else if (from != null) {
        data = await client.from('payment_costs').select().gte('payment_date', from.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else if (to != null) {
        data = await client.from('payment_costs').select().lte('payment_date', to.toIso8601String().split('T').first).order('payment_date', ascending: false);
      } else {
        data = await client.from('payment_costs').select().order('payment_date', ascending: false);
      }
      return (data as List).map((e) => PaymentCostModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب المدفوعات: $e');
    }
  }

  Future<List<PaymentCostModel>> getAll() async {
    try {
      final data = await client.from('payment_costs').select().order('payment_date', ascending: false);
      return (data as List).map((e) => PaymentCostModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب كل المدفوعات: $e');
    }
  }

  Future<double> getTotalByType(String type, DateTime from, DateTime to) async {
    try {
      final data = await client.from('payment_costs').select('amount').eq('type', type).gte('payment_date', from.toIso8601String().split('T').first).lte('payment_date', to.toIso8601String().split('T').first);
      double total = 0;
      for (final row in data as List) {
        total += (row['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw ServerException('فشل حساب الإجمالي: $e');
    }
  }
}
