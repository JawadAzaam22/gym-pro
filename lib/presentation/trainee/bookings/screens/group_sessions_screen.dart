import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../controllers/group_sessions_controller.dart';

/// شاشة عرض الحصص الجماعية للمتدرب.
///
/// كانت تعرض فقط اسم الحصة وتاريخ بداية/نهاية التسجيل — بلا اسم مدرب ولا
/// قاعة ولا أي معلومة عن اليوم/الوقت الفعلي الذي تنعقد فيه الحصة أسبوعيًا،
/// فكانت عمليًا عديمة الفائدة (متدرب لا يعرف متى يحضر). الآن تعرض كل هذه
/// المعلومات عبر groupSessionsDisplayProvider الذي يربط الحصة بالمدرب
/// والقاعة وفترات session_periods/access_periods الفعلية. كما تستثني
/// الحصص الملغاة تلقائيًا.
class GroupSessionsScreen extends ConsumerWidget {
  const GroupSessionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(groupSessionsDisplayProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الحصص الجماعية')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.info),
            SizedBox(width: 8),
            Expanded(
                child: Text('عرض فقط للكورسات المتاحة — الحجز والإلغاء يتمّان عبر موظف الاستقبال',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
          ]),
        ),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const LoadingIndicator(message: 'جاري تحميل الحصص...'),
            error: (e, _) => AsyncErrorView(
                error: e,
                onRetry: () => ref.invalidate(groupSessionsDisplayProvider)),
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                    child: Text('لا توجد حصص جماعية متاحة حاليًا',
                        style: TextStyle(color: AppColors.textMuted)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = list[i];
                  final s = item.session;
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
                                      fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('سعة ${s.capacity}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          if ((s.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(s.description!,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                          const Divider(height: 18, color: AppColors.border),
                          _infoRow(Icons.fitness_center, item.trainerName),
                          const SizedBox(height: 4),
                          _infoRow(Icons.meeting_room, item.hallName),
                          const SizedBox(height: 4),
                          _infoRow(Icons.schedule, item.scheduleText),
                        ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(width: 6),
      Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12))),
    ]);
  }
}
