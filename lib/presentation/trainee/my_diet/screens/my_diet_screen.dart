import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../trainer/diet_builder/controllers/diet_builder_controller.dart';
import '../controllers/my_diet_controller.dart';

class MyDietScreen extends ConsumerWidget {
  const MyDietScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myDietProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('خطتي الغذائية')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل خطتك...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(myDietProvider)),
        data: (diets) {
          if (diets.isEmpty) return const Center(child: Text('لا توجد خطة مسندة إليك بعد', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: diets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final diet = diets[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(diet.name, style: Theme.of(context).textTheme.titleMedium)), const StatusBadge(label: 'نشطة', variant: BadgeVariant.active)]),
                    if (diet.description != null) ...[const SizedBox(height: 4), Text(diet.description!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))],
                    const SizedBox(height: 12),
                    _DietDays(dietId: diet.id),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// أيام خطة واحدة — مزود عائلي بدل FutureBuilder داخل build.
class _DietDays extends ConsumerWidget {
  final int dietId;
  const _DietDays({required this.dietId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(dietDaysProvider(dietId));
    return daysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.success)),
      error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(dietDaysProvider(dietId))),
      data: (days) {
        if (days.isEmpty) return const Text('لا توجد أيام بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
        return Column(
          children: days
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.restaurant, size: 16, color: AppColors.success)),
                      title: Text(DayOfWeekHelper.name(d.dayOfWeek), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      children: [_DietMeals(dayId: d.id)],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

/// وجبات يوم واحد — مزود عائلي بدل FutureBuilder متداخل.
class _DietMeals extends ConsumerWidget {
  final int dayId;
  const _DietMeals({required this.dayId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(dietMealsProvider(dayId));
    return mealsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: AppColors.success)),
      error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(dietMealsProvider(dayId))),
      data: (meals) {
        if (meals.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('لا توجد وجبات', style: TextStyle(color: AppColors.textMuted, fontSize: 11)));
        return Column(
          children: meals
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.mealType, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)), Text(m.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
                      if (m.calories != null) Text('${m.calories} سعرة', style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ))
              .toList(),
        );
      },
    );
  }
}
