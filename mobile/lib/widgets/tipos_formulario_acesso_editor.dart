import 'package:flutter/material.dart';

import '../models/tipos_formulario_acesso.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class TiposFormularioAcessoEditor extends StatelessWidget {
  const TiposFormularioAcessoEditor({
    super.key,
    required this.tipos,
    required this.onChanged,
    this.readOnly = false,
    this.acessoTotal = false,
    this.usaOverride,
  });

  final List<TipoFormularioAcessoLinha> tipos;
  final void Function(int index, TipoFormularioAcessoLinha linha) onChanged;
  final bool readOnly;
  final bool acessoTotal;
  final bool? usaOverride;

  @override
  Widget build(BuildContext context) {
    if (acessoTotal) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Este perfil possui acesso a todos os tipos de formulário.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.primaryBlue,
              ),
        ),
      );
    }

    if (tipos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum tipo de formulário cadastrado.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.fontFamily,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usaOverride == true) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Lista específica deste usuário (substitui a do tipo de usuário).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.primaryBlue,
                  ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tipos.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tipo = tipos[index];
            return CheckboxListTile(
              value: tipo.liberado,
              onChanged: readOnly
                  ? null
                  : (v) => onChanged(
                        index,
                        tipo.copyWith(liberado: v ?? false),
                      ),
              title: Text(
                tipo.nome,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontFamily: AppTheme.fontFamily,
                    ),
              ),
              subtitle: tipo.descricao != null && tipo.descricao!.isNotEmpty
                  ? Text(
                      tipo.descricao!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: AppTheme.fontFamily,
                          ),
                    )
                  : (!tipo.ativo
                      ? Text(
                          'Inativo',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontFamily: AppTheme.fontFamily,
                                    color: Colors.grey,
                                  ),
                        )
                      : null),
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ],
    );
  }
}
