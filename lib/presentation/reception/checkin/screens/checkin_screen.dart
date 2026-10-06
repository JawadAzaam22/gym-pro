import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/membership_expired_dialog.dart';
import '../../../../core/errors/failures.dart';
import '../controllers/checkin_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});
  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _search = TextEditingController();
  String? _selectedManualTraineeId;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traineesAsync = ref.watch(filteredReceptionTraineesProvider);
    final checkinAsync = ref.watch(checkinControllerProvider);
    final allTraineesAsync = ref.watch(receptionTraineesProvider);

    final allTrainees = allTraineesAsync.whenOrNull(
          data: (list) => list,
        ) ??
        [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      label: 'بحث سريع',
                      hint: 'اسم أو هاتف المتدرب',
                      controller: _search,
                      prefixIcon: Icons.search,
                      onChanged: (v) {
                        _searchDebounce?.cancel();
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 250), () {
                          ref
                              .read(receptionSearchQueryProvider.notifier)
                              .state = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'مسح QR',
                    icon: Icons.qr_code,
                    expanded: false,
                    showArrow: false,
                    onPressed: () => context.push('/reception/checkin/qr'),
                  ),
                ]),
                const SizedBox(height: 12),
                // حقل "session id" (رقم الحصة الخام) كان يطلب من موظف
                // الاستقبال إدخال معرّف داخلي من قاعدة البيانات يدويًا —
                // غير عملي وغير مفهوم. التسجيل اليدوي لا يحتاج ربطًا بحصة
                // محددة أصلاً (هو فقط تسجيل حضور عام لليوم)، فحُذف الحقل.
                allTraineesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('خطأ في التحميل',
                      style: TextStyle(color: AppColors.error)),
                  data: (_) => DropdownButtonFormField<String>(
                    value: _selectedManualTraineeId,
                    decoration: const InputDecoration(
                      labelText: 'تسجيل يدوي — اختر المتدرب',
                      prefixIcon: Icon(Icons.person),
                    ),
                    isExpanded: true,
                    items: allTrainees
                        .where((u) => u.isActive)
                        .map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} • ${u.phone}'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedManualTraineeId = v),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'تسجيل يدوي',
                    icon: Icons.how_to_reg,
                    showArrow: false,
                    onPressed: () async {
                      final id = _selectedManualTraineeId;
                      if (id == null || id.isEmpty) {
                        AppToast.error(context, 'اختر المتدرب أولاً');
                        return;
                      }
                      final res = await ref
                          .read(checkinControllerProvider.notifier)
                          .checkin(id, 'manual');
                      if (!mounted) return;
                      final traineeName = allTrainees
                              .where((u) => u.id == id)
                              .map((u) => u.name)
                              .firstOrNull ??
                          'المتدرب';
                      res.fold(
                        (f) {
                          if (f is MembershipExpiredFailure) {
                            showMembershipExpiredDialog(context,
                                endDate: f.endDate, traineeLabel: traineeName);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('فشل التسجيل: ${f.message}'),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        },
                        (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('تم تسجيل حضور $traineeName'),
                                backgroundColor: AppColors.success),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('المتدربين', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            checkinAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => StatusBadge(
                  label: '${list.length} حاضر اليوم',
                  variant: BadgeVariant.info),
            ),
          ]),
          const SizedBox(height: 12),
          traineesAsync.when(
            loading: () => const LoadingIndicator(
                message: 'جاري تحميل قائمة المتدربين...'),
            error: (e, _) => AsyncErrorView(
              error: e,
              onRetry: () => ref.invalidate(receptionTraineesProvider),
            ),
            data: (trainees) {
              if (trainees.isEmpty) {
                return const Center(
                  child: Text('لا يوجد متدربين',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trainees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final u = trainees[i];
                  return AppCard(
                    key: ValueKey(u.id),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceLow,
                          child: Text(
                            u.name.isNotEmpty ? u.name.characters.first : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4)
                                ]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: AppColors.surfaceLow,
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text(u.role.name,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                Text(u.phone,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: u.isActive ? 'نشط' : 'موقوف',
                          variant: u.isActive
                              ? BadgeVariant.active
                              : BadgeVariant.danger,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: u.isActive
                              ? () async {
                                  final res = await ref
                                      .read(checkinControllerProvider.notifier)
                                      .checkin(u.id, 'manual');
                                  if (!mounted) return;
                                  res.fold(
                                    (f) {
                                      if (f is MembershipExpiredFailure) {
                                        showMembershipExpiredDialog(context,
                                            endDate: f.endDate,
                                            traineeLabel: u.name);
                                      } else {
                                        AppToast.error(
                                            context, 'فشل: ${f.message}');
                                      }
                                    },
                                    (_) => AppToast.success(
                                        context, 'تم تسجيل ${u.name}'),
                                  );
                                }
                              : null,
                          icon:
                              const Icon(Icons.check, color: AppColors.success),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppColors.success.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
