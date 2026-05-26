import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/submissao.dart';
import '../../models/tipo_formulario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/resposta_display.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/permissao_gate.dart';
import 'submissao_detail_screen.dart';

class SubmissoesListScreen extends ConsumerStatefulWidget {
  const SubmissoesListScreen({super.key});

  @override
  ConsumerState<SubmissoesListScreen> createState() =>
      _SubmissoesListScreenState();
}

class _SubmissoesListScreenState extends ConsumerState<SubmissoesListScreen> {
  List<TipoFormulario> _tipos = [];
  List<SubmissaoResumo>? _items;
  String? _tipoFormularioId;
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  late final FormEnterFocus _enterFocus;
  bool _loadingTipos = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(2);
    _loadTipos();
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _loadTipos() async {
    try {
      final tipos = await ref.read(apiClientProvider).listTiposFormulario();
      if (mounted) {
        setState(() {
          _tipos = tipos;
          _loadingTipos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTipos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(apiClientProvider).listSubmissoes(
            tipoFormularioId: _tipoFormularioId,
            nome: _nomeController.text.trim().isNotEmpty
                ? _nomeController.text.trim()
                : null,
            cpf: _cpfController.text.trim().isNotEmpty
                ? _cpfController.text.trim()
                : null,
          );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(SubmissaoResumo item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubmissaoDetailScreen(submissaoId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissaoGate(
      programaCodigo: Programas.submissoes,
      child: AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: 'Consulta de respostas',
      ),
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
                if (_loadingTipos)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String?>(
                    key: ValueKey(_tipoFormularioId),
                    initialValue: _tipoFormularioId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de formulário',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._tipos.map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.nome),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _tipoFormularioId = v),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomeController,
                  focusNode: _enterFocus.fields[0],
                  textInputAction: _enterFocus.inputAction(0),
                  onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  onEditingComplete: _enterFocus.editingComplete(0),
                  decoration: const InputDecoration(
                    labelText: 'Nome do assistido',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cpfController,
                  focusNode: _enterFocus.fields[1],
                  textInputAction: _enterFocus.inputAction(1),
                  onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                  onEditingComplete: _enterFocus.editingComplete(1),
                  decoration: const InputDecoration(
                    labelText: 'CPF do assistido',
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
          Expanded(child: _buildList()),
        ],
      ),
    ),
    );
  }

  Widget _buildList() {
    if (_items == null) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            'Filtre por tipo de formulário, nome ou CPF e toque em Buscar.\n'
            'Toque em um lançamento para ver as respostas e gerar PDF.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutralGray,
                ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items!.isEmpty) {
      return Center(
        child: Padding(
          padding: AppLayout.screenPadding,
          child: Text(
            'Nenhum lançamento encontrado.',
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
          AppLayout.screenPaddingBottom,
        ),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final s = _items![index];
          return AppCard(
            onTap: () => _openDetail(s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tipoFormularioNome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.pessoaNome,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'CPF: ${s.pessoaCpfFormatado}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.neutralGray,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatSubmissaoData(s.createdAt)} · ${s.totalRespostas} resposta(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.neutralGray,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
