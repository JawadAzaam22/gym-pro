import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/adaptive_nav_scaffold.dart';
import '../../shared/widgets/notification_bell.dart';
import '../controllers/reception_nav_controller.dart';

class ReceptionShellScreen extends ConsumerStatefulWidget {
  const ReceptionShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ReceptionShellScreen> createState() =>
      _ReceptionShellScreenState();
}

class _ReceptionShellScreenState extends ConsumerState<ReceptionShellScreen> {
  static final _drawerKey = GlobalKey<ScaffoldState>();

  ReceptionSection _resolveSection(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    return sectionFromLocation(currentLocation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final section = _resolveSection(context);
    final current = ref.read(receptionNavProvider);
    if (current != section) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(receptionNavProvider.notifier).state = section;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = _resolveSection(context);
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final visibleSections = ReceptionSection.values
        .where((s) => s != ReceptionSection.qrScan)
        .toList();
    final selectedIndex = visibleSections.indexOf(currentSection);

    final items = visibleSections
        .map((section) => NavItem(
              icon: _iconForSection(section),
              label: isWide ? section.label : section.shortLabel,
              selected: currentSection == section,
              onTap: () {
                final branchBySection = <ReceptionSection, int>{
                  ReceptionSection.dashboard: 0,
                  ReceptionSection.checkin: 1,
                  ReceptionSection.memberships: 2,
                  ReceptionSection.bookings: 3,
                  ReceptionSection.privateBookings: 4,
                  ReceptionSection.assignment: 5,
                  ReceptionSection.payments: 6,
                  ReceptionSection.schedule: 7,
                  ReceptionSection.newTrainee: 8,
                };
                final pathBySection = <ReceptionSection, String>{
                  ReceptionSection.dashboard: '/reception/dashboard',
                  ReceptionSection.checkin: '/reception/checkin',
                  ReceptionSection.memberships: '/reception/memberships',
                  ReceptionSection.bookings: '/reception/bookings/group',
                  ReceptionSection.privateBookings:
                      '/reception/bookings/private',
                  ReceptionSection.assignment: '/reception/trainer-assignment',
                  ReceptionSection.payments: '/reception/payments/record',
                  ReceptionSection.schedule: '/reception/schedule',
                  ReceptionSection.newTrainee: '/reception/trainees/new',
                };
                final idx = branchBySection[section];
                final path = pathBySection[section];
                if (idx == null || path == null) return;
                widget.navigationShell.goBranch(
                  idx,
                  initialLocation: widget.navigationShell.currentIndex == idx,
                );
                context.go(path);
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
            'الاستقبال',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );

    final isQrRoute = currentSection == ReceptionSection.qrScan;

    final appBar = isQrRoute
        ? null
        : AppBar(
            leading: isWide
                ? null
                : IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _drawerKey.currentState?.openDrawer(),
                  ),
            title: Text(currentSection.label),
            actions: const [
              NotificationBell(route: '/reception/notifications'),
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text('R',
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

  static IconData _iconForSection(ReceptionSection section) {
    switch (section) {
      case ReceptionSection.dashboard:
        return Icons.dashboard;
      case ReceptionSection.checkin:
        return Icons.how_to_reg;
      case ReceptionSection.qrScan:
        return Icons.qr_code_scanner;
      case ReceptionSection.memberships:
        return Icons.card_membership;
      case ReceptionSection.bookings:
        return Icons.event;
      case ReceptionSection.privateBookings:
        return Icons.person_outline;
      case ReceptionSection.assignment:
        return Icons.person_add;
      case ReceptionSection.payments:
        return Icons.payments;
      case ReceptionSection.schedule:
        return Icons.calendar_month;
      case ReceptionSection.newTrainee:
        return Icons.group_add;
    }
  }
}
