import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta; // e.g. "+14% هذا الشهر"
  final IconData icon;
  final Color? deltaColor;

  const StatCard({super.key, required this.label, required this.value, this.delta, required this.icon, this.deltaColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTheme.statCounter),
          if (delta != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: (deltaColor ?? AppColors.success).withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: (deltaColor ?? AppColors.success).withOpacity(0.25))),
              child: Text(delta!, style: TextStyle(color: deltaColor ?? AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}
