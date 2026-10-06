import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum BadgeVariant { active, expiring, frozen, danger, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool withDot;

  const StatusBadge({super.key, required this.label, this.variant = BadgeVariant.active, this.withDot = true});

  Color get _color {
    switch (variant) {
      case BadgeVariant.active:
        return AppColors.success;
      case BadgeVariant.expiring:
        return AppColors.warning;
      case BadgeVariant.frozen:
        return AppColors.textMuted;
      case BadgeVariant.danger:
        return AppColors.error;
      case BadgeVariant.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: c.withOpacity(0.25))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
