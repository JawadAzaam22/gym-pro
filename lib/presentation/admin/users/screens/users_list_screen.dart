import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../controllers/users_controller.dart';
import '../../../shared/widgets/app_toast.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});
  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(usersControllerProvider);
    final filtered = ref.watch(filteredUsersProvider);
    final roleFilter = ref.watch(userRoleFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الأعضاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(usersControllerProvider.notifier).refresh()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/users/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('عضو جديد', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(userSearchQueryProvider.notifier).state = v,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الهاتف أو البريد...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(userSearchQueryProvider.notifier).state =
                                  '';
                            })
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: ['الكل', 'أدمن', 'استقبال', 'مدرب', 'متدرب']
                          .map((label) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                  label: Text(label,
                                      style: TextStyle(
                                          color: roleFilter == label
                                              ? Colors.white
                                              : AppColors.textMuted,
                                          fontSize: 12)),
                                  selected: roleFilter == label,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.surfaceCard,
                                  side: BorderSide(
                                      color: roleFilter == label
                                          ? AppColors.primary
                                          : AppColors.border),
                                  onSelected: (_) => ref
                                      .read(userRoleFilterProvider.notifier)
                                      .state = label)))
                          .toList()),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const LoadingIndicator(message: 'جاري تحميل الأعضاء...'),
              error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 8),
                Text('خطأ: $e', style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton(
                    onPressed: () =>
                        ref.read(usersControllerProvider.notifier).refresh(),
                    child: const Text('إعادة المحاولة'))
              ])),
              data: (_) {
                if (filtered.isEmpty) {
                  return const EmptyState(
                      message: 'لا يوجد أعضاء يطابقون البحث',
                      icon: Icons.group_off);
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(usersControllerProvider.notifier).refresh(),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceCard,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final u = filtered[i];
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Stack(children: [
                              CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.surfaceLow,
                                  backgroundImage: const AssetImage(
                                      'assets/images/avatar_placeholder.png'),
                                  onBackgroundImageError: (_, __) {},
                                  child: Text(u.name.characters.first,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          shadows: [
                                            Shadow(
                                                color: Colors.black54,
                                                blurRadius: 4)
                                          ]))),
                              if (!u.isActive)
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.surfaceCard,
                                                width: 2)))),
                            ]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(u.name,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: AppColors.surfaceLow,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(u.role.name,
                                              style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 10)))
                                    ]),
                                    const SizedBox(height: 2),
                                    Text('${u.phone} • ${u.email}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis),
                                    Text(
                                        u.gender.name == 'male'
                                            ? 'ذكر'
                                            : 'أنثى',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10)),
                                  ]),
                            ),
                            Column(children: [
                              StatusBadge(
                                  label: u.isActive ? 'نشط' : 'موقوف',
                                  variant: u.isActive
                                      ? BadgeVariant.active
                                      : BadgeVariant.danger),
                              const SizedBox(height: 6),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                _iconBtn(
                                    Icons.edit_outlined,
                                    () => context.push('/admin/users/${u.id}',
                                        extra: u)),
                                const SizedBox(width: 4),
                                _iconBtn(
                                    u.isActive
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    () => _confirmDeactivate(u),
                                    color: u.isActive
                                        ? AppColors.warning
                                        : AppColors.success),
                                const SizedBox(width: 4),
                                _iconBtn(
                                    Icons.delete_forever_outlined,
                                    () => _confirmDelete(u),
                                    color: AppColors.error),
                              ]),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
          {Color color = AppColors.textMuted}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border)),
            child: Icon(icon, size: 14, color: color)),
      );

  void _confirmDeactivate(user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(user.isActive ? 'تعطيل العضو؟' : 'تفعيل العضو؟',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'هل أنت متأكد من ${user.isActive ? 'تعطيل' : 'تفعيل'} ${user.name}؟',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(usersControllerProvider.notifier)
                    .setActive(user.id, !user.isActive);
                if (mounted) {
                  if (ok) {
                    AppToast.success(context, 'تم التحديث');
                  } else {
                    AppToast.error(context, 'فشل');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(user.isActive ? 'تعطيل' : 'تفعيل')),
        ],
      ),
    );
  }

  void _confirmDelete(user) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف نهائي للمستخدم؟',
            style: TextStyle(color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تحذير: هذا الإجراء لا رجعة فيه. سيُحذف المستخدم وجميع بياناته نهائيًا.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'اكتب اسم المستخدم بالضبط للتأكيد:',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'اسم المستخدم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.error, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim() != user.name) {
                  AppToast.error(context, 'اسم المستخدم غير مطابق — الإلغاء');
                  return;
                }
                Navigator.pop(ctx);
                // أولاً: محاولة حذف آمنة. إن وُجدت سجلات مرتبطة (عضويات/
                // حضور/مدفوعات/برامج...) نعرض خيار الحذف الشامل (cascade)
                // بدل رسالة فشل نهائية بلا حل.
                final notifier = ref.read(usersControllerProvider.notifier);
                final ok = await notifier.deleteUser(user.id, cascade: false);
                if (!mounted) return;
                if (ok) {
                  AppToast.success(context, 'تم الحذف نهائيًا');
                  return;
                }
                final errorMsg =
                    ref.read(usersControllerProvider).error?.toString() ?? '';
                if (errorMsg.contains('سجلات مرتبطة') ||
                    errorMsg.contains('HAS_RELATED_RECORDS')) {
                  _confirmCascadeDelete(user);
                } else {
                  AppToast.error(context, 'فشل الحذف: $errorMsg');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف نهائي')),
        ],
      ),
    );
  }

  /// خيار "الحذف الشامل": يُعرض فقط بعد فشل الحذف الآمن بسبب سجلات مرتبطة.
  /// يُؤرشف كل شيء يخص المستخدم في deleted_users_archive قبل حذف سجلاته
  /// الشخصية، وتبقى سجلات الآخرين (تقارير، مدفوعاتهم، حصصهم) سليمة تمامًا —
  /// فقط تفقد اسم "من سجّلها" إن كان هو من سجّلها.
  void _confirmCascadeDelete(user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('حذف شامل — لا رجعة فيه',
            style: TextStyle(color: AppColors.error)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لهذا المستخدم سجلات مرتبطة (عضويات/حضور/مدفوعات/برامج/جلسات خاصة). لا يمكن حذفه حذفًا آمنًا.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              'يمكنك حذفه حذفًا شاملاً: تُحفظ نسخة كاملة من كل بياناته في أرشيف دائم (deleted_users_archive) للرجوع إليها لاحقًا، ثم تُحذف سجلاته الشخصية نهائيًا. تقارير ومدفوعات وحصص الأشخاص الآخرين المرتبطين به (كمدرّب سجّل دفعة مثلاً) تبقى سليمة ولا تُحذف.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(usersControllerProvider.notifier)
                    .deleteUser(user.id, cascade: true);
                if (!mounted) return;
                final errorMsg =
                    ref.read(usersControllerProvider).error?.toString() ?? '';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'تم الحذف الشامل وحُفظت نسخة في الأرشيف'
                        : 'فشل الحذف الشامل: $errorMsg'),
                    backgroundColor: ok ? AppColors.success : AppColors.error));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف شامل نهائي')),
        ],
      ),
    );
  }
}
