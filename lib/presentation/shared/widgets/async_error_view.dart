import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// عرض موحّد لحالة الخطأ: رسالة واضحة + زر "إعادة المحاولة".
/// يُستخدم مع `AsyncValue.when(error: ...)` في كل الشاشات.
class AsyncErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final String message;

  const AsyncErrorView({super.key, required this.error, required this.onRetry, this.message = 'تعذّر تحميل البيانات'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
