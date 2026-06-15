import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/periodo_inscricao.dart';
import '../../constants/situacao_turma.dart';
import '../../models/curso.dart';
import '../../models/turma.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'turma_form_screen.dart';

class TurmasListScreen extends ConsumerStatefulWidget {
  const TurmasListScreen({super.key});

  @override
  ConsumerState<TurmasListScreen> createState() => _TurmasListScreenState();
}

class _TurmasListScreenState extends ConsumerState<TurmasListScreen> {
  List<Turma>? _turmas;
  List<Curso> _cursos = [];
  bool _loading = true;
  bool _loadingCursos = true;
  bool _mostrarInativos = false;
  int? _cursoCodigo;

  @override
  void initState() {
    super.initState();
    _loadCursos();
    _load();
  }

  Future<void> _loadCursos() async {
    try {
      final auth = ref.read(authProvider);
      if (!auth.podeConsultar(Programas.cursos)) {
        if (mounted) setState(() => _loadingCursos = false);
        return;
      }
      final items = await ref.read(apiClientProvider).listCursos(ativo: true);
      if (!mounted) return;
      setState(() {
        _cursos = items..sort((a, b) => a.descricao.compareTo(b.descricao));
        _loadingCursos = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCursos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listTurmas(
            ativo: _mostrarInativos ? null : true,
            cursoCodigo: _cursoCodigo,
          );
      if (mounted) setState(() => _turmas = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Turma? turma]) async {
    final auth = ref.read(authProvider);
    if (turma == null && !auth.podeIncluir(Programas.turmas)) {
      return;
    }
    if (turma != null && !auth.podeAlterar(Programas.turmas)) {
      return;
    }
    if (turma != null && !turma.ativo) {
      showErrorSnackBar(
        context,
        'Turma desativada não pode ser editada.',
      );
      return;
    }

    Turma? detalhe = turma;
    if (turma != null) {
      try {
        detalhe = await ref.read(apiClientProvider).getTurma(turma.id);
      } catch (e) {
        if (mounted) showErrorSnackBar(context, e.toString());
        return;
      }
    }

    if (!mounted) return;
    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => TurmaFormScreen(turma: detalhe),
      ),
    );
    if (saved == true || saved is Turma) _load();
  }

  Future<void> _desativar(Turma turma) async {
    if (!ref.read(authProvider).podeExcluir(Programas.turmas)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar turma?'),
        content: Text(
          '"${turma.codigo} — ${turma.nome}" será desativada.\n\n'
          'O registro permanece no banco.',
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
      await ref.read(apiClientProvider).desativarTurma(turma.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Turma desativada');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.turmas);
    final podeAlterar = auth.podeAlterar(Programas.turmas);
    final podeExcluir = auth.podeExcluir(Programas.turmas);

    return PermissaoGate(
      programaCodigo: Programas.turmas,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Cadastro de Turmas',
          actions: [
            IconButton(
              tooltip: _mostrarInativos ? 'Ocultar inativos' : 'Mostrar inativos',
              icon: Icon(
                _mostrarInativos
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() => _mostrarInativos = !_mostrarInativos);
                _load();
              },
            ),
          ],
        ),
        floatingActionButton: podeIncluir
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
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
                0,
              ),
              child: DropdownButtonFormField<int?>(
                value: _cursoCodigo,
                decoration: InputDecoration(
                  labelText: 'Curso',
                  prefixIcon: const Icon(Icons.school_outlined),
                  helperText: _loadingCursos
                      ? 'Carregando cursos…'
                      : (_cursos.isEmpty
                          ? 'Sem permissão ou nenhum curso ativo'
                          : null),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos os cursos'),
                  ),
                  ..._cursos.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.codigo,
                      child: Text('${c.codigo} — ${c.descricao}'),
                    ),
                  ),
                ],
                onChanged: _loadingCursos
                    ? null
                    : (v) {
                        setState(() => _cursoCodigo = v);
                        _load();
                      },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList(podeAlterar, podeExcluir)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool podeAlterar, bool podeExcluir) {
    if (_loading && _turmas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_turmas == null || _turmas!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            _cursoCodigo != null
                ? 'Nenhuma turma encontrada para o curso selecionado.'
                : (_mostrarInativos
                    ? 'Nenhuma turma cadastrada.'
                    : 'Nenhuma turma ativa.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPaddingH,
          0,
          AppLayout.screenPaddingH,
          88,
        ),
        itemCount: _turmas!.length,
        itemBuilder: (context, index) {
          final item = _turmas![index];
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.codigo.toString(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (!item.ativo)
                      Text(
                        'Inativo',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.cursoDescricao,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      PeriodoInscricao.rotulo(item.periodo),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      item.situacaoRotulo ??
                          SituacaoTurma.rotulo(item.situacao),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: item.situacao == SituacaoTurma.aberta
                                ? Colors.green.shade700
                                : AppColors.neutralGray,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RecordActionButtons(
                  onEdit: podeAlterar && item.ativo
                      ? () => _openForm(item)
                      : null,
                  onDelete: podeExcluir && item.ativo
                      ? () => _desativar(item)
                      : null,
                  deleteTooltip: 'Desativar',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
