import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/auth/controllers/auth_controller.dart';

final traineesAttendanceProvider = FutureProvider((ref) async {
  final trainerId = ref.read(authControllerProvider).value?.id ?? '';
  // ملاحظة: getTrainerTrainees بلا وسائط تجلب جميع العلاقات، لذا نُمرر
  // trainerId صراحة لنحصل فقط على متدربي هذا المدرب تحديدًا.
  if (trainerId.isEmpty) return <TraineeAttendanceData>[];
  final traineesRes =
      await ref.read(bookingDatasourceProvider).getTrainerTrainees(trainerId: trainerId);
  final traineeIds = traineesRes.map((t) => t.traineeId).toList();
  if (traineeIds.isEmpty) return <TraineeAttendanceData>[];

  // ملاحظة أداء: كانت هذه الشاشة تجلب سجل الحضور لكل متدرب على حدة داخل
  // حلقة for (طلب شبكة منفصل لكل متدرب)، فتصبح بطيئة جدًا مع كثرة المتدربين
  // (مثلاً 20 متدربًا = 20 طلبًا متتاليًا). نستبدلها باستدعاء واحد يجلب كل
  // سجلات الحضور دفعة واحدة (آخر 90 يومًا لتفادي جلب سجل تاريخي ضخم بلا داعٍ)
  // ثم نجمّعها محليًا حسب المتدرب. مُصرَّحة بأنواع واضحة (List<Attendance>)
  // بدل dynamic/List الخام لتفادي أي خطأ نوع غير متوقع أثناء البناء يُترجم
  // في وضع الإصدار (release) إلى "شاشة رمادية" بلا رسالة خطأ واضحة.
  final results = <String, List<Attendance>>{};
  final since = DateTime.now().subtract(const Duration(days: 90));
  final attRes = await ref
      .read(attendanceRepositoryProvider)
      .getAllAttendance(from: since);
  attRes.fold((l) => null, (all) {
    for (final a in all) {
      if (traineeIds.contains(a.traineeId)) {
        results.putIfAbsent(a.traineeId, () => <Attendance>[]).add(a);
      }
    }
  });

  final usersRes = await ref.read(userRepositoryProvider).getAllUsers();
  final names = <String, String>{};
  usersRes.fold((l) => null, (users) {
    for (final u in users) {
      names[u.id] = u.name;
    }
  });

  return traineeIds
      .map((tid) => TraineeAttendanceData(
            traineeId: tid,
            traineeName: names[tid] ?? tid,
            attendance: results[tid] ?? const <Attendance>[],
          ))
      .toList();
});

class TraineeAttendanceData {
  final String traineeId;
  final String traineeName;
  final List<Attendance> attendance;
  const TraineeAttendanceData(
      {required this.traineeId,
      required this.traineeName,
      required this.attendance});
}

class TraineesAttendanceScreen extends ConsumerWidget {
  const TraineesAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(traineesAttendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('حضور متدربي')),
      body: dataAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل بيانات الحضور...'),
        error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(traineesAttendanceProvider)),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('لا يوجد متدربون مسجلون بعد', style: TextStyle(color: AppColors.textMuted)));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(traineesAttendanceProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final d = list[i];
                final records = d.attendance;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: Text(d.traineeName.isNotEmpty ? d.traineeName[0] : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(d.traineeName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                            child: Text('${records.length} حضور', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ),
                        ],
                      ),
                      if (records.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),
                        ...records.take(5).map((a) {
                          final date = a.checkInTime;
                          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text(timeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                const Spacer(),
                                Text(a.method.name == 'qr' ? 'QR' : 'يدوي', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                        if (records.length > 5)
                          Text('و ${records.length - 5} سجل آخر...', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
