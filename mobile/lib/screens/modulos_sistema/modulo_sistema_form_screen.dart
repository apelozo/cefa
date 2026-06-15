import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/modulo_sistema.dart';
import '../../models/programa.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';
import '../programas/programa_form_screen.dart';

class ModuloSistemaFormScreen extends ConsumerStatefulWidget {
  const ModuloSistemaFormScreen({super.key, this.modulo});

  final ModuloSistema? modulo;

  bool get isEditing => modulo != null;

  @override
  ConsumerState<ModuloSistemaFormScreen> createState() =>
      _ModuloSistemaFormScreenState();
}

class _ModuloSistemaFormScreenState
    extends ConsumerState<ModuloSistemaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _ordemController;
  late final FormEnterFocus _enterFocus;
  late bool _ativo;
  bool _saving = false;
  bool _loadingProgramas = true;
  List<Programa> _todosProgramas = [];
  final Set<String> _programaIdsSelecionados = {};

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(3);
    _nomeController = TextEditingController(text: widget.modulo?.nome ?? '');
    _descricaoController =
        TextEditingController(text: widget.modulo?.descricao ?? '');
    _ordemController = TextEditingController(
      text: (widget.modulo?.ordem ?? 0).toString(),
    );
    _ativo = widget.modulo?.ativo ?? true;
    if (widget.modulo != null) {
      _programaIdsSelecionados.addAll(
        widget.modulo!.programas.map((p) => p.id),
      );
    }
    _loadProgramas();
  }

  Future<void> _loadProgramas() async {
    try {
      final programas = await ref.read(apiClientProvider).listProgramas();
      if (mounted) {
        setState(() {
          _todosProgramas = programas;
          _loadingProgramas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProgramas = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _ordemController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ordem = int.tryParse(_ordemController.text.trim());
    if (ordem == null || ordem < 0) {
      showErrorSnackBar(context, 'Informe uma ordem válida (número ≥ 0)');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final descricao = _descricaoController.text.trim();
      ModuloSistema moduloSalvo;

      if (widget.isEditing) {
        moduloSalvo = await api.updateModuloSistema(
          ModuloSistema(
            id: widget.modulo!.id,
            codigo: widget.modulo!.codigo,
            nome: _nomeController.text.trim(),
            descricao: descricao.isEmpty ? null : descricao,
            ordem: ordem,
            ativo: _ativo,
            createdAt: widget.modulo!.createdAt,
          ),
        );
      } else {
        moduloSalvo = await api.createModuloSistema(
          ModuloSistema(
            id: '',
            codigo: 0,
            nome: _nomeController.text.trim(),
            descricao: descricao.isEmpty ? null : descricao,
            ordem: ordem,
            ativo: _ativo,
            createdAt: DateTime.now(),
          ),
        );
      }

      await api.setModuloProgramas(
        moduloSalvo.id,
        _programaIdsSelecionados.toList(),
      );

      if (mounted) {
        showSuccessSnackBar(context, 'Salvo com sucesso');
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
        title: widget.isEditing ? 'Alterar módulo' : 'Novo módulo',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppLayout.screenPadding,
            children: [
              if (widget.isEditing)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Código',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  subtitle: Text(widget.modulo!.codigo.toString()),
                ),
              if (widget.isEditing) const SizedBox(height: 12),
              TextFormField(
                controller: _nomeController,
                focusNode: _enterFocus.fields[0],
                textInputAction: _enterFocus.inputAction(0),
                onFieldSubmitted: (_) => _enterFocus.onSubmitted(0),
                onEditingComplete: _enterFocus.editingComplete(0),
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                focusNode: _enterFocus.fields[1],
                textInputAction: _enterFocus.inputAction(1),
                onFieldSubmitted: (_) => _enterFocus.onSubmitted(1),
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ordemController,
                focusNode: _enterFocus.fields[2],
                textInputAction: _enterFocus.inputAction(2),
                onFieldSubmitted: (_) => _enterFocus.onSubmitted(2),
                onEditingComplete: _enterFocus.editingComplete(2),
                decoration: const InputDecoration(labelText: 'Ordem no menu'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ordem é obrigatória';
                  }
                  if (int.tryParse(v.trim()) == null) {
                    return 'Informe um número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Programas do módulo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final criado = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const ProgramaFormScreen(),
                        ),
                      );
                      if (criado == true) _loadProgramas();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Novo programa'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingProgramas)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_todosProgramas.isEmpty)
                Text(
                  'Nenhum programa cadastrado.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ..._todosProgramas.map((p) {
                  final selected = _programaIdsSelecionados.contains(p.id);
                  final emOutroModulo = p.moduloSistemaId != null &&
                      p.moduloSistemaId != widget.modulo?.id;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _programaIdsSelecionados.add(p.id);
                        } else {
                          _programaIdsSelecionados.remove(p.id);
                        }
                      });
                    },
                    title: Text(p.nome),
                    subtitle: Text(
                      p.codigo +
                          (emOutroModulo && p.moduloNome != null
                              ? ' · atualmente em: ${p.moduloNome}'
                              : ''),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              if (widget.isEditing && widget.modulo != null)
                AuditoriaSection(
                  auditoria: widget.modulo!.auditoria,
                  mostrarExclusao: !widget.modulo!.ativo,
                ),
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
