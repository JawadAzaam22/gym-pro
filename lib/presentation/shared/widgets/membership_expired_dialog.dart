import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// حوار تحذيري للاستقبال عند محاولة تسجيل حضور لعضوية منتهية (SRS 5.2):
/// "العضوية منتهية — تاريخ الانتهاء: X — لا يمكن تسجيل الدخول".
Future<void> showMembershipExpiredDialog(BuildContext context, {DateTime? endDate, String? traineeLabel}) {
  final endStr = endDate?.toIso8601String().split('T').first ?? 'غير معروف';
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 8),
          Text('العضوية منتهية', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (traineeLabel != null) ...[
            Text(traineeLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
          ],
          Text('تاريخ الانتهاء: $endStr', style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('لا يمكن تسجيل الدخول — وجّه العضو لتجديد الاشتراك أولاً.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('فهمت', style: TextStyle(color: AppColors.primary))),
      ],
    ),
  );
}
