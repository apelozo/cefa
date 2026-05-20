import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

abstract final class AppAssets {
  static const String icAlterar = 'assets/images/ic_alterar.svg';
  static const String icExcluir = 'assets/images/ic_excluir.svg';
}

class RecordActionButtons extends StatelessWidget {
  const RecordActionButtons({
    super.key,
    this.onEdit,
    this.onDelete,
    this.editTooltip = 'Alterar',
    this.deleteTooltip = 'Excluir',
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editTooltip;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          _ActionImageButton(
            assetPath: AppAssets.icAlterar,
            tooltip: editTooltip,
            backgroundColor: AppColors.lightBlue,
            onPressed: onEdit!,
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 8),
        if (onDelete != null) ...[
          _ActionImageButton(
            assetPath: AppAssets.icExcluir,
            tooltip: deleteTooltip,
            backgroundColor: Colors.red.shade50,
            onPressed: onDelete!,
          ),
        ],
      ],
    );
  }
}

class _ActionImageButton extends StatelessWidget {
  const _ActionImageButton({
    required this.assetPath,
    required this.tooltip,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String assetPath;
  final String tooltip;
  final Color backgroundColor;
  final VoidCallback onPressed;

  static const double _size = 48;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Center(
              child: SvgPicture.asset(
                assetPath,
                width: _iconSize,
                height: _iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
