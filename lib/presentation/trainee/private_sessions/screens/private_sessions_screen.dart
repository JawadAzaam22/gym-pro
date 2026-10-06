import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../../domain/entities/private_training_schedule.dart';
import '../controllers/private_sessions_controller.dart';

class TraineePrivateSessionsScreen extends ConsumerWidget {
  const TraineePrivateSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // حُذفت "الجلسات المجدولة" (جلسات لمرة واحدة) نهائيًا: ميزة غير
    // مستخدمة فعليًا، والاعتماد الآن فقط على "المواعيد الثابتة" الأسبوعية.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('مواعيدي الثابتة')),
      body: _FixedScheduleTab(),
    );
  }
}

class _FixedScheduleTab extends ConsumerWidget {
  String _to12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1].substring(0, 2);
      if (hour == 0) return '12:$minute ص';
      if (hour < 12) return '$hour:$minute ص';
      if (hour == 12) return '12:$minute م';
      return '${hour - 12}:$minute م';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fixedAsync = ref.watch(traineeFixedScheduleProvider);
    return fixedAsync.when(
      loading: () =>
          const LoadingIndicator(message: 'جاري تحميل المواعيد الثابتة...'),
      error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(traineeFixedScheduleProvider)),
      data: (fixed) {
        if (fixed.isEmpty) {
          return const Center(
              child: Text('لا توجد مواعيد ثابتة',
                  style: TextStyle(color: AppColors.textMuted)));
        }
        // Group by day
        final byDay = <int, List<PrivateTrainingSchedule>>{};
        for (final s in fixed) {
          byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: DayOfWeekHelper.entries.map((entry) {
            final day = entry.key;
            final dayName = entry.value;
            final slots = byDay[day] ?? [];

            if (slots.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...slots.map((slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fitness_center,
                                  color: AppColors.info, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.trainerName ?? 'مدرب: ${slot.trainerTraineeId}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${_to12Hour(slot.startTime)} - ${_to12Hour(slot.endTime)}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}