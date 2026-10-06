import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

void showReceptionDrawer(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  void close() {
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _ReceptionDrawerOverlay(onClose: close, outerContext: context),
  );

  overlay.insert(entry);
}

class _ReceptionDrawerOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final BuildContext outerContext;

  const _ReceptionDrawerOverlay({required this.onClose, required this.outerContext});

  @override
  State<_ReceptionDrawerOverlay> createState() => _ReceptionDrawerOverlayState();
}

class _ReceptionDrawerOverlayState extends State<_ReceptionDrawerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
    );
    _controller.forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outerContext = widget.outerContext;
    final shortest = MediaQuery.of(outerContext).size.shortestSide;
    final drawerWidth = shortest > 600 ? 304.0 : 260.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black54.withOpacity(_fadeAnim.value)),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: AppColors.surface,
                    elevation: 16,
                    child: SizedBox(
                      width: drawerWidth,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          DrawerHeader(
                            decoration: const BoxDecoration(color: AppColors.surfaceLow),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.fitness_center, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                Text('Athletic Pulse', style: Theme.of(context).textTheme.titleMedium),
                                Text('الاستقبال', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.dashboard, color: AppColors.primary),
                            title: const Text('لوحة التحكم'),
                            selected: true,
                            onTap: _close,
                          ),
                          ListTile(
                            leading: const Icon(Icons.how_to_reg),
                            title: const Text('تسجيل الحضور'),
                            onTap: () { _close(); context.push('/reception/checkin'); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.qr_code_scanner),
                            title: const Text('مسح QR'),
                            onTap: () { _close(); context.push('/reception/checkin/qr'); },
                          ),
                          const Divider(color: AppColors.border),
                          ListTile(
                            leading: const Icon(Icons.card_membership),
                            title: const Text('اشتراك جديد'),
                            onTap: () { _close(); context.push('/reception/memberships/new'); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.refresh),
                            title: const Text('تجديد اشتراك'),
                            onTap: () { _close(); context.push('/reception/memberships/renew'); },
                          ),
                          ListTile(
                            leading: const Icon(Icons.person_add),
                            title: const Text('تعيين مدرب'),
                            onTap: () { _close(); context.push('/reception/trainer-assignment'); },
                          ),
                          const Divider(color: AppColors.border),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.error),
                            title: const Text('خروج', style: TextStyle(color: AppColors.error)),
                            onTap: () { _close(); context.go('/'); },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
