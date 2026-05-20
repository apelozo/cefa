import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/campo_texto.dart';
import '../../models/pergunta.dart';
import '../../models/pessoa.dart';
import '../../models/submissao.dart';
import '../../models/tipo_campo.dart';
import '../../models/tipo_formulario.dart';
import '../../auth/programas.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_layout.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../formulario/campo_input.dart';
import '../formulario/confirmacao_screen.dart';

class LancamentoFormularioScreen extends ConsumerStatefulWidget {
  const LancamentoFormularioScreen({
    super.key,
    required this.tipo,
    required this.pessoa,
  });

  final TipoFormulario tipo;
  final Pessoa pessoa;

  @override
  ConsumerState<LancamentoFormularioScreen> createState() =>
      _LancamentoFormularioScreenState();
}

class _LancamentoFormularioScreenState
    extends ConsumerState<LancamentoFormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Pergunta>? _perguntas;
  bool _loading = true;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, bool?> _logicoValues = {};
  final Map<String, String?> _listaValues = {};
  final _submitFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    _submitFocusNode.dispose();
    super.dispose();
  }

  List<FocusNode> get _orderedFocusNodes {
    if (_perguntas == null) return [];
    return _perguntas!
        .where((p) {
          if (p.tipoCampo == TipoCampo.logico ||
              p.tipoCampo == TipoCampo.lista) {
            return false;
          }
          if (p.tipoCampo == TipoCampo.texto) {
            final linhas =
                p.linhasCampo ?? CampoTextoLimites.defaultLinhas;
            if (linhas > 1) return false;
          }
          return true;
        })
        .map((p) => _focusNodes[p.id]!)
        .toList();
  }

  TextInputAction _inputActionFor(Pergunta p) {
    final ordered = _orderedFocusNodes;
    final node = _focusNodes[p.id];
    if (node == null) return TextInputAction.done;
    final index = ordered.indexOf(node);
    if (index < 0 || index < ordered.length - 1) {
      return TextInputAction.next;
    }
    return TextInputAction.done;
  }

  void _onFieldSubmitted(Pergunta p) {
    final node = _focusNodes[p.id];
    if (node == null) return;
    FormEnterFocus.chainSubmit(
      orderedFields: _orderedFocusNodes,
      current: node,
      submitFocusNode: _submitFocusNode,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final items = await api.listPerguntas(
        ativo: true,
        tipoFormularioId: widget.tipo.id,
        opcoesAtivas: true,
      );
      for (final n in _focusNodes.values) {
        n.dispose();
      }
      _focusNodes.clear();
      for (final p in items) {
        if (p.tipoCampo != TipoCampo.logico) {
          _controllers.putIfAbsent(p.id, TextEditingController.new);
          _focusNodes[p.id] = FocusNode();
        }
      }
      if (mounted) setState(() => _perguntas = items);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  RespostaItem? _tryBuildResposta(Pergunta p) {
    switch (p.tipoCampo) {
      case TipoCampo.inteiro:
        final t = _controllers[p.id]!.text.trim();
        if (t.isEmpty) return null;
        return RespostaItem(perguntaId: p.id, valorInteiro: int.parse(t));
      case TipoCampo.decimal:
        final t = _controllers[p.id]!.text.trim();
        if (t.isEmpty) return null;
        return RespostaItem(
          perguntaId: p.id,
          valorDecimal: t.replaceAll(',', '.'),
        );
      case TipoCampo.texto:
        final t = _controllers[p.id]!.text.trim();
        if (t.isEmpty) return null;
        return RespostaItem(perguntaId: p.id, valorTexto: t);
      case TipoCampo.logico:
        final v = _logicoValues[p.id];
        if (v == null) return null;
        return RespostaItem(perguntaId: p.id, valorLogico: v);
      case TipoCampo.data:
        final t = _controllers[p.id]!.text.trim();
        if (t.isEmpty) return null;
        return RespostaItem(
          perguntaId: p.id,
          valorData: normalizarDataBr(t),
        );
      case TipoCampo.lista:
        final id = _listaValues[p.id];
        if (id == null || id.isEmpty) return null;
        return RespostaItem(perguntaId: p.id, valorOpcaoId: id);
    }
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;

    final respostas = _perguntas!
        .map(_tryBuildResposta)
        .whereType<RespostaItem>()
        .toList();
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConfirmacaoScreen(
          tipoFormularioId: widget.tipo.id,
          tipoFormularioNome: widget.tipo.nome,
          pessoaId: widget.pessoa.id,
          pessoaNome: widget.pessoa.nome,
          perguntas: _perguntas!,
          respostas: respostas,
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.tipo.nome,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _perguntas == null || _perguntas!.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppLayout.screenPadding,
                    child: Text(
                      'Nenhuma pergunta ativa neste formulário.\nCadastre perguntas vinculadas a "${widget.tipo.nome}".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.screenPaddingH,
                        AppLayout.screenPaddingTop,
                        AppLayout.screenPaddingH,
                        0,
                      ),
                      child: Text(
                        'Pessoa: ${widget.pessoa.nome}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: AppScreenChrome.whiteTopSheet(),
                        child: Form(
                          key: _formKey,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppLayout.screenPaddingH,
                              20,
                              AppLayout.screenPaddingH,
                              16,
                            ),
                            itemCount: _perguntas!.length,
                            itemBuilder: (context, index) {
                              final p = _perguntas![index];
                              return AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.enunciado,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    CampoInput(
                                      pergunta: p,
                                      respostaOpcional: true,
                                      textController: _controllers[p.id],
                                      focusNode: _focusNodes[p.id],
                                      textInputAction: _inputActionFor(p),
                                      onFieldSubmitted: p.tipoCampo !=
                                              TipoCampo.logico
                                          ? (_) => _onFieldSubmitted(p)
                                          : null,
                                      logicoValue: _logicoValues[p.id],
                                      onLogicoChanged: (v) => setState(
                                        () => _logicoValues[p.id] = v,
                                      ),
                                      listaValue: _listaValues[p.id],
                                      onListaChanged: (v) => setState(
                                        () => _listaValues[p.id] = v,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: AppLayout.screenPaddingSymmetricH.copyWith(
                          top: 12,
                          bottom: AppLayout.screenPaddingBottom,
                        ),
                        child: AppButton(
                          label: 'Revisar e enviar',
                          focusNode: _submitFocusNode,
                          onPressed: ref.watch(authProvider).podeIncluir(
                                Programas.lancamento,
                              )
                              ? _review
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
