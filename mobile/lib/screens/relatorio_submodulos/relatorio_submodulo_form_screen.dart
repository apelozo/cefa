import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/relatorio_submodulo.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';

class RelatorioSubmoduloFormScreen extends ConsumerStatefulWidget {
  const RelatorioSubmoduloFormScreen({super.key, this.submodulo});

  final RelatorioSubmodulo? submodulo;

  bool get isEditing => submodulo != null;

  @override
  ConsumerState<RelatorioSubmoduloFormScreen> createState() =>
      _RelatorioSubmoduloFormScreenState();
}

class _RelatorioSubmoduloFormScreenState
    extends ConsumerState<RelatorioSubmoduloFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _ordemController;
  late final FormEnterFocus _enterFocus;
  bool _ativo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(widget.isEditing ? 3 : 4);
    _codigoController =
        TextEditingController(text: widget.submodulo?.codigo ?? '');
    _nomeController =
        TextEditingController(text: widget.submodulo?.nome ?? '');
    _descricaoController =
        TextEditingController(text: widget.submodulo?.descricao ?? '');
    _ordemController = TextEditingController(
      text: (widget.submodulo?.ordem ?? 0).toString(),
    );
    _ativo = widget.submodulo?.ativo ?? true;
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _codigoController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _ordemController.dispose();
    super.dispose();
  }

  int? _parseOrdem() {
    final raw = _ordemController.text.trim();
    if (raw.isEmpty) return 0;
    return int.tryParse(raw);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ordem = _parseOrdem();
    if (ordem == null || ordem < 0) {
      showErrorSnackBar(context, 'Ordem inválida');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final descricao = _descricaoController.text.trim();

      if (widget.isEditing) {
        await api.updateRelatorioSubmodulo(
          RelatorioSubmodulo(
            id: widget.submodulo!.id,
            codigo: widget.submodulo!.codigo,
            nome: _nomeController.text.trim(),
            descricao: descricao.isEmpty ? null : descricao,
            ordem: ordem,
            ativo: _ativo,
            auditoria: widget.submodulo!.auditoria,
          ),
        );
      } else {
        await api.createRelatorioSubmodulo(
          RelatorioSubmodulo(
            id: '',
            codigo: _codigoController.text.trim().toLowerCase(),
            nome: _nomeController.text.trim(),
            descricao: descricao.isEmpty ? null : descricao,
            ordem: ordem,
            ativo: _ativo,
          ),
        );
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isEditing ? 'Submódulo atualizado' : 'Submódulo criado',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar submódulo' : 'Novo submódulo',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppLayout.screenPadding,
            children: [
              if (!widget.isEditing)
                TextFormField(
                  controller: _codigoController,
                  focusNode: _enterFocus.fields[0],
                  textInputAction: _enterFocus.inputAction(0),
                  onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    hintText: 'ex.: iefa',
                    helperText:
                        'Minúsculas, números e underscore. Não altera após criar.',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Código é obrigatório';
                    }
                    final c = v.trim().toLowerCase();
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(c)) {
                      return 'Use letras minúsculas, números e _';
                    }
                    return null;
                  },
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Código',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  subtitle: Text(_codigoController.text),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeController,
                focusNode: _enterFocus.fields[widget.isEditing ? 0 : 1],
                textInputAction:
                    _enterFocus.inputAction(widget.isEditing ? 0 : 1),
                onFieldSubmitted: (_) =>
                    _enterFocus.onSubmitted(widget.isEditing ? 0 : 1),
                decoration: const InputDecoration(
                  labelText: 'Nome (exibido na Home)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                focusNode: _enterFocus.fields[widget.isEditing ? 1 : 2],
                textInputAction:
                    _enterFocus.inputAction(widget.isEditing ? 1 : 2),
                onFieldSubmitted: (_) =>
                    _enterFocus.onSubmitted(widget.isEditing ? 1 : 2),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ordemController,
                focusNode: _enterFocus.fields[widget.isEditing ? 2 : 3],
                textInputAction:
                    _enterFocus.inputAction(widget.isEditing ? 2 : 3),
                onFieldSubmitted: (_) =>
                    _enterFocus.onSubmitted(widget.isEditing ? 2 : 3),
                decoration: const InputDecoration(
                  labelText: 'Ordem na Home',
                  helperText: 'Menor número aparece primeiro entre submódulos.',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'Informe um número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                subtitle: const Text(
                  'Submódulos inativos não podem ser vinculados a novos programas.',
                ),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              if (widget.isEditing && widget.submodulo != null)
                AuditoriaSection(auditoria: widget.submodulo!.auditoria),
              const SizedBox(height: 24),
              AppButton(
                label: widget.isEditing ? 'Salvar' : 'Criar',
                focusNode: _enterFocus.submitFocusNode,
                onPressed: _saving ? null : _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
