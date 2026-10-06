import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/user_search_field.dart';
import '../../../../domain/entities/booking.dart';
import '../../../admin/sessions/controllers/sessions_controller.dart';
import '../../../admin/users/controllers/users_controller.dart';
import '../../../admin/halls/controllers/halls_controller.dart';
import '../controllers/bookings_controller.dart';

class GroupBookingsScreen extends ConsumerStatefulWidget {
  const GroupBookingsScreen({super.key});
  @override
  ConsumerState<GroupBookingsScreen> createState() =>
      _GroupBookingsScreenState();
}

class _GroupBookingsScreenState extends ConsumerState<GroupBookingsScreen> {
  String? _selectedTraineeId;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsControllerProvider);
    final countsAsync = ref.watch(sessionBookingCountsProvider);
    final usersAsync = ref.watch(usersControllerProvider);
    final hallsAsync = ref.watch(hallsControllerProvider);
    // حجوزات المتدرب المحدد — لعرض زر "إلغاء الحجز" بدل الحجز عند الحاجة.
    final traineeBookingsAsync = _selectedTraineeId == null
        ? null
        : ref.watch(traineeBookingsProvider(_selectedTraineeId!));
    final traineeBookings =
        traineeBookingsAsync?.valueOrNull ?? const <Booking>[];
    final bookingIdBySession = <int, int>{
      for (final b in traineeBookings)
        if (b.status.name == 'confirmed') b.sessionId: b.id,
    };

    final trainees = usersAsync.whenOrNull(
          data: (users) =>
              users.where((u) => u.role.name == 'trainee').toList(),
        ) ??
        [];

    final halls = hallsAsync.whenOrNull(data: (h) => h) ?? [];

    String trainerName(String? id) {
      if (id == null) return 'بدون مدرب';
      return usersAsync.whenOrNull(
            data: (users) {
              try {
                return users.firstWhere((u) => u.id == id).name;
              } catch (_) {
                return 'المدرب غير معروف';
              }
            },
          ) ??
          'المدرب غير معروف';
    }

    String hallName(int id) {
      try {
        return halls.firstWhere((h) => h.id == id).name;
      } catch (_) {
        return 'القاعة غير معروفة';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                UserSearchField(
                  users: trainees,
                  labelText: 'المتدرب للحجز',
                  prefixIcon: Icons.person,
                  selectedId: _selectedTraineeId,
                  onSelected: (user) =>
                      setState(() => _selectedTraineeId = user?.id),
                ),
                const SizedBox(height: 8),
                const Text('اختر المتدرب ثم اختر حصة للحجز أو لإلغاء حجزه',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const LoadingIndicator(message: 'جاري تحميل الحصص...'),
              error: (e, _) => AsyncErrorView(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(sessionsControllerProvider)),
              data: (sessions) => countsAsync.when(
                loading: () =>
                    const LoadingIndicator(message: 'جاري تحميل الأعداد...'),
                error: (e, _) => AsyncErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(sessionBookingCountsProvider)),
                data: (counts) {
                  if (sessions.isEmpty) {
                    return Center(
                        child: AppCard(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                          const Icon(Icons.event_busy,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          const Text('لا توجد حصص',
                              style:
                                  TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          AppButton(
                              label: 'تحديث',
                              showArrow: false,
                              onPressed: () => ref.invalidate(
                                  sessionsControllerProvider)),
                        ])));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = sessions[i];
                      final count = counts[s.id] ?? 0;
                      final isFull = count >= s.capacity;
                      final existingBookingId = bookingIdBySession[s.id];
                      final isBooked = existingBookingId != null;
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(s.name,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14))),
                              if (isBooked) ...[
                                const StatusBadge(
                                    label: 'محجوز',
                                    variant: BadgeVariant.info),
                                const SizedBox(width: 6),
                              ],
                              StatusBadge(
                                  label: s.status.name,
                                  variant: s.status.name == 'cancelled'
                                      ? BadgeVariant.danger
                                      : BadgeVariant.active),
                            ]),
                            const SizedBox(height: 4),
                            Text(s.description ?? 'بدون وصف',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.meeting_room,
                                  size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                  '${hallName(s.hallId)} • ${trainerName(s.trainerId)}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const Spacer(),
                              Text('سعة ${s.capacity}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                                '${s.startDate.toIso8601String().split('T').first} → ${s.endDate.toIso8601String().split('T').first}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      '$count / ${s.capacity} محجوز',
                                      style: TextStyle(
                                          color: isFull
                                              ? AppColors.error
                                              : AppColors.success,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: isBooked
                                      ? AppButton(
                                          label: 'إلغاء الحجز',
                                          icon: Icons.event_busy,
                                          showArrow: false,
                                          variant:
                                              AppButtonVariant.secondary,
                                          onPressed: () async {
                                            final ok = await ref
                                                .read(
                                                    bookingsControllerProvider
                                                        .notifier)
                                                .cancel(existingBookingId);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(ok
                                                  ? 'تم إلغاء حجز الحصة'
                                                  : 'فشل إلغاء الحجز'),
                                              backgroundColor: ok
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ));
                                          })
                                      : AppButton(
                                          label:
                                              isFull ? 'ممتلئة' : 'حجز',
                                          icon: isFull
                                              ? Icons.block
                                              : Icons.event_available,
                                          showArrow: false,
                                          onPressed: isFull
                                              ? null
                                              : () async {
                                                  if (_selectedTraineeId ==
                                                          null ||
                                                      _selectedTraineeId!
                                                          .isEmpty) {
                                                    ScaffoldMessenger
                                                        .of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'اختر المتدرب أولاً'),
                                                          backgroundColor:
                                                              AppColors
                                                                  .error),
                                                    );
                                                    return;
                                                  }
                                                  final ok = await ref
                                                      .read(
                                                          bookingsControllerProvider
                                                              .notifier)
                                                      .book(
                                                          _selectedTraineeId!,
                                                          s.id);
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  ScaffoldMessenger
                                                      .of(context)
                                                      .showSnackBar(
                                                      SnackBar(
                                                    content: Text(ok
                                                        ? 'تم الحجز'
                                                        : 'فشل الحجز'),
                                                    backgroundColor: ok
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                  ));
                                                })),
                            ]),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
