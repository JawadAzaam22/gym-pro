import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../../data/models/diet_meal_model.dart';
import '../../../../data/providers.dart';
import '../controllers/diet_builder_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class MealsScreen extends ConsumerStatefulWidget {
  final int dayId;
  const MealsScreen({super.key, required this.dayId});
  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  int _refresh = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('وجبات يوم #${widget.dayId}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(context),
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('وجبة جديدة', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        key: ValueKey(_refresh),
        future: ref.read(dietDatasourceProvider).getMeals(widget.dayId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (snap.hasError) return Center(child: Text('خطأ: ${snap.error}', style: const TextStyle(color: AppColors.error)));
          final meals = snap.data!;
          if (meals.isEmpty) return const Center(child: Text('لا توجد وجبات — أضف الأولى', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = meals[i];
              return AppCard(
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.restaurant, size: 16, color: AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.mealType, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)), Text(m.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)), if (m.calories != null) Text('${m.calories} سعرة', style: const TextStyle(color: AppColors.warning, fontSize: 11))])),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _editMeal(context, m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: () async {
                      try {
                        await ref.read(dietDatasourceProvider).deleteMeal(m.id);
                        ref.invalidate(dietMealsProvider(widget.dayId));
                        if (mounted) setState(() => _refresh++);
                      } catch (err) {
                        if (mounted) AppToast.error(context, 'فشل الحذف: $err');
                      }
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _addMeal(BuildContext context) {
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('وجبة جديدة', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'نوع الوجبة (فطور/غداء/عشاء/سناك)')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 2),
            TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'السعرات (اختياري)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (typeCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(dietDatasourceProvider).addMeal(DietMealModel(
                      id: 0,
                      dayId: widget.dayId,
                      mealType: typeCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      calories: int.tryParse(calCtrl.text.trim()),
                      orderIndex: 0,
                    ));
                ref.invalidate(dietMealsProvider(widget.dayId));
                if (mounted) {
                  setState(() => _refresh++);
                  AppToast.success(context, 'تمت الإضافة');
                }
              } catch (e) {
                if (mounted) AppToast.error(context, 'فشل: $e');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editMeal(BuildContext context, DietMealModel m) {
    final typeCtrl = TextEditingController(text: m.mealType);
    final descCtrl = TextEditingController(text: m.description);
    final calCtrl = TextEditingController(text: m.calories?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('تعديل الوجبة', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'نوع الوجبة (فطور/غداء/عشاء/سناك)')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'الوصف'), maxLines: 2),
            TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'السعرات (اختياري)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (typeCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(dietDatasourceProvider).updateMeal(DietMealModel(
                      id: m.id,
                      dayId: m.dayId,
                      mealType: typeCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      calories: int.tryParse(calCtrl.text.trim()),
                      orderIndex: m.orderIndex,
                    ));
                ref.invalidate(dietMealsProvider(widget.dayId));
                if (mounted) {
                  setState(() => _refresh++);
                  AppToast.success(context, 'تم التحديث');
                }
              } catch (e) {
                if (mounted) AppToast.error(context, 'فشل: $e');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
