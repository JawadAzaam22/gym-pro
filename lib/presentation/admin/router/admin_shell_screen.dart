import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/adaptive_nav_scaffold.dart';
import '../../shared/widgets/notification_bell.dart';
import '../controllers/admin_nav_controller.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  static final _drawerKey = GlobalKey<ScaffoldState>();

  AdminSection _resolveSection(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    return adminSectionFromLocation(currentLocation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final section = _resolveSection(context);
    final current = ref.read(adminNavProvider);
    if (current != section) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(adminNavProvider.notifier).state = section;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = _resolveSection(context);
    final selectedIndex = AdminSection.values.indexOf(currentSection);
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final items = AdminSection.values
        .map((section) => NavItem(
              icon: _iconForSection(section),
              label: isWide ? section.label : section.shortLabel,
              selected: currentSection == section,
              onTap: () {
                navigateToAdminSection(
                    context, widget.navigationShell, section);
              },
            ))
        .toList();

    final footerItems = [
      NavItem(
        icon: Icons.logout,
        label: 'خروج',
        iconColor: AppColors.error,
        onTap: () async {
          try {
            await Supabase.instance.client.auth.signOut();
          } catch (_) {}
          if (context.mounted) context.go('/');
        },
      ),
    ];

    final drawerHeader = Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.fitness_center, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Athletic Pulse',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'الإدارة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );

    final appBar = AppBar(
      leading: isWide
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _drawerKey.currentState?.openDrawer(),
            ),
      title: Text(currentSection.label),
      actions: const [
        NotificationBell(route: '/admin/notifications'),
        Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text('A',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        SizedBox(width: 12),
      ],
    );

    return AdaptiveNavScaffold(
      appBar: appBar,
      body: widget.navigationShell,
      items: items,
      header: drawerHeader,
      footerItems: footerItems,
      backgroundColor: AppColors.background,
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      drawerKey: _drawerKey,
    );
  }

  static IconData _iconForSection(AdminSection section) {
    switch (section) {
      case AdminSection.dashboard:
        return Icons.dashboard;
      case AdminSection.users:
        return Icons.group;
      case AdminSection.halls:
        return Icons.meeting_room;
      case AdminSection.sessions:
        return Icons.class_;
      case AdminSection.finance:
        return Icons.assessment;
      case AdminSection.schedule:
        return Icons.calendar_month;
    }
  }
}
