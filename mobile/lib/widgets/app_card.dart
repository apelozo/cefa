import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_layout.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );

    final content = Padding(padding: padding, child: child);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                child: content,
              )
            : content,
      ),
    );
  }
}
