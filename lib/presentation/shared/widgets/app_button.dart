import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final bool showArrow;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = true,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
              if (variant == AppButtonVariant.primary && showArrow) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_back, size: 16),
              ],
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        final elevated = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: AppColors.primaryGlow,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(AppColors.primaryHover),
          ),
          child: child,
        );
        // Glow Container – expand ElevatedButton when expanded
        button = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: onPressed == null
                ? null
                : [
                    const BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: expanded
              ? SizedBox(width: double.infinity, child: elevated)
              : elevated,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
        break;
    }

    if (expanded && variant != AppButtonVariant.primary) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
