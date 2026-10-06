import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../shared/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _sessionRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isTrainer = widget.role == 'trainer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'المستخدم',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(isTrainer ? 'مدرب' : 'متدرب',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('الوصول السريع'),
          AppCard(
            child: Column(
              children: isTrainer
                  ? [
                      _linkTile(context, Icons.group, 'المتدربون',
                          '/trainer/trainees'),
                      _linkTile(context, Icons.how_to_reg, 'سجل الحضور',
                          '/trainer/attendance'),
                    ]
                  : [
                      _linkTile(context, Icons.card_membership, 'عضويتي',
                          '/trainee/membership'),
                      _linkTile(context, Icons.fitness_center, 'برنامجي',
                          '/trainee/program'),
                      _linkTile(context, Icons.restaurant, 'خطتي الغذائية',
                          '/trainee/diet'),
                      _linkTile(
                          context, Icons.person, 'مدربي', '/trainee/trainer'),
                    ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('التنبيهات'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('التنبيهات العامة'),
                  subtitle: const Text('إشعارات النظام والتحديثات',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تذكير الجلسات'),
                  subtitle: const Text('تنبيه قبل موعد الجلسة',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  value: _sessionRemindersEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) =>
                          setState(() => _sessionRemindersEnabled = value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('الحساب'),
          AppCard(
            child: Column(
              children: [
                _actionTile(Icons.language, 'اللغة', 'العربية'),
                _actionTile(Icons.info_outline, 'عن التطبيق', 'Gym Pro'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      );

  Widget _linkTile(
          BuildContext context, IconData icon, String title, String path) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left, color: AppColors.textMuted),
        onTap: () => context.push(path),
      );

  Widget _actionTile(IconData icon, String title, String value) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.textMuted),
        title: Text(title),
        trailing: Text(value,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      );

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go('/');
  }
}
