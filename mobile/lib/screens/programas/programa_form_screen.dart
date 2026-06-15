import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/modulo_relatorios.dart';
import '../../models/modulo_sistema.dart';
import '../../models/programa.dart';
import '../../models/relatorio_submodulo.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';

class ProgramaFormScreen extends ConsumerStatefulWidget {
  const ProgramaFormScreen({super.key, this.programa});

  final Programa? programa;

  bool get isEditing => programa != null;

  @override
  ConsumerState<ProgramaFormScreen> createState() => _ProgramaFormScreenState();
}

class _ProgramaFormScreenState extends ConsumerState<ProgramaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nomeController;
  late final FormEnterFocus _enterFocus;
  bool _autoListagem = false;
  String? _moduloSistemaId;
  int? _moduloCodigo;
  String? _relatorioSubmoduloId;
  List<ModuloSistema> _modulos = [];
  List<RelatorioSubmodulo> _submodulos = [];
  bool _loadingModulos = true;
  bool _loadingSubmodulos = false;
  bool _saving = false;

  bool get _moduloEhRelatorios => _moduloCodigo == moduloRelatoriosCodigo;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(widget.isEditing ? 2 : 3);
    _codigoController = TextEditingController(text: widget.programa?.codigo ?? '');
    _nomeController = TextEditingController(text: widget.programa?.nome ?? '');
    _autoListagem = widget.programa?.autoListagem ?? false;
    _moduloSistemaId = widget.programa?.moduloSistemaId;
    _moduloCodigo = widget.programa?.moduloCodigo;
    _relatorioSubmoduloId = widget.programa?.relatorioSubmoduloId;
    _loadModulos();
  }

  Future<void> _loadSubmodulos() async {
    if (!_moduloEhRelatorios) {
      setState(() {
        _submodulos = [];
        _relatorioSubmoduloId = null;
        _loadingSubmodulos = false;
      });
      return;
    }

    setState(() => _loadingSubmodulos = true);
    try {
      final submodulos =
          await ref.read(apiClientProvider).listRelatorioSubmodulos(ativo: true);
      if (mounted) {
        setState(() {
          _submodulos = submodulos;
          _loadingSubmodulos = false;
          if (_relatorioSubmoduloId != null &&
              !submodulos.any((s) => s.id == _relatorioSubmoduloId)) {
            _relatorioSubmoduloId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSubmodulos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  void _onModuloChanged(String? moduloId) {
    ModuloSistema? modulo;
    if (moduloId != null) {
      for (final m in _modulos) {
        if (m.id == moduloId) {
          modulo = m;
          break;
        }
      }
    }
    setState(() {
      _moduloSistemaId = moduloId;
      _moduloCodigo = modulo?.codigo;
      if (!_moduloEhRelatorios) {
        _relatorioSubmoduloId = null;
      }
    });
    _loadSubmodulos();
  }

  Future<void> _loadModulos() async {
    try {
      final modulos = await ref.read(apiClientProvider).listModulosSistema();
      if (mounted) {
        setState(() {
          _modulos = modulos.where((m) => m.ativo).toList();
          _loadingModulos = false;
          if (_moduloSistemaId != null) {
            ModuloSistema? modulo;
            for (final m in _modulos) {
              if (m.id == _moduloSistemaId) {
                modulo = m;
                break;
              }
            }
            _moduloCodigo = modulo?.codigo;
          }
        });
        await _loadSubmodulos();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingModulos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _codigoController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_moduloEhRelatorios &&
        (_relatorioSubmoduloId == null || _relatorioSubmoduloId!.isEmpty)) {
      showErrorSnackBar(
        context,
        'Selecione o submódulo de relatório para programas do módulo Relatórios.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final nome = _nomeController.text.trim();
      final codigo = _codigoController.text.trim().toLowerCase();

      if (widget.isEditing) {
        await api.updatePrograma(
          Programa(
            id: widget.programa!.id,
            codigo: widget.programa!.codigo,
            nome: nome,
            autoListagem: _autoListagem,
            moduloSistemaId: _moduloSistemaId,
            relatorioSubmoduloId:
                _moduloEhRelatorios ? _relatorioSubmoduloId : null,
          ),
        );
      } else {
        await api.createPrograma(
          Programa(
            id: '',
            codigo: codigo,
            nome: nome,
            autoListagem: _autoListagem,
            moduloSistemaId: _moduloSistemaId,
            relatorioSubmoduloId:
                _moduloEhRelatorios ? _relatorioSubmoduloId : null,
          ),
        );
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isEditing ? 'Programa atualizado' : 'Programa criado',
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
        title: widget.isEditing ? 'Editar programa' : 'Novo programa',
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
                    hintText: 'ex.: relatorios_custom',
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
                  labelText: 'Nome (exibido na liberação de acesso)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Listagem automática'),
                subtitle: const Text(
                  'Marque se o programa corresponde a uma tela de lista no menu.',
                ),
                value: _autoListagem,
                onChanged: (v) => setState(() => _autoListagem = v),
              ),
              const SizedBox(height: 12),
              if (_loadingModulos)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                DropdownButtonFormField<String?>(
                  value: _moduloSistemaId,
                  decoration: const InputDecoration(
                    labelText: 'Módulo do menu (opcional)',
                  ),
                  hint: const Text('Selecione'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Nenhum'),
                    ),
                    ..._modulos.map(
                      (m) => DropdownMenuItem<String?>(
                        value: m.id,
                        child: Text('${m.codigo} — ${m.nome}'),
                      ),
                    ),
                  ],
                  onChanged: _onModuloChanged,
                ),
              if (_moduloEhRelatorios) ...[
                const SizedBox(height: 12),
                if (_loadingSubmodulos)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _relatorioSubmoduloId,
                    decoration: const InputDecoration(
                      labelText: 'Submódulo de relatório',
                    ),
                    hint: const Text('Selecione'),
                    items: _submodulos
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text('${s.codigo} — ${s.nome}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _relatorioSubmoduloId = v),
                    validator: (v) {
                      if (_moduloEhRelatorios &&
                          (v == null || v.isEmpty)) {
                        return 'Submódulo é obrigatório no módulo Relatórios';
                      }
                      return null;
                    },
                  ),
              ],
              if (widget.isEditing && widget.programa != null)
                AuditoriaSection(auditoria: widget.programa!.auditoria),
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
