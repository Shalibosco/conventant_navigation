// lib/presentation/widgets/custom_button.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ButtonVariant { primary, secondary, outline, ghost, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Marked as 'final' to satisfy linter warnings
    final Widget child = isLoading
        ? SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: _getForegroundColor(),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: _getForegroundColor()),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: _getForegroundColor(),
          ),
        ),
      ],
    );

    // ✅ Marked as 'final' to satisfy linter warnings
    final Widget button = switch (variant) {
      ButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cuNavy, // ✅ Mapped to cuNavy
          foregroundColor: Colors.white,
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
      ButtonVariant.secondary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cuGold, // ✅ Mapped to cuGold
          foregroundColor: Colors.white,
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
      ButtonVariant.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.cuNavy, // ✅ Mapped to cuNavy
          side: const BorderSide(color: AppTheme.cuNavy, width: 1.5), // ✅ Swapped Const Issue
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
      ButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.cuNavy, // ✅ Mapped to cuNavy
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
      ButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorRed, // ✅ Mapped to errorRed or standard Colors.red
          foregroundColor: Colors.white,
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _getForegroundColor() {
    return switch (variant) {
      ButtonVariant.primary || ButtonVariant.secondary ||
      ButtonVariant.danger => Colors.white,
      ButtonVariant.outline || ButtonVariant.ghost => AppTheme.cuNavy, // ✅ Mapped to cuNavy
    };
  }
}