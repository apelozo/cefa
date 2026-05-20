import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/campo_texto.dart';
import '../../models/pergunta.dart';
import '../../models/pergunta_opcao.dart';
import '../../models/tipo_campo.dart';
import '../../models/tipo_formulario.dart';
import '../../providers/api_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/pergunta_ordem.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import 'pergunta_opcoes_editor.dart';

class PerguntaFormScreen extends ConsumerStatefulWidget {
  const PerguntaFormScreen({super.key, this.pergunta});

  final Pergunta? pergunta;

  bool get isEditing => pergunta != null;

  @override
  ConsumerState<PerguntaFormScreen> createState() =>
      _PerguntaFormScreenState();
}

class _PerguntaFormScreenState extends ConsumerState<PerguntaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opcoesEditorKey = GlobalKey<PerguntaOpcoesEditorState>();
  late final TextEditingController _enunciadoController;
  late final TextEditingController _ordemController;
  late final TextEditingController _tamanhoController;
  late final TextEditingController _linhasController;
  late TipoCampo _tipoCampo;
  late bool _ativo;
  List<TipoFormulario> _tiposFormulario = [];
  List<PerguntaOpcao> _opcoesIniciais = [];
  List<Pergunta> _perguntasDoTipo = [];
  String? _tipoFormularioId;
  bool _loadingTipos = true;
  bool _loadingOpcoes = false;
  bool _saving = false;
  final _enunciadoFocus = FocusNode();
  final _tamanhoFocus = FocusNode();
  final _linhasFocus = FocusNode();
  final _ordemFocus = FocusNode();
  final _submitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tipoFormularioId = widget.pergunta?.tipoFormularioId;
    _opcoesIniciais = List.of(widget.pergunta?.opcoes ?? []);
    _loadTipos();
    if (widget.isEditing &&
        widget.pergunta!.tipoCampo == TipoCampo.lista &&
        _opcoesIniciais.isEmpty) {
      _loadPerguntaCompleta();
    }
    _enunciadoController =
        TextEditingController(text: widget.pergunta?.enunciado ?? '');
    _ordemController = TextEditingController(
      text: widget.isEditing
          ? widget.pergunta!.ordem.toString()
          : '',
    );
    _tamanhoController = TextEditingController(
      text: widget.pergunta?.tamanhoCampo?.toString() ??
          '${CampoTextoLimites.defaultTamanho}',
    );
    _linhasController = TextEditingController(
      text: widget.pergunta?.linhasCampo?.toString() ??
          '${CampoTextoLimites.defaultLinhas}',
    );
    _tipoCampo = widget.pergunta?.tipoCampo ?? TipoCampo.texto;
    _ativo = widget.pergunta?.ativo ?? true;
  }

  Future<void> _loadPerguntaCompleta() async {
    setState(() => _loadingOpcoes = true);
    try {
      final p =
          await ref.read(apiClientProvider).getPergunta(widget.pergunta!.id);
      if (mounted) {
        setState(() => _opcoesIniciais = List.of(p.opcoes));
        _opcoesEditorKey.currentState?.reloadFrom(_opcoesIniciais);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loadingOpcoes = false);
    }
  }

  Future<void> _carregarPerguntasDoTipo(String tipoId) async {
    try {
      final items = await ref
          .read(apiClientProvider)
          .listPerguntas(tipoFormularioId: tipoId);
      if (!mounted) return;
      setState(() => _perguntasDoTipo = items);
      if (!widget.isEditing) {
        _ordemController.text =
            proximaOrdemDisponivel(items).toString();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _loadTipos() async {
    try {
      final api = ref.read(apiClientProvider);
      var tipos = await api.listTiposFormulario();
      final currentId = widget.pergunta?.tipoFormularioId;
      if (currentId != null && !tipos.any((t) => t.id == currentId)) {
        final inativos = await api.listTiposFormulario(ativo: false);
        tipos = [...tipos, ...inativos.where((t) => t.id == currentId)];
      }
      if (mounted) {
        final tipoId = currentId ?? (tipos.isNotEmpty ? tipos.first.id : null);
        setState(() {
          _tiposFormulario = tipos;
          _tipoFormularioId = tipoId;
          _loadingTipos = false;
        });
        if (tipoId != null) {
          await _carregarPerguntasDoTipo(tipoId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTipos = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enunciadoFocus.dispose();
    _tamanhoFocus.dispose();
    _linhasFocus.dispose();
    _ordemFocus.dispose();
    _submitFocus.dispose();
    _enunciadoController.dispose();
    _ordemController.dispose();
    _tamanhoController.dispose();
    _linhasController.dispose();
    super.dispose();
  }

  void _focusAfterEnunciado() {
    if (_tipoCampo == TipoCampo.texto) {
      _tamanhoFocus.requestFocus();
    } else if (_tipoCampo == TipoCampo.lista) {
      _opcoesEditorKey.currentState?.requestFocusFirst();
    } else {
      _ordemFocus.requestFocus();
    }
  }

  void _focusAfterTamanho() {
    _linhasFocus.requestFocus();
  }

  void _focusAfterLinhas() {
    if (_tipoCampo == TipoCampo.lista) {
      _opcoesEditorKey.currentState?.requestFocusFirst();
    } else {
      _ordemFocus.requestFocus();
    }
  }

  int? _parseTamanho() {
    if (_tipoCampo != TipoCampo.texto) return null;
    return int.parse(_tamanhoController.text);
  }

  int? _parseLinhas() {
    if (_tipoCampo != TipoCampo.texto) return null;
    return int.parse(_linhasController.text);
  }

  List<PerguntaOpcao> _opcoesParaEnvio() {
    final coletadas =
        _opcoesEditorKey.currentState?.collectOpcoes() ?? _opcoesIniciais;
    return coletadas
        .where(
          (o) =>
              o.rotulo.isNotEmpty ||
              (o.id != null && o.id!.isNotEmpty),
        )
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoCampo == TipoCampo.lista) {
      final editor = _opcoesEditorKey.currentState;
      if (editor == null || !editor.validateOpcoes()) {
        showErrorSnackBar(
          context,
          'Informe ao menos uma opção ativa com texto',
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final ordem = int.parse(_ordemController.text);
      final enunciado = _enunciadoController.text.trim();
      final tamanho = _parseTamanho();
      final linhas = _parseLinhas();
      final List<PerguntaOpcao> opcoes =
          _tipoCampo == TipoCampo.lista ? _opcoesParaEnvio() : [];

      if (_tipoFormularioId == null) {
        showErrorSnackBar(context, 'Selecione o tipo de formulário');
        return;
      }

      if (widget.isEditing) {
        final p = widget.pergunta!;
        await api.updatePergunta(
          Pergunta(
            id: p.id,
            enunciado: enunciado,
            tipoCampo: _tipoCampo,
            tamanhoCampo: tamanho,
            linhasCampo: linhas,
            tipoFormularioId: _tipoFormularioId!,
            ordem: ordem,
            ativo: _ativo,
            createdAt: p.createdAt,
            opcoes: opcoes,
          ),
        );
      } else {
        await api.createPergunta(
          Pergunta(
            id: '',
            enunciado: enunciado,
            tipoCampo: _tipoCampo,
            tamanhoCampo: tamanho,
            linhasCampo: linhas,
            tipoFormularioId: _tipoFormularioId!,
            ordem: ordem,
            ativo: _ativo,
            createdAt: DateTime.now(),
            opcoes: opcoes,
          ),
        );
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isEditing ? 'Pergunta atualizada' : 'Pergunta criada',
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
        title: widget.isEditing ? 'Editar pergunta' : 'Nova pergunta',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            TextFormField(
              controller: _enunciadoController,
              focusNode: _enunciadoFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _focusAfterEnunciado(),
              decoration: const InputDecoration(labelText: 'Enunciado'),
              maxLines: 3,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Informe o enunciado';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_loadingTipos)
              const LinearProgressIndicator()
            else if (_tiposFormulario.isEmpty)
              Text(
                'Cadastre um tipo de formulário antes de criar perguntas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'tf_${_tipoFormularioId}_${_tiposFormulario.length}',
                ),
                initialValue: _tipoFormularioId != null &&
                        _tiposFormulario.any((t) => t.id == _tipoFormularioId)
                    ? _tipoFormularioId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Tipo de formulário',
                ),
                items: _tiposFormulario
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.nome),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _tipoFormularioId = v);
                  _carregarPerguntasDoTipo(v);
                },
                validator: (v) =>
                    v == null ? 'Selecione o tipo de formulário' : null,
              ),
            const SizedBox(height: 24),
            DropdownButtonFormField<TipoCampo>(
              key: ValueKey(_tipoCampo),
              initialValue: _tipoCampo,
              decoration: const InputDecoration(labelText: 'Tipo do campo'),
              items: TipoCampo.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: widget.isEditing
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _tipoCampo = v;
                        if (v == TipoCampo.lista && _opcoesIniciais.isEmpty) {
                          _opcoesIniciais = [
                            PerguntaOpcao(
                              rotulo: '',
                              ordem: 0,
                              ativo: true,
                            ),
                          ];
                        }
                      });
                    },
            ),
            if (widget.isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'O tipo não pode ser alterado após existirem respostas.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_tipoCampo == TipoCampo.texto) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _tamanhoController,
                focusNode: _tamanhoFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusAfterTamanho(),
                onEditingComplete: _focusAfterTamanho,
                decoration: const InputDecoration(
                  labelText: 'Tamanho do texto (caracteres)',
                  helperText: 'Máximo permitido no formulário',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (_tipoCampo != TipoCampo.texto) return null;
                  if (v == null || v.isEmpty) return 'Informe o tamanho';
                  final n = int.tryParse(v);
                  if (n == null ||
                      n < CampoTextoLimites.minTamanho ||
                      n > CampoTextoLimites.maxTamanho) {
                    return 'Entre ${CampoTextoLimites.minTamanho} e ${CampoTextoLimites.maxTamanho}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linhasController,
                focusNode: _linhasFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusAfterLinhas(),
                onEditingComplete: _focusAfterLinhas,
                decoration: const InputDecoration(
                  labelText: 'Linhas no lançamento',
                  helperText: 'Altura do campo ao responder o formulário',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (_tipoCampo != TipoCampo.texto) return null;
                  if (v == null || v.isEmpty) return 'Informe a quantidade de linhas';
                  final n = int.tryParse(v);
                  if (n == null ||
                      n < CampoTextoLimites.minLinhas ||
                      n > CampoTextoLimites.maxLinhas) {
                    return 'Entre ${CampoTextoLimites.minLinhas} e ${CampoTextoLimites.maxLinhas}';
                  }
                  return null;
                },
              ),
            ],
            if (_tipoCampo == TipoCampo.lista) ...[
              const SizedBox(height: 16),
              if (_loadingOpcoes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(),
                )
              else
                PerguntaOpcoesEditor(
                  key: _opcoesEditorKey,
                  initialOpcoes: _opcoesIniciais,
                  focusAfterLast: _ordemFocus,
                ),
            ],
            if (_tipoCampo == TipoCampo.inteiro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Inteiro: até 9 dígitos (Int).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_tipoCampo == TipoCampo.data)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Data: formato dd/mm/aa (ex.: 20/10/26 → 20/10/2026).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _ordemController,
              focusNode: _ordemFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitFocus.requestFocus(),
              onEditingComplete: () => _submitFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'Ordem',
                helperText: widget.isEditing
                    ? 'Não pode repetir a ordem de outra pergunta deste formulário'
                    : 'Próxima ordem disponível sugerida automaticamente',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a ordem';
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Ordem inválida';
                if (ordemDuplicada(
                  perguntas: _perguntasDoTipo,
                  ordem: n,
                  excluirPerguntaId: widget.pergunta?.id,
                )) {
                  return 'Já existe outra pergunta com esta ordem neste formulário';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativa'),
              subtitle: const Text(
                'Perguntas inativas não aparecem no formulário',
              ),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: widget.isEditing ? 'Salvar' : 'Criar',
              focusNode: _submitFocus,
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
