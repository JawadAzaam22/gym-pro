import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../trainer/program_builder/controllers/program_builder_controller.dart';
import '../controllers/my_program_controller.dart';

class MyProgramScreen extends ConsumerWidget {
  const MyProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProgramProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('برنامجي التدريبي')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل برنامجك...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(myProgramProvider)),
        data: (programs) {
          if (programs.isEmpty) return const Center(child: Text('لا يوجد برنامج مسند إليك بعد', style: TextStyle(color: AppColors.textMuted)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = programs[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleMedium)), const StatusBadge(label: 'نشط', variant: BadgeVariant.active)]),
                    if (p.description != null) ...[const SizedBox(height: 4), Text(p.description!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))],
                    Text('من ${p.startDate.toIso8601String().split('T').first}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 12),
                    _ProgramDays(programId: p.id),
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

/// أيام برنامج واحد — مزود عائلي بدل FutureBuilder داخل build.
class _ProgramDays extends ConsumerWidget {
  final int programId;
  const _ProgramDays({required this.programId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(programDaysProvider(programId));
    return daysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(programDaysProvider(programId))),
      data: (days) {
        if (days.isEmpty) return const Text('لا توجد أيام بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
        return Column(
          children: days
              .map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(DayOfWeekHelper.name(d.dayOfWeek), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text(d.muscleGroup ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      children: [_ProgramExercises(dayId: d.id)],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

/// تمارين يوم واحد — مزود عائلي بدل FutureBuilder متداخل.
class _ProgramExercises extends ConsumerWidget {
  final int dayId;
  const _ProgramExercises({required this.dayId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exAsync = ref.watch(programExercisesProvider(dayId));
    return exAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(programExercisesProvider(dayId))),
      data: (exs) {
        if (exs.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('لا توجد تمارين', style: TextStyle(color: AppColors.textMuted, fontSize: 11)));
        return Column(
          children: exs
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fitness_center, size: 14, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.exerciseName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)), Text('${e.sets ?? '-'} مجموعات × ${e.reps ?? '-'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
                    ]),
                  ))
              .toList(),
        );
      },
    );
  }
}
