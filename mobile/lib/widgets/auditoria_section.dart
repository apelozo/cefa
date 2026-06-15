import 'package:flutter/material.dart';

import '../models/auditoria_campos.dart';
import '../theme/app_theme.dart';
import '../utils/auditoria_display.dart';
import '../utils/datetime_display.dart';

/// Bloco padrão de auditoria (inclusão, alteração e exclusão lógica).
class AuditoriaSection extends StatelessWidget {
  const AuditoriaSection({
    super.key,
    required this.auditoria,
    this.mostrarExclusao = false,
    this.paddingBottom = 16,
  });

  final AuditoriaCampos auditoria;
  final bool mostrarExclusao;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    if (!auditoria.temAlgumRegistro) {
      return SizedBox(height: paddingBottom);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Auditoria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: AppTheme.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          if (auditoria.dataHoraInclusao != null)
            _linha(
              'Inclusão',
              formatAuditoriaEvento(
                dataHora: formatDateTimeBr(auditoria.dataHoraInclusao),
                nomeUsuario: auditoria.usuarioInclusaoNomeUsuario,
                nome: auditoria.usuarioInclusaoNome,
              ),
            ),
          if (auditoria.dataHoraAlteracao != null)
            _linha(
              'Última alteração',
              formatAuditoriaEvento(
                dataHora: formatDateTimeBr(auditoria.dataHoraAlteracao),
                nomeUsuario: auditoria.usuarioAlteracaoNomeUsuario,
                nome: auditoria.usuarioAlteracaoNome,
              ),
            ),
          if (mostrarExclusao && auditoria.dataHoraExclusao != null)
            _linha(
              'Desativação (soft delete)',
              formatAuditoriaEvento(
                dataHora: formatDateTimeBr(auditoria.dataHoraExclusao),
                nomeUsuario: auditoria.usuarioExclusaoNomeUsuario,
                nome: auditoria.usuarioExclusaoNome,
              ),
            ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$rotulo: $valor',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
