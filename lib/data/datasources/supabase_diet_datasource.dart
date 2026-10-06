import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';
import '../models/diet_model.dart';
import '../models/diet_day_model.dart';
import '../models/diet_meal_model.dart';

class SupabaseDietDatasource {
  final SupabaseClient client;
  SupabaseDietDatasource(this.client);

  Future<DietModel> createDiet(DietModel diet) async {
    try {
      final data = await client.from('diets').insert(diet.toInsertJson()).select().single();
      return DietModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إنشاء الخطة الغذائية: $e');
    }
  }

  Future<DietModel> updateDiet(DietModel diet) async {
    try {
      final map = diet.toJson()..remove('id')..remove('created_at');
      final data = await client.from('diets').update(map).eq('id', diet.id).select().single();
      return DietModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث الخطة: $e');
    }
  }

  Future<void> deactivateDiet(int id) async {
    try {
      await client.from('diets').update({'is_active': false}).eq('id', id);
    } catch (e) {
      throw ServerException('فشل تعطيل الخطة: $e');
    }
  }

  Future<DietModel> getDietById(int id) async {
    try {
      final data = await client.from('diets').select().eq('id', id).single();
      return DietModel.fromJson(data);
    } catch (e) {
      throw ServerException('الخطة غير موجودة: $e');
    }
  }

  Future<List<DietModel>> getDietsByTrainee(String traineeId) async {
    try {
      final data = await client.from('diets').select().eq('trainee_id', traineeId).eq('is_active', true).order('created_at', ascending: false);
      return (data as List).map((e) => DietModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب خطط المتدرب: $e');
    }
  }

  Future<List<DietModel>> getDietsByTrainer(String trainerId) async {
    try {
      final data = await client.from('diets').select().eq('trainer_id', trainerId).order('created_at', ascending: false);
      return (data as List).map((e) => DietModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب خطط المدرب: $e');
    }
  }

  Future<DietDayModel> addDay(DietDayModel day) async {
    try {
      final data = await client.from('diet_days').insert(day.toInsertJson()).select().single();
      return DietDayModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إضافة يوم للخطة: $e');
    }
  }

  Future<List<DietDayModel>> getDays(int dietId) async {
    try {
      final data = await client.from('diet_days').select().eq('diet_id', dietId).order('order_index');
      return (data as List).map((e) => DietDayModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب أيام الخطة: $e');
    }
  }

  Future<DietMealModel> addMeal(DietMealModel meal) async {
    try {
      final data = await client.from('diet_meals').insert(meal.toInsertJson()).select().single();
      return DietMealModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل إضافة وجبة: $e');
    }
  }

  Future<List<DietMealModel>> getMeals(int dayId) async {
    try {
      final data = await client.from('diet_meals').select().eq('day_id', dayId).order('order_index');
      return (data as List).map((e) => DietMealModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب وجبات اليوم: $e');
    }
  }

  Future<DietMealModel> updateMeal(DietMealModel meal) async {
    try {
      final map = meal.toJson()..remove('id');
      final data = await client.from('diet_meals').update(map).eq('id', meal.id).select().single();
      return DietMealModel.fromJson(data);
    } catch (e) {
      throw ServerException('فشل تحديث الوجبة: $e');
    }
  }

  Future<void> deleteMeal(int id) async {
    try {
      await client.from('diet_meals').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الوجبة: $e');
    }
  }

  /// يحذف يومًا واحدًا فقط من خطة غذائية (ووجباته تلقائيًا عبر CASCADE في
  /// قاعدة البيانات). كانت شاشة "حذف اليوم" تستدعي deleteDiet(dayId) خطأً —
  /// أي تمرير معرّف اليوم كأنه معرّف الخطة الغذائية كاملة، فيحذف خطة غذائية
  /// عشوائية أخرى (أيًا كانت التي تملك نفس الرقم) بدل حذف اليوم المقصود.
  Future<void> deleteDay(int id) async {
    try {
      await client.from('diet_days').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف اليوم: $e');
    }
  }

  Future<void> deleteDiet(int id) async {
    try {
      // diet_days و diet_meals تُحذف تلقائيًا عبر ON DELETE CASCADE في
      // القاعدة، فلا حاجة لحذفها يدويًا هنا (الكود القديم كان يخلط بين
      // معرّف اليوم ومعرّف الخطة في نفس المتغير id، وهو خطأ منطقي بحت).
      await client.from('diets').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الخطة الغذائية: $e');
    }
  }
}
