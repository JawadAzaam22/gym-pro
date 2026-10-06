import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../domain/entities/hall.dart';
import '../controllers/halls_controller.dart';

class HallsListScreen extends ConsumerStatefulWidget {
  const HallsListScreen({super.key});
  @override
  ConsumerState<HallsListScreen> createState() => _HallsListScreenState();
}

class _HallsListScreenState extends ConsumerState<HallsListScreen> {
  @override
  Widget build(BuildContext context) {
    final hallsAsync = ref.watch(hallsControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('القاعات وفترات الوصول'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(hallsControllerProvider))
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showHallDialog(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label:
              const Text('قاعة جديدة', style: TextStyle(color: Colors.white))),
      body: hallsAsync.when(
        loading: () => const LoadingIndicator(message: 'جاري تحميل القاعات...'),
        error: (e, _) => AsyncErrorView(
            error: e, onRetry: () => ref.invalidate(hallsControllerProvider)),
        data: (halls) {
          if (halls.isEmpty) {
            return const Center(
                child: Text('لا توجد قاعات بعد',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(hallsControllerProvider),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: halls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final h = halls[i];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/hall_a.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.meeting_room,
                                        color: AppColors.primary)))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(h.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text('السعة: ${h.capacity}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 11)),
                              Text(
                                  'الدوام: ${h.openTime.substring(0, 5)}–${h.closeTime.substring(0, 5)} • فترة ${h.defaultSlotMinutes} د',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 11)),
                            ])),
                        StatusBadge(
                            label: h.isActive ? 'نشطة' : 'موقوفة',
                            variant: h.isActive
                                ? BadgeVariant.active
                                : BadgeVariant.danger),
                      ]),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                    '/admin/halls/${h.id}/periods',
                                    extra: h),
                                icon: const Icon(Icons.schedule, size: 14),
                                label: const Text('الفترات',
                                    style: TextStyle(fontSize: 12)))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: () => _showHallDialog(hall: h),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('تعديل',
                                    style: TextStyle(fontSize: 12)))),
                        const SizedBox(width: 8),
                        IconButton(
                            onPressed: () => _confirmDeactivate(h),
                            icon: Icon(
                                h.isActive ? Icons.block : Icons.check_circle,
                                size: 18,
                                color: h.isActive
                                    ? AppColors.warning
                                    : AppColors.success),
                            style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceLow,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)))),
                      ]),
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

  void _showHallDialog({Hall? hall}) {
    final nameCtrl = TextEditingController(text: hall?.name ?? '');
    final capCtrl =
        TextEditingController(text: hall?.capacity.toString() ?? '');
    final openCtrl =
        TextEditingController(text: hall?.openTime.substring(0, 5) ?? '08:00');
    final closeCtrl =
        TextEditingController(text: hall?.closeTime.substring(0, 5) ?? '22:00');
    int slotMinutes = 60;
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text(hall == null ? 'قاعة جديدة' : 'تعديل قاعة',
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppTextField(
                    label: 'اسم القاعة',
                    controller: nameCtrl,
                    prefixIcon: Icons.meeting_room_outlined,
                    validator: (v) => Validators.required(v, 'الاسم')),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'السعة',
                    controller: capCtrl,
                    prefixIcon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                    validator: Validators.capacity),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      label: 'وقت الفتح',
                      controller: openCtrl,
                      prefixIcon: Icons.access_time,
                      hint: '08:00',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTextField(
                      label: 'وقت الإغلاق',
                      controller: closeCtrl,
                      prefixIcon: Icons.access_time_filled,
                      hint: '22:00',
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: 60,
                  decoration: const InputDecoration(
                      labelText: 'مدة الفراغ (دقيقة)',
                      prefixIcon: Icon(Icons.timelapse)),
                  items: const [
                    DropdownMenuItem(value: 60, child: Text('ساعة واحدة')),
                  ],
                  onChanged: null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(ctx)),
                child: const Text('إلغاء',
                    style: TextStyle(color: AppColors.textMuted))),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => loading = true);
                      final newHall = Hall(
                          id: hall?.id ?? 0,
                          name: nameCtrl.text.trim(),
                          capacity: int.parse(capCtrl.text),
                          isActive: hall?.isActive ?? true,
                          openTime: '${openCtrl.text.trim()}:00',
                          closeTime: '${closeCtrl.text.trim()}:00',
                          defaultSlotMinutes: slotMinutes);
                      bool ok;
                      if (hall == null) {
                        ok = await ref
                            .read(hallsControllerProvider.notifier)
                            .createHall(newHall);
                      } else {
                        ok = await ref
                            .read(hallsControllerProvider.notifier)
                            .updateHall(newHall);
                      }
                      setD(() => loading = false);
                      if (ctx.mounted) WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(ctx));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok ? 'تم الحفظ' : 'فشل'),
                            backgroundColor:
                                ok ? AppColors.success : AppColors.error));
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(hall == null ? 'إنشاء' : 'حفظ'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDeactivate(Hall h) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceCard,
                title: Text(h.isActive ? 'تعطيل القاعة؟' : 'تفعيل القاعة؟',
                    style: const TextStyle(color: AppColors.textPrimary)),
                content: Text(
                    'هل أنت متأكد من ${h.isActive ? 'تعطيل' : 'تفعيل'} ${h.name}؟',
                    style: const TextStyle(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(ctx)),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(ctx));
                        final ok = await ref
                            .read(hallsControllerProvider.notifier)
                            .toggleStatus(h);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok ? 'تم التحديث' : 'فشل'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error));
                        }
                      },
                      child: Text(h.isActive ? 'تعطيل' : 'تفعيل'))
                ]));
  }
}
