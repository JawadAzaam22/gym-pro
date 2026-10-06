import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: AppColors.primary), if (message != null) ...[const SizedBox(height: 12), Text(message!, style: const TextStyle(color: AppColors.textMuted))]]));
}
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: AppColors.textMuted), const SizedBox(height: 12), Text(message, style: const TextStyle(color: AppColors.textMuted))])); 
}
