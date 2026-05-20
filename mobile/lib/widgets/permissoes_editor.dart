import 'package:flutter/material.dart';

import '../models/permissao.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class PermissoesEditor extends StatelessWidget {
  const PermissoesEditor({
    super.key,
    required this.linhas,
    required this.onChanged,
    this.readOnly = false,
    this.adminTotal = false,
  });

  final List<PermissaoLinha> linhas;
  final void Function(int index, PermissaoLinha linha) onChanged;
  final bool readOnly;
  final bool adminTotal;

  @override
  Widget build(BuildContext context) {
    if (adminTotal) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Este perfil possui permissão total em todos os programas.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.primaryBlue,
              ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: linhas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final linha = linhas[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                linha.programaNome,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontFamily: AppTheme.fontFamily,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: [
                  _FlagSwitch(
                    label: 'Consultar',
                    value: linha.podeConsultar,
                    onChanged: readOnly
                        ? null
                        : (v) => onChanged(
                              index,
                              linha.copyWith(podeConsultar: v),
                            ),
                  ),
                  _FlagSwitch(
                    label: 'Incluir',
                    value: linha.podeIncluir,
                    onChanged: readOnly
                        ? null
                        : (v) => onChanged(
                              index,
                              linha.copyWith(podeIncluir: v),
                            ),
                  ),
                  _FlagSwitch(
                    label: 'Alterar',
                    value: linha.podeAlterar,
                    onChanged: readOnly
                        ? null
                        : (v) => onChanged(
                              index,
                              linha.copyWith(podeAlterar: v),
                            ),
                  ),
                  _FlagSwitch(
                    label: 'Excluir',
                    value: linha.podeExcluir,
                    onChanged: readOnly
                        ? null
                        : (v) => onChanged(
                              index,
                              linha.copyWith(podeExcluir: v),
                            ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlagSwitch extends StatelessWidget {
  const _FlagSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 12),
      ),
      selected: value,
      onSelected: onChanged,
    );
  }
}
