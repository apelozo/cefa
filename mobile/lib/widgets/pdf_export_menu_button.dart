import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Menu padrão do Cefa: visualizar ou baixar/compartilhar PDF.
class PdfExportMenuButton extends StatelessWidget {
  const PdfExportMenuButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onVisualizar,
    required this.onExportar,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onVisualizar;
  final VoidCallback onExportar;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'PDF',
      enabled: !loading,
      icon: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      onSelected: (value) {
        if (value == 'visualizar') {
          onVisualizar();
        } else if (value == 'exportar') {
          onExportar();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'visualizar',
          child: Text(
            'Visualizar PDF',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
        PopupMenuItem(
          value: 'exportar',
          child: Text(
            'Baixar / compartilhar PDF',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      ],
    );
  }
}
