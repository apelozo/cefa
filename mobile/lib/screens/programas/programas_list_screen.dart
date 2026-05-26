import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/programa.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'programa_form_screen.dart';

class ProgramasListScreen extends ConsumerStatefulWidget {
  const ProgramasListScreen({super.key});

  @override
  ConsumerState<ProgramasListScreen> createState() =>
      _ProgramasListScreenState();
}

class _ProgramasListScreenState extends ConsumerState<ProgramasListScreen> {
  List<Programa>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listProgramas();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Programa? item]) async {
    final auth = ref.read(authProvider);
    if (item == null && !auth.podeIncluir(Programas.modulosSistema)) return;
    if (item != null && !auth.podeAlterar(Programas.modulosSistema)) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProgramaFormScreen(programa: item),
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.modulosSistema);
    final podeAlterar = auth.podeAlterar(Programas.modulosSistema);

    return PermissaoGate(
      programaCodigo: Programas.modulosSistema,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: 'Programas do sistema'),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items == null || _items!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        'Nenhum programa cadastrado.\n'
                        'Crie um programa para vinculá-lo aos módulos e liberar acessos.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.accentOrange,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        AppLayout.screenPaddingTop,
                        AppLayout.screenPaddingH,
                        88,
                      ),
                      itemCount: _items!.length,
                      itemBuilder: (context, index) {
                        final p = _items![index];
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nome,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Código: ${p.codigo}'
                                '${p.moduloNome != null ? ' · Módulo: ${p.moduloNome}' : ''}'
                                '${p.autoListagem ? ' · Listagem' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (podeAlterar) ...[
                                const SizedBox(height: 12),
                                RecordActionButtons(
                                  onEdit: () => _openForm(p),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
