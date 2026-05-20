import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/tipo_formulario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../pessoas/pessoas_search_args.dart';
import '../pessoas/pessoas_search_screen.dart';
import 'lancamento_formulario_screen.dart';

class LancamentoTipoScreen extends ConsumerStatefulWidget {
  const LancamentoTipoScreen({super.key});

  @override
  ConsumerState<LancamentoTipoScreen> createState() =>
      _LancamentoTipoScreenState();
}

class _LancamentoTipoScreenState extends ConsumerState<LancamentoTipoScreen> {
  List<TipoFormulario>? _tipos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tipos =
          await ref.read(apiClientProvider).listTiposFormulario(ativo: true);
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _selecionarTipo(TipoFormulario tipo) async {
    final pessoa = await PessoasSearchScreen.select(
      context,
      args: PessoasSearchArgs(
        title: 'Pessoa do lançamento',
        subtitle: 'Formulário: ${tipo.nome}',
        onlyAtivas: true,
      ),
    );
    if (pessoa == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LancamentoFormularioScreen(
          tipo: tipo,
          pessoa: pessoa,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissaoGate(
      programaCodigo: Programas.lancamento,
      child: AppScaffold(
      appBar: AppScreenChrome.appBar(context, title: 'Lançamento'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tipos == null || _tipos!.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppLayout.screenPadding,
                    child: Text(
                      'Nenhum tipo de formulário ativo.\nCadastre um tipo antes de lançar respostas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.screenPaddingH,
                    AppLayout.screenPaddingTop,
                    AppLayout.screenPaddingH,
                    AppLayout.screenPaddingBottom,
                  ),
                  children: [
                    Text(
                      'Selecione o tipo de formulário',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ..._tipos!.map(
                      (tipo) => AppCard(
                        onTap: () => _selecionarTipo(tipo),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tipo.nome,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if (tipo.descricao != null &&
                                      tipo.descricao!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tipo.descricao!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.neutralGray,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    ),
    );
  }
}
