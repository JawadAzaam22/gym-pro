import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Row(children: [Text(actionLabel!, style: const TextStyle(color: AppColors.primary)), const SizedBox(width: 4), const Icon(Icons.arrow_back, size: 14, color: AppColors.primary)])),
      ],
    );
  }
}
