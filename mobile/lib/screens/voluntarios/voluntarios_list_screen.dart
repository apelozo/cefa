import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/departamento.dart';
import '../../models/voluntario.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import '../../widgets/record_action_buttons.dart';
import 'voluntario_form_screen.dart';

class VoluntariosListScreen extends ConsumerStatefulWidget {
  const VoluntariosListScreen({super.key});

  @override
  ConsumerState<VoluntariosListScreen> createState() =>
      _VoluntariosListScreenState();
}

class _VoluntariosListScreenState extends ConsumerState<VoluntariosListScreen> {
  List<Voluntario>? _voluntarios;
  List<Departamento> _departamentos = [];
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  bool _loading = false;
  bool _loadingDepartamentos = true;
  bool _mostrarInativos = false;
  int? _departamentoCodigo;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
    _loadDepartamentos();
    _load();
  }

  Future<void> _loadDepartamentos() async {
    try {
      final auth = ref.read(authProvider);
      if (!auth.podeConsultar(Programas.departamentos)) {
        if (mounted) setState(() => _loadingDepartamentos = false);
        return;
      }
      final items = await ref.read(apiClientProvider).listDepartamentos(ativo: true);
      if (!mounted) return;
      setState(() {
        _departamentos = items
          ..sort((a, b) => a.descricao.compareTo(b.descricao));
        _loadingDepartamentos = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDepartamentos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  bool get _temFiltroBusca =>
      _nomeController.text.trim().isNotEmpty ||
      _cpfController.text.trim().isNotEmpty ||
      _departamentoCodigo != null;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final nome = _nomeController.text.trim();
      final cpf = _cpfController.text.trim();
      final items = await ref.read(apiClientProvider).listVoluntarios(
            ativo: _mostrarInativos ? null : true,
            nome: nome.isNotEmpty ? nome : null,
            cpf: cpf.isNotEmpty ? cpf : null,
            departamentoCodigo: _departamentoCodigo,
          );
      if (mounted) setState(() => _voluntarios = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Voluntario? voluntario]) async {
    final auth = ref.read(authProvider);
    if (voluntario == null && !auth.podeIncluir(Programas.voluntarios)) {
      return;
    }
    if (voluntario != null && !auth.podeAlterar(Programas.voluntarios)) {
      return;
    }
    if (voluntario != null && !voluntario.ativo) {
      showErrorSnackBar(
        context,
        'Voluntário desativado não pode ser editado.',
      );
      return;
    }

    final saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => VoluntarioFormScreen(voluntario: voluntario),
      ),
    );
    if (saved == true || saved is Voluntario) _load();
  }

  Future<void> _desativar(Voluntario voluntario) async {
    if (!ref.read(authProvider).podeExcluir(Programas.voluntarios)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar voluntário?'),
        content: Text(
          '"${voluntario.codigo} — ${voluntario.nome}" será desativado.\n\n'
          'O registro permanece no banco e pode ser consultado com o filtro Inativos.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).desativarVoluntario(voluntario.id);
      if (mounted) {
        showSuccessSnackBar(context, 'Voluntário desativado');
        _load();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  String _mensagemListaVazia() {
    if (_temFiltroBusca) {
      return 'Nenhum voluntário encontrado para os filtros informados.';
    }
    if (_mostrarInativos) {
      return 'Nenhum voluntário cadastrado.';
    }
    return 'Nenhum voluntário ativo.\nAtive "Inativos" para ver desativados.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeIncluir = auth.podeIncluir(Programas.voluntarios);
    final podeAlterar = auth.podeAlterar(Programas.voluntarios);
    final podeExcluir = auth.podeExcluir(Programas.voluntarios);

    return PermissaoGate(
      programaCodigo: Programas.voluntarios,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: 'Voluntários',
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
                0,
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    focusNode: _enterFocus.fields[0],
                    textInputAction: _enterFocus.inputAction(0),
                    onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                    onEditingComplete: _enterFocus.editingComplete(0),
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _departamentoCodigo,
                    decoration: InputDecoration(
                      labelText: 'Departamento',
                      prefixIcon: const Icon(Icons.apartment_outlined),
                      helperText: _loadingDepartamentos
                          ? 'Carregando departamentos…'
                          : (_departamentos.isEmpty
                              ? 'Sem permissão ou nenhum departamento ativo'
                              : null),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._departamentos.map(
                        (d) => DropdownMenuItem<int?>(
                          value: d.codigo,
                          child: Text('${d.codigo} — ${d.descricao}'),
                        ),
                      ),
                    ],
                    onChanged: _loadingDepartamentos
                        ? null
                        : (v) => setState(() => _departamentoCodigo = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cpfController,
                    focusNode: _enterFocus.fields[1],
                    textInputAction: _enterFocus.inputAction(1),
                    onFieldSubmitted: (_) => _load(),
                    onEditingComplete: _enterFocus.editingComplete(1),
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfFormatter()],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Buscar',
                    focusNode: _enterFocus.submitFocusNode,
                    onPressed: _loading ? null : _load,
                    loading: _loading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildList(podeAlterar, podeExcluir),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool podeAlterar, bool podeExcluir) {
    if (_loading && _voluntarios == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_voluntarios == null || _voluntarios!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            _mensagemListaVazia(),
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
        itemCount: _voluntarios!.length,
        itemBuilder: (context, index) {
          final v = _voluntarios![index];
          final subtitulo = [
            if (v.empresa != null && v.empresa!.isNotEmpty) v.empresa,
            if (v.funcao != null && v.funcao!.isNotEmpty) v.funcao,
            if (v.cpf != null && v.cpf!.isNotEmpty) formatCpfDisplay(v.cpf!),
          ].join(' · ');

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
                        v.codigo.toString(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.nome,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (v.nomeCracha.trim().toLowerCase() !=
                              v.nome.trim().toLowerCase())
                            Text(
                              'Crachá: ${v.nomeCracha}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (!v.ativo)
                      Text(
                        'Inativo',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                      ),
                  ],
                ),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitulo,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                RecordActionButtons(
                  onEdit: podeAlterar && v.ativo ? () => _openForm(v) : null,
                  onDelete:
                      podeExcluir && v.ativo ? () => _desativar(v) : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
