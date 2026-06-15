import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_layout.dart';

enum AppButtonType { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.loading = false,
    this.icon,
    this.focusNode,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool loading;
  final IconData? icon;
  final FocusNode? focusNode;
  /// Quando `false`, o botão não força largura infinita (uso em [Row]).
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final child = loading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    Widget wrapButton(Widget button) {
      final sized = SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 56,
        child: button,
      );
      if (fullWidth) return sized;
      return IntrinsicWidth(child: sized);
    }

    switch (type) {
      case AppButtonType.primary:
        return wrapButton(ElevatedButton(
            focusNode: focusNode,
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange.withValues(
                alpha: disabled ? 0.45 : 1,
              ),
              disabledBackgroundColor:
                  AppColors.accentOrange.withValues(alpha: 0.45),
            ),
            child: child,
          ));
      case AppButtonType.secondary:
        return wrapButton(OutlinedButton(
          focusNode: focusNode,
          onPressed: disabled ? null : onPressed,
          child: child,
        ));
      case AppButtonType.danger:
        return wrapButton(ElevatedButton(
          focusNode: focusNode,
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withValues(
              alpha: disabled ? 0.45 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.buttonRadius),
            ),
          ),
          child: child,
        ));
    }
  }
}
