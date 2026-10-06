import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/day_of_week_helper.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../../domain/entities/private_training_schedule.dart';
import '../controllers/schedule_controller.dart';

class MyScheduleScreen extends ConsumerStatefulWidget {
  const MyScheduleScreen({super.key});
  @override
  ConsumerState<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends ConsumerState<MyScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainerId = ref.watch(authControllerProvider).value?.id ?? '';
    if (trainerId.isEmpty) {
      return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: Text('سجّل الدخول أولاً',
                  style: TextStyle(color: AppColors.textMuted))));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('جدولي'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'الحصص الجماعية'),
            Tab(text: 'مواعيدي الثابتة'),
            Tab(text: 'فترات مناوبتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GroupSessionsTab(trainerId: trainerId),
          _FixedScheduleTab(trainerId: trainerId),
          _MyShiftsTab(trainerId: trainerId),
        ],
      ),
    );
  }
}

/// فترات مناوبة المدرب في القاعات (access_periods المُسندة إليه)، مُجمّعة
/// حسب اليوم ومُنسّقة بوضوح — وليست مدفونة داخل الجدول العام الضخم الذي
/// يخلط كل القاعات والحصص معًا. هذا ما طُلب تحديدًا: "سحب الفترات التي
/// فيها مدرب من الجدول وإظهارها عنده" في شاشة مستقلة.
class _MyShiftsTab extends ConsumerWidget {
  final String trainerId;
  const _MyShiftsTab({required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(trainerShiftPeriodsProvider(trainerId));
    return shiftsAsync.when(
      loading: () => const LoadingIndicator(message: 'جاري تحميل فتراتك...'),
      error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(trainerShiftPeriodsProvider(trainerId))),
      data: (shifts) {
        if (shifts.isEmpty) {
          return const Center(
              child: Text('لا توجد فترات مناوبة مُسندة إليك بعد',
                  style: TextStyle(color: AppColors.textMuted)));
        }
        // تجميع حسب اليوم (0=السبت .. 6=الجمعة) للعرض بترتيب واضح.
        final byDay = <int, List<TrainerShiftPeriod>>{};
        for (final s in shifts) {
          byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
        }
        final days = byDay.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: days.expand((day) {
            final items = byDay[day]!
              ..sort((a, b) => a.startTime.compareTo(b.startTime));
            return [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 12),
                child: Text(DayOfWeekHelper.name(day),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(children: [
                        const Icon(Icons.meeting_room,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.hallName,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text('${s.startTime} - ${s.endTime}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusBadge(
                            label: s.isActive ? 'نشط' : 'موقوف',
                            variant: s.isActive
                                ? BadgeVariant.active
                                : BadgeVariant.danger),
                      ]),
                    ),
                  )),
            ];
          }).toList(),
        );
      },
    );
  }
}

class _GroupSessionsTab extends ConsumerWidget {
  final String trainerId;
  const _GroupSessionsTab({required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(trainerSessionsDisplayProvider(trainerId));
    return sessionsAsync.when(
      loading: () =>
          const LoadingIndicator(message: 'جاري تحميل الحصص الجماعية...'),
      error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(trainerSessionsDisplayProvider(trainerId))),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
              child: Text('لا توجد حصص جماعية مجدولة',
                  style: TextStyle(color: AppColors.textMuted)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: items.map((item) {
            final s = item.session;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.class_,
                              color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(s.name,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text('${item.hallName} • سعة ${s.capacity}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ])),
                      StatusBadge(
                          label: s.status.name,
                          variant: s.status.name == 'cancelled'
                              ? BadgeVariant.danger
                              : BadgeVariant.active),
                    ]),
                    const Divider(height: 16, color: AppColors.border),
                    Row(children: [
                      const Icon(Icons.schedule,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(item.scheduleText,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12))),
                    ]),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FixedScheduleTab extends ConsumerWidget {
  final String trainerId;
  const _FixedScheduleTab({required this.trainerId});

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
    final fixedAsync = ref.watch(trainerFixedScheduleProvider(trainerId));
    return fixedAsync.when(
      loading: () =>
          const LoadingIndicator(message: 'جاري تحميل المواعيد الثابتة...'),
      error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(trainerFixedScheduleProvider(trainerId))),
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
                                color: AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_add_alt_1,
                                  color: AppColors.warning, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.traineeName ?? 'متدرب: ${slot.trainerTraineeId}',
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
