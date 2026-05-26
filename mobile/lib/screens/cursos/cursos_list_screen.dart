import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/curso.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'curso_form_screen.dart';

class CursosListScreen extends ConsumerStatefulWidget {
  const CursosListScreen({super.key});

  @override
  ConsumerState<CursosListScreen> createState() => _CursosListScreenState();
}

class _CursosListScreenState extends ConsumerState<CursosListScreen> {
  List<Curso>? _cursos;
  bool _loading = true;
  bool _mostrarInativos = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listCursos(
            ativo: _mostrarInativos ? null : true,
          );
      if (mounted) setState(() => _cursos = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Curso? curso]) async {
    final auth = ref.read(authProvider);
    if (curso == null && !auth.podeIncluir(Programas.cursos)) {
      return;
    }
    if (curso != null && !auth.podeAlterar(Programas.cursos)) {
      return;
    }
    if (curso != null && !curso.ativo) {
      showErrorSnackBar(
        context,
        'Curso desativado não pode ser editado.',
      );
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => CursoFormScreen(curso: curso),
      ),
    );
    if (saved == true || saved is Curso) _load();
  }

  Future<void> _desativar(Curso curso) async {
    if (!ref.read(authProvider).podeExcluir(Programas.cursos)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar curso?'),
        content: Text(
          '"${curso.codigo} — ${curso.descricao}" será desativado.\n\n'
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
      await ref.read(apiClientProvider).desativarCurso(curso.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Curso desativado');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.cursos);
    final podeAlterar = auth.podeAlterar(Programas.cursos);
    final podeExcluir = auth.podeExcluir(Programas.cursos);

    return PermissaoGate(
      programaCodigo: Programas.cursos,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Cursos',
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _cursos == null || _cursos!.isEmpty
                ? Center(
                    child: Padding(
                      padding: AppLayout.screenPadding,
                      child: Text(
                        _mostrarInativos
                            ? 'Nenhum curso cadastrado.'
                            : 'Nenhum curso ativo.\nAtive "Inativos" para ver desativados.',
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
                      itemCount: _cursos!.length,
                      itemBuilder: (context, index) {
                        final c = _cursos![index];
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
                                      c.codigo.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      c.descricao,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  if (!c.ativo)
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
                              const SizedBox(height: 12),
                              RecordActionButtons(
                                onEdit: podeAlterar && c.ativo
                                    ? () => _openForm(c)
                                    : null,
                                onDelete: podeExcluir && c.ativo
                                    ? () => _desativar(c)
                                    : null,
                              ),
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
