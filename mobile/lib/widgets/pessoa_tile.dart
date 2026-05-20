import 'package:flutter/material.dart';

import '../models/pessoa.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

/// Conteúdo do cartão de pessoa (sem [AppCard]).
class PessoaTileBody extends StatelessWidget {
  const PessoaTileBody({
    super.key,
    required this.pessoa,
    this.showChevron = true,
  });

  final Pessoa pessoa;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pessoa.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (!pessoa.ativo)
                    Text(
                      'Inativo',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'CPF: ${pessoa.cpfExibicao}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutralGray,
                    ),
              ),
              Text(
                'RG: ${pessoa.rgExibicao} · Nasc.: ${pessoa.dtNascimento}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutralGray,
                    ),
              ),
              if (pessoa.nomeSocial != null &&
                  pessoa.nomeSocial!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Nome social: ${pessoa.nomeSocial}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutralGray,
                      ),
                ),
              ],
              if (pessoa.nomeMae != null && pessoa.nomeMae!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Mãe: ${pessoa.nomeMae}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutralGray,
                      ),
                ),
              ],
              if (pessoa.municipioExibicao != null) ...[
                const SizedBox(height: 2),
                Text(
                  pessoa.municipioExibicao!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.neutralGray,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (showChevron)
          const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
      ],
    );
  }
}

/// Cartão resumido de pessoa (listas e pesquisa).
class PessoaTile extends StatelessWidget {
  const PessoaTile({
    super.key,
    required this.pessoa,
    this.onTap,
    this.showChevron = true,
  });

  final Pessoa pessoa;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: PessoaTileBody(pessoa: pessoa, showChevron: showChevron),
    );
  }
}
