import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/aluno.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'aluno_form_screen.dart';

class AlunosListScreen extends ConsumerStatefulWidget {
  const AlunosListScreen({super.key});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  List<Aluno>? _alunos;
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  bool _loading = true;
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final nome = _nomeController.text.trim();
      final cpf = _cpfController.text.trim();
      final items = await ref.read(apiClientProvider).listAlunos(
            ativo: _mostrarInativos ? null : true,
            nome: nome.isEmpty ? null : nome,
            cpf: cpf.isEmpty ? null : cpf,
          );
      if (mounted) setState(() => _alunos = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Aluno? aluno]) async {
    final auth = ref.read(authProvider);
    if (aluno == null && !auth.podeIncluir(Programas.alunos)) {
      return;
    }
    if (aluno != null && !auth.podeAlterar(Programas.alunos)) {
      return;
    }
    if (aluno != null && !aluno.ativo) {
      showErrorSnackBar(
        context,
        'Aluno desativado não pode ser editado.',
      );
      return;
    }

    Aluno? alunoCompleto = aluno;
    if (aluno != null) {
      try {
        alunoCompleto = await ref.read(apiClientProvider).getAluno(aluno.id);
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e.toString());
        return;
      }
    }

    if (!mounted) return;
    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => AlunoFormScreen(aluno: alunoCompleto),
      ),
    );
    if (saved == true || saved is Aluno) _load();
  }

  Future<void> _desativar(Aluno aluno) async {
    if (!ref.read(authProvider).podeExcluir(Programas.alunos)) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar aluno?'),
        content: Text(
          '"${aluno.nome}" será desativado.\n\nO registro permanece no banco.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(apiClientProvider).desativarAluno(aluno.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Aluno desativado');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.alunos);
    final podeAlterar = auth.podeAlterar(Programas.alunos);
    final podeExcluir = auth.podeExcluir(Programas.alunos);

    return PermissaoGate(
      programaCodigo: Programas.alunos,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Cadastro de Alunos',
          actions: [
            FilterChip(
              label: const Text('Inativos'),
              selected: _mostrarInativos,
              onSelected: _loading
                  ? null
                  : (v) {
                      setState(() => _mostrarInativos = v);
                      _load();
                    },
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingTop,
                AppLayout.screenPaddingH,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cpfController,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CpfFormatter()],
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pesquisar',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alunos == null || _alunos!.isEmpty
                      ? Center(
                          child: Padding(
                            padding: AppLayout.screenPadding,
                            child: Text(
                              _mostrarInativos
                                  ? 'Nenhum aluno cadastrado.'
                                  : 'Nenhum aluno ativo.',
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
                              8,
                              AppLayout.screenPaddingH,
                              88,
                            ),
                            itemCount: _alunos!.length,
                            itemBuilder: (context, index) {
                              final a = _alunos![index];
                              return AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.nome,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        if (!a.ativo)
                                          Text(
                                            'Inativo',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                          ),
                                      ],
                                    ),
                                    if ((a.cpfFormatado != null &&
                                            a.cpfFormatado!.isNotEmpty) ||
                                        (a.dtNascimento != null &&
                                            a.dtNascimento!.isNotEmpty) ||
                                        a.idade != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (a.cpfFormatado != null &&
                                                a.cpfFormatado!.isNotEmpty)
                                              Text(
                                                'CPF: ${a.cpfFormatado}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            if (a.dtNascimento != null &&
                                                a.dtNascimento!.isNotEmpty)
                                              Text(
                                                a.dtNascimento!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            if (a.idade != null)
                                              Text(
                                                'Idade: ${a.idade}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    RecordActionButtons(
                                      onEdit: podeAlterar && a.ativo
                                          ? () => _openForm(a)
                                          : null,
                                      onDelete: podeExcluir && a.ativo
                                          ? () => _desativar(a)
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
