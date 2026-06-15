import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../models/entrevista_composicao_familiar.dart';
import '../../models/entrevista_condicao_educacional.dart';
import '../../models/entrevista_condicao_trabalho.dart';
import '../../models/entrevista_deficiencia_familiar.dart';
import '../../models/entrevista_gestante_familiar.dart';
import '../../constants/resposta_sim_nao.dart';
import '../../models/entrevista_assistido.dart';
import '../../models/entrevista_programas_sociais.dart';
import '../../models/escolaridade.dart';
import '../../models/forma_acesso_instituicao.dart';
import '../../models/pessoa.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/data_br_hoje.dart';
import '../../utils/moeda_br.dart';
import '../../utils/entrevista_pdf.dart';
import '../../utils/snackbar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/auditoria_section.dart';
import '../../widgets/permissao_gate.dart';
import '../pessoas/pessoas_search_args.dart';
import '../pessoas/pessoas_search_screen.dart';
import 'entrevista_composicao_familiar_tab.dart';
import 'entrevista_programas_sociais_tab.dart';
import 'entrevista_condicao_educacional_tab.dart';
import 'entrevista_condicao_saude_tab.dart';
import 'entrevista_condicao_trabalho_tab.dart';
import 'entrevista_focus.dart';
import 'entrevista_form_linhas.dart';
import 'entrevista_text_field.dart';

class EntrevistaAssistidoScreen extends ConsumerStatefulWidget {
  const EntrevistaAssistidoScreen({
    super.key,
    this.entrevistaId,
    this.readOnly = false,
  });

  final String? entrevistaId;
  final bool readOnly;

  bool get isEdicao => entrevistaId != null;

  @override
  ConsumerState<EntrevistaAssistidoScreen> createState() =>
      _EntrevistaAssistidoScreenState();
}

class _EntrevistaAssistidoScreenState
    extends ConsumerState<EntrevistaAssistidoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;
  late final TextEditingController _dataController;
  late final FocusNode _dataEntrevistaFocusNode;
  late final FocusNode _submitFocusNode;
  late final TextEditingController _outrosController;
  late final TextEditingController _outrosProgramasSociaisController;
  late final TextEditingController _outrosOrgaosSociaisController;
  final Set<FormaAcessoInstituicao> _formasSelecionadas = {};
  bool _bolsaFamilia = false;
  bool _peti = false;
  bool _bpc = false;
  bool _outrosProgramas = false;
  bool _cras = false;
  bool _centroPop = false;
  bool _conselhoTutelar = false;
  bool _ubs = false;
  bool _creas = false;
  bool _caps = false;
  bool _craf = false;
  bool _outrosAtendimentoFamilia = false;
  final List<ComposicaoFamiliarLinha> _composicaoLinhas = [];
  final List<CondicaoTrabalhoLinha> _trabalhoLinhas = [];
  final List<CondicaoEducacionalLinha> _educacionalLinhas = [];
  final List<DeficienciaFamiliarLinha> _deficienciaLinhas = [];
  final List<GestanteFamiliarLinha> _gestanteLinhas = [];
  late SaudeFamiliaForm _saudeFamilia;
  Pessoa? _pessoa;
  EntrevistaAssistido? _entrevistaCarregada;
  List<Escolaridade> _escolaridades = [];
  bool _submitting = false;
  bool _loading = true;
  bool _exportandoPdf = false;

  bool get _readOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _saudeFamilia = SaudeFamiliaForm();
    _dataController = TextEditingController(text: dataBrHoje4Anos());
    _dataEntrevistaFocusNode = FocusNode();
    _submitFocusNode = FocusNode();
    _dataEntrevistaFocusNode.addListener(_onDataEntrevistaFocusChange);
    _outrosController = TextEditingController();
    _outrosProgramasSociaisController = TextEditingController();
    _outrosOrgaosSociaisController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dataEntrevistaFocusNode.removeListener(_onDataEntrevistaFocusChange);
    _dataEntrevistaFocusNode.dispose();
    _submitFocusNode.dispose();
    _dataController.dispose();
    _outrosController.dispose();
    _outrosProgramasSociaisController.dispose();
    _outrosOrgaosSociaisController.dispose();
    for (final linha in _composicaoLinhas) {
      linha.dispose();
    }
    for (final linha in _trabalhoLinhas) {
      linha.dispose();
    }
    for (final linha in _educacionalLinhas) {
      linha.dispose();
    }
    for (final linha in _deficienciaLinhas) {
      linha.dispose();
    }
    for (final linha in _gestanteLinhas) {
      linha.dispose();
    }
    _saudeFamilia.dispose();
    super.dispose();
  }

  Future<void> _carregarEscolaridades({List<int>? codigosExtras}) async {
    try {
      final items =
          await ref.read(apiClientProvider).listEscolaridades(ativo: true);
      final merged = [...items];
      for (final codigo in codigosExtras ?? const <int>[]) {
        if (merged.any((e) => e.codigo == codigo)) continue;
        final extra = await ref
            .read(apiClientProvider)
            .listEscolaridades(codigo: codigo);
        merged.addAll(extra);
      }
      merged.sort((a, b) => a.descricao.compareTo(b.descricao));
      if (mounted) setState(() => _escolaridades = merged);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _inicializar() async {
    if (widget.entrevistaId != null) {
      await _carregarEntrevista(widget.entrevistaId!);
      return;
    }
    if (!_readOnly) {
      await _carregarEscolaridades();
    }
    await _selecionarPessoa();
  }

  Future<void> _carregarEntrevista(String id) async {
    try {
      final entrevista =
          await ref.read(apiClientProvider).getEntrevistaAssistido(id);
      if (!mounted) return;

      _dataController.text =
          formatarDataBrExibicao4Anos(entrevista.dataEntrevista);
      _outrosController.text = entrevista.outrosTexto ?? '';
      _formasSelecionadas.clear();
      for (final f in entrevista.formasAcesso) {
        final forma = FormaAcessoInstituicao.fromApi(f.formaAcesso);
        if (forma != null) _formasSelecionadas.add(forma);
      }

      final ps = entrevista.programasSociais;
      _bolsaFamilia = ps.bolsaFamilia;
      _peti = ps.peti;
      _bpc = ps.bpc;
      _outrosProgramas = ps.outrosProgramas;
      _outrosProgramasSociaisController.text =
          ps.outrosProgramasSociais ?? '';
      _cras = ps.cras;
      _centroPop = ps.centroPop;
      _conselhoTutelar = ps.conselhoTutelar;
      _ubs = ps.ubs;
      _creas = ps.creas;
      _caps = ps.caps;
      _craf = ps.craf;
      _outrosAtendimentoFamilia = ps.outrosAtendimentoFamilia;
      _outrosOrgaosSociaisController.text = ps.outrosOrgaosSociais ?? '';

      for (final item in entrevista.condicoesTrabalho) {
        _trabalhoLinhas.add(CondicaoTrabalhoLinha.fromItem(item));
      }
      for (final item in entrevista.condicoesEducacionais) {
        _educacionalLinhas.add(CondicaoEducacionalLinha.fromItem(item));
      }
      for (final item in entrevista.deficienciasFamilia) {
        _deficienciaLinhas.add(DeficienciaFamiliarLinha.fromItem(item));
      }
      for (final item in entrevista.gestantesFamilia) {
        _gestanteLinhas.add(GestanteFamiliarLinha.fromItem(item));
      }
      _saudeFamilia.dispose();
      _saudeFamilia = SaudeFamiliaForm.fromEntrevista(entrevista.saudeFamilia);
      for (final item in entrevista.composicaoFamiliar) {
        final comp = ComposicaoFamiliarLinha.fromItem(item);
        final nome = item.nome.trim();
        CondicaoTrabalhoLinha? vinculadaTrab;
        for (final trab in _trabalhoLinhas) {
          if (trab.nomeSelecionado?.trim() == nome) {
            vinculadaTrab = trab;
            break;
          }
        }
        if (vinculadaTrab == null) {
          vinculadaTrab = CondicaoTrabalhoLinha()
            ..nomeSelecionado = nome.isNotEmpty ? nome : null;
          _trabalhoLinhas.add(vinculadaTrab);
        }
        comp.linhaTrabalhoVinculada = vinculadaTrab;

        CondicaoEducacionalLinha? vinculadaEduc;
        for (final educ in _educacionalLinhas) {
          if (educ.nomeSelecionado?.trim() == nome) {
            vinculadaEduc = educ;
            break;
          }
        }
        if (vinculadaEduc == null) {
          vinculadaEduc = CondicaoEducacionalLinha()
            ..nomeSelecionado = nome.isNotEmpty ? nome : null;
          _educacionalLinhas.add(vinculadaEduc);
        }
        comp.linhaEducacionalVinculada = vinculadaEduc;
        _composicaoLinhas.add(comp);
      }

      Pessoa? pessoaPdf = entrevista.pessoaCompleta;
      if (pessoaPdf == null || pessoaPdf.dtNascimento.isEmpty) {
        pessoaPdf = await ref.read(apiClientProvider).getPessoa(entrevista.pessoaId);
      }

      setState(() {
        _entrevistaCarregada = entrevista;
        _pessoa = pessoaPdf;
        _loading = false;
      });
      if (!_readOnly) {
        await _carregarEscolaridades(
          codigosExtras: entrevista.condicoesEducacionais
              .map((c) => c.escolaridadeCodigo)
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e.toString());
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _selecionarPessoa() async {
    final pessoa = await PessoasSearchScreen.select(
      context,
      args: const PessoasSearchArgs(
        title: 'Assistido da entrevista',
        subtitle: 'Entrevista com o Assistido',
        onlyAtivas: true,
      ),
    );
    if (!mounted) return;
    if (pessoa == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _pessoa = pessoa;
      _loading = false;
    });
  }

  List<String> get _nomesFamilia {
    final nomes = <String>[];
    final assistido = _pessoa?.nome.trim() ?? '';
    if (assistido.isNotEmpty) nomes.add(assistido);
    for (final linha in _composicaoLinhas) {
      final n = linha.nome.text.trim();
      if (n.isNotEmpty && !nomes.contains(n)) nomes.add(n);
    }
    return nomes;
  }

  int get _quantidadePessoasComposicao {
    return _composicaoLinhas.where((l) => l.preenchida).length;
  }

  void _adicionarComposicao() {
    setState(() {
      final comp = ComposicaoFamiliarLinha();
      final trab = CondicaoTrabalhoLinha();
      final educ = CondicaoEducacionalLinha();
      comp.linhaTrabalhoVinculada = trab;
      comp.linhaEducacionalVinculada = educ;
      _composicaoLinhas.add(comp);
      _trabalhoLinhas.add(trab);
      _educacionalLinhas.add(educ);
    });
  }

  void _syncLinhasVinculadasFromComposicao(int index) {
    final comp = _composicaoLinhas[index];
    final nome = comp.nome.text.trim();
    if (nome.isEmpty) return;
    final trab = comp.linhaTrabalhoVinculada;
    if (trab != null) {
      trab.nomeSelecionado = nome;
    }
    final educ = comp.linhaEducacionalVinculada;
    if (educ != null) {
      educ.nomeSelecionado = nome;
    }
  }

  void _onComposicaoChanged(int index) {
    _syncLinhasVinculadasFromComposicao(index);
    _refreshForm();
  }

  void _removerComposicao(int index) {
    setState(() {
      final comp = _composicaoLinhas[index];
      final vinculadaTrab = comp.linhaTrabalhoVinculada;
      final vinculadaEduc = comp.linhaEducacionalVinculada;
      comp.dispose();
      _composicaoLinhas.removeAt(index);
      if (vinculadaTrab != null) {
        _trabalhoLinhas.remove(vinculadaTrab);
        vinculadaTrab.dispose();
      }
      if (vinculadaEduc != null) {
        _educacionalLinhas.remove(vinculadaEduc);
        vinculadaEduc.dispose();
      }
    });
  }

  void _adicionarTrabalho() {
    setState(() => _trabalhoLinhas.add(CondicaoTrabalhoLinha()));
  }

  void _removerTrabalho(int index) {
    setState(() {
      _trabalhoLinhas[index].dispose();
      _trabalhoLinhas.removeAt(index);
    });
  }

  void _adicionarEducacional() {
    setState(() => _educacionalLinhas.add(CondicaoEducacionalLinha()));
  }

  void _removerEducacional(int index) {
    setState(() {
      _educacionalLinhas[index].dispose();
      _educacionalLinhas.removeAt(index);
    });
  }

  void _adicionarDeficiencia() {
    setState(() => _deficienciaLinhas.add(DeficienciaFamiliarLinha()));
  }

  void _removerDeficiencia(int index) {
    setState(() {
      _deficienciaLinhas[index].dispose();
      _deficienciaLinhas.removeAt(index);
    });
  }

  void _adicionarGestante() {
    setState(() => _gestanteLinhas.add(GestanteFamiliarLinha()));
  }

  void _removerGestante(int index) {
    setState(() {
      _gestanteLinhas[index].dispose();
      _gestanteLinhas.removeAt(index);
    });
  }

  void _limparGestantes() {
    setState(() {
      for (final linha in _gestanteLinhas) {
        linha.dispose();
      }
      _gestanteLinhas.clear();
    });
  }

  void _refreshForm() => setState(() {});

  void _onDataEntrevistaFocusChange() {
    if (!_dataEntrevistaFocusNode.hasFocus) {
      _aplicarMascaraDataEntrevista4Anos();
    }
  }

  void _aplicarMascaraDataEntrevista4Anos() {
    final texto = _dataController.text.trim();
    if (texto.isEmpty) return;
    final formatado = formatarDataBrExibicao4Anos(texto);
    if (formatado != _dataController.text) {
      _dataController.text = formatado;
      _dataController.selection =
          TextSelection.collapsed(offset: formatado.length);
    }
  }

  void _advanceFromData() {
    if (_readOnly) return;
    _aplicarMascaraDataEntrevista4Anos();
    _tabController.animateTo(1);
    _advanceAfterProgramasSociais();
  }

  void _advanceAfterProgramasSociais() {
    if (_readOnly) return;
    if (_composicaoLinhas.isNotEmpty) {
      _tabController.animateTo(2);
      EntrevistaFocus.advance(_composicaoLinhas.first.focusNome);
      return;
    }
    _advanceAfterComposicao();
  }

  void _advanceAfterComposicao() {
    if (_readOnly) return;
    if (_trabalhoLinhas.isNotEmpty) {
      _tabController.animateTo(3);
      EntrevistaFocus.advance(_trabalhoLinhas.first.focusVrBeneficioSocial);
      return;
    }
    _advanceAfterTrabalho();
  }

  void _advanceAfterTrabalho() {
    if (_readOnly) return;
    if (_educacionalLinhas.isNotEmpty) {
      _tabController.animateTo(4);
      EntrevistaFocus.advance(_educacionalLinhas.first.focusIdade);
      return;
    }
    _advanceAfterEducacional();
  }

  void _advanceAfterEducacional() {
    if (_readOnly) return;
    final s = _saudeFamilia;
    if (s.temGestante == RespostaSimNao.sim && _gestanteLinhas.isNotEmpty) {
      _tabController.animateTo(5);
      return;
    }
    _advanceToSubmit();
  }

  void _advanceToSubmit() {
    if (_readOnly) return;
    EntrevistaFocus.advance(_submitFocusNode);
  }

  void _toggleForma(FormaAcessoInstituicao forma, bool? selected) {
    if (_readOnly) return;
    setState(() {
      if (selected == true) {
        _formasSelecionadas.add(forma);
      } else {
        _formasSelecionadas.remove(forma);
        if (forma == FormaAcessoInstituicao.outros) {
          _outrosController.clear();
        }
      }
    });
  }

  String? _validarFormas() {
    if (_formasSelecionadas.isEmpty) {
      return 'Selecione ao menos uma forma de acesso';
    }
    if (_formasSelecionadas.contains(FormaAcessoInstituicao.outros) &&
        _outrosController.text.trim().isEmpty) {
      return 'Informe a descrição quando selecionar Outros';
    }
    return null;
  }

  String? _validarProgramasSociais() {
    if (_outrosProgramas &&
        _outrosProgramasSociaisController.text.trim().isEmpty) {
      return 'Informe a descrição quando selecionar Outros Programas';
    }
    if (_outrosAtendimentoFamilia &&
        _outrosOrgaosSociaisController.text.trim().isEmpty) {
      return 'Informe a descrição quando selecionar Outros órgãos';
    }
    return null;
  }

  EntrevistaProgramasSociais _programasSociaisModel() {
    return EntrevistaProgramasSociais(
      bolsaFamilia: _bolsaFamilia,
      peti: _peti,
      bpc: _bpc,
      outrosProgramas: _outrosProgramas,
      outrosProgramasSociais: _outrosProgramas
          ? _outrosProgramasSociaisController.text.trim()
          : null,
      cras: _cras,
      centroPop: _centroPop,
      conselhoTutelar: _conselhoTutelar,
      ubs: _ubs,
      creas: _creas,
      caps: _caps,
      craf: _craf,
      outrosAtendimentoFamilia: _outrosAtendimentoFamilia,
      outrosOrgaosSociais: _outrosAtendimentoFamilia
          ? _outrosOrgaosSociaisController.text.trim()
          : null,
    );
  }

  Future<void> _salvar() async {
    if (_pessoa == null) {
      showErrorSnackBar(context, 'Selecione o assistido');
      return;
    }

    _composicaoLinhas.removeWhere((l) => l.completamenteVazia);
    _trabalhoLinhas.removeWhere((l) => l.completamenteVazia);
    _educacionalLinhas.removeWhere((l) => l.completamenteVazia);
    _deficienciaLinhas.removeWhere((l) => l.completamenteVazia);
    _gestanteLinhas.removeWhere((l) => l.completamenteVazia);

    if (!_formKey.currentState!.validate()) return;

    final erroFormas = _validarFormas();
    if (erroFormas != null) {
      showErrorSnackBar(context, erroFormas);
      return;
    }

    final erroProgramas = _validarProgramasSociais();
    if (erroProgramas != null) {
      showErrorSnackBar(context, erroProgramas);
      return;
    }

    final composicao = <EntrevistaComposicaoFamiliar>[];
    for (final linha in _composicaoLinhas) {
      final item = linha.toModel();
      if (item == null) {
        showErrorSnackBar(
          context,
          'Preencha todos os campos dos integrantes da composição familiar',
        );
        return;
      }
      composicao.add(item);
    }

    for (final linha in _trabalhoLinhas) {
      formatarMoedaBrNoController(linha.vrBeneficioSocial);
      formatarMoedaBrNoController(linha.rendaMensal);
    }

    final condicoes = <EntrevistaCondicaoTrabalho>[];
    for (final linha in _trabalhoLinhas) {
      final item = linha.toModel();
      if (item == null) {
        showErrorSnackBar(
          context,
          'Em condições de trabalho, informe nome e ocupação em cada linha',
        );
        return;
      }
      condicoes.add(item);
    }

    final educacionais = <EntrevistaCondicaoEducacional>[];
    for (final linha in _educacionalLinhas) {
      final item = linha.toModel();
      if (item == null) {
        showErrorSnackBar(
          context,
          'Em condições educacionais, informe nome, idade e escolaridade em cada linha',
        );
        return;
      }
      educacionais.add(item);
    }

    final deficiencias = <EntrevistaDeficienciaFamiliar>[];
    for (final linha in _deficienciaLinhas) {
      final item = linha.toModel();
      if (item == null) {
        showErrorSnackBar(
          context,
          'Em condições de saúde, informe nome e tipo de deficiência em cada registro',
        );
        return;
      }
      deficiencias.add(item);
    }

    final s = _saudeFamilia;
    if (s.remediosControladosMental == RespostaSimNao.sim &&
        s.remediosControladosQuais.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Informe quais remédios controlados');
      return;
    }
    if (s.usoAbusivoDrogas == RespostaSimNao.sim &&
        s.usoAbusivoDrogasQuais.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Informe quais drogas');
      return;
    }
    final gestantes = <EntrevistaGestanteFamiliar>[];
    if (s.temGestante == RespostaSimNao.sim) {
      for (final linha in _gestanteLinhas) {
        final item = linha.toModel();
        if (item == null) {
          showErrorSnackBar(
            context,
            'Em gestantes, informe nome, meses de gestação (0 a 10) e pré-natal em cada registro',
          );
          return;
        }
        gestantes.add(item);
      }
      if (gestantes.isEmpty) {
        showErrorSnackBar(
          context,
          'Informe ao menos uma gestante na família',
        );
        return;
      }
    }

    final programasSociaisJson = _programasSociaisModel().toJson();
    final saudeFamiliaJson = _saudeFamilia.toModel().toJson();

    final auth = ref.read(authProvider);
    final isEdicao = widget.isEdicao;
    if (isEdicao && !auth.podeAlterar(Programas.entrevistaAssistido)) {
      showErrorSnackBar(context, 'Sem permissão para alterar entrevistas');
      return;
    }
    if (!isEdicao && !auth.podeIncluir(Programas.entrevistaAssistido)) {
      showErrorSnackBar(context, 'Sem permissão para registrar entrevistas');
      return;
    }

    final body = (
      pessoaId: _pessoa!.id,
      dataEntrevista: normalizarDataBr(_dataController.text.trim()),
      formasAcesso: _formasSelecionadas.map((f) => f.apiValue).toList(),
      outrosTexto: _formasSelecionadas.contains(FormaAcessoInstituicao.outros)
          ? _outrosController.text.trim()
          : null,
      composicaoFamiliar: composicao.map((c) => c.toJson()).toList(),
      condicoesTrabalho: condicoes.map((c) => c.toJson()).toList(),
      condicoesEducacionais: educacionais.map((c) => c.toJson()).toList(),
      deficienciasFamilia: deficiencias.map((d) => d.toJson()).toList(),
      gestantesFamilia: gestantes.map((g) => g.toJson()).toList(),
      programasSociais: programasSociaisJson,
      saudeFamilia: saudeFamiliaJson,
    );

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      if (isEdicao) {
        await api.updateEntrevistaAssistido(
          id: widget.entrevistaId!,
          pessoaId: body.pessoaId,
          dataEntrevista: body.dataEntrevista,
          formasAcesso: body.formasAcesso,
          outrosTexto: body.outrosTexto,
          composicaoFamiliar: body.composicaoFamiliar,
          condicoesTrabalho: body.condicoesTrabalho,
          condicoesEducacionais: body.condicoesEducacionais,
          deficienciasFamilia: body.deficienciasFamilia,
          gestantesFamilia: body.gestantesFamilia,
          programasSociais: body.programasSociais,
          saudeFamilia: body.saudeFamilia,
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Entrevista atualizada com sucesso');
          Navigator.pop(context, true);
        }
      } else {
        await api.createEntrevistaAssistido(
          pessoaId: body.pessoaId,
          dataEntrevista: body.dataEntrevista,
          formasAcesso: body.formasAcesso,
          outrosTexto: body.outrosTexto,
          composicaoFamiliar: body.composicaoFamiliar,
          condicoesTrabalho: body.condicoesTrabalho,
          condicoesEducacionais: body.condicoesEducacionais,
          deficienciasFamilia: body.deficienciasFamilia,
          gestantesFamilia: body.gestantesFamilia,
          programasSociais: body.programasSociais,
          saudeFamilia: body.saudeFamilia,
        );
        if (mounted) {
          showSuccessSnackBar(context, 'Entrevista registrada com sucesso');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _titulo {
    if (_readOnly) return 'Consultar entrevista';
    if (widget.isEdicao) return 'Alterar entrevista';
    return 'Nova entrevista';
  }

  Future<void> _gerarPdf({required bool visualizar}) async {
    final pessoa = _pessoa;
    if (pessoa == null || _exportandoPdf) return;

    setState(() => _exportandoPdf = true);
    try {
      EntrevistaAssistido entrevista;
      if (widget.entrevistaId != null) {
        entrevista = await ref
            .read(apiClientProvider)
            .getEntrevistaAssistido(widget.entrevistaId!);
      } else {
        final carregada = _entrevistaCarregada;
        if (carregada == null) return;
        entrevista = carregada;
      }
      // Garante programas sociais iguais à tela (checkboxes / textos atuais).
      entrevista = entrevista.copyWith(
        programasSociais: _programasSociaisModel(),
      );

      if (visualizar) {
        await EntrevistaPdf.visualizar(entrevista, pessoa);
      } else {
        await EntrevistaPdf.exportar(entrevista, pessoa);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Não foi possível gerar o PDF: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _exportandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _pessoa == null) {
      return AppScaffold(
        appBar: AppScreenChrome.appBar(context, title: _titulo),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pessoa = _pessoa!;
    final textTheme = Theme.of(context).textTheme;

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.screenPaddingH,
              AppLayout.screenPaddingTop,
              AppLayout.screenPaddingH,
              8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pessoa.nome,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          if (!_readOnly)
                            TextButton(
                              onPressed: _selecionarPessoa,
                              child: const Text('Trocar'),
                            ),
                        ],
                      ),
                      if (pessoa.cpfFormatado != null ||
                          pessoa.cpf.isNotEmpty)
                        Text(
                          'CPF: ${pessoa.cpfFormatado ?? formatCpfDisplay(pessoa.cpf)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutralGray,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                EntrevistaTextField(
                  controller: _dataController,
                  focusNode: _dataEntrevistaFocusNode,
                  readOnly: _readOnly,
                  onAdvance: _advanceFromData,
                  beforeAdvance: _aplicarMascaraDataEntrevista4Anos,
                  decoration: const InputDecoration(
                    labelText: 'Data da entrevista',
                    hintText: 'dd/mm/aaaa',
                  ),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [DataBrFormatter()],
                  validator: validateDataBr,
                ),
                if (widget.isEdicao && _entrevistaCarregada != null) ...[
                  const SizedBox(height: 16),
                  AuditoriaSection(
                    auditoria: _entrevistaCarregada!.auditoria,
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: AppColors.lightBlue,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.neutralGray,
              indicatorColor: AppColors.accentOrange,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Assistência'),
                Tab(text: 'Programas Sociais'),
                Tab(text: 'Composição Familiar'),
                Tab(text: 'Trabalho e Renda'),
                Tab(text: 'Condições Educacionais da Família'),
                Tab(text: 'Condições de Saúde da Família'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AbaAssistencia(
                  readOnly: _readOnly,
                  outrosController: _outrosController,
                  formasSelecionadas: _formasSelecionadas,
                  onToggleForma: _toggleForma,
                ),
                EntrevistaProgramasSociaisTab(
                  readOnly: _readOnly,
                  bolsaFamilia: _bolsaFamilia,
                  peti: _peti,
                  bpc: _bpc,
                  outrosProgramas: _outrosProgramas,
                  outrosProgramasSociaisController:
                      _outrosProgramasSociaisController,
                  cras: _cras,
                  centroPop: _centroPop,
                  conselhoTutelar: _conselhoTutelar,
                  ubs: _ubs,
                  creas: _creas,
                  caps: _caps,
                  craf: _craf,
                  outrosAtendimentoFamilia: _outrosAtendimentoFamilia,
                  outrosOrgaosSociaisController: _outrosOrgaosSociaisController,
                  onBolsaFamiliaChanged: (v) =>
                      setState(() => _bolsaFamilia = v ?? false),
                  onPetiChanged: (v) => setState(() => _peti = v ?? false),
                  onBpcChanged: (v) => setState(() => _bpc = v ?? false),
                  onOutrosProgramasChanged: (v) {
                    setState(() {
                      _outrosProgramas = v ?? false;
                      if (!_outrosProgramas) {
                        _outrosProgramasSociaisController.clear();
                      }
                    });
                  },
                  onCrasChanged: (v) => setState(() => _cras = v ?? false),
                  onCentroPopChanged: (v) =>
                      setState(() => _centroPop = v ?? false),
                  onConselhoTutelarChanged: (v) =>
                      setState(() => _conselhoTutelar = v ?? false),
                  onUbsChanged: (v) => setState(() => _ubs = v ?? false),
                  onCreasChanged: (v) => setState(() => _creas = v ?? false),
                  onCapsChanged: (v) => setState(() => _caps = v ?? false),
                  onCrafChanged: (v) => setState(() => _craf = v ?? false),
                  onOutrosAtendimentoChanged: (v) {
                    setState(() {
                      _outrosAtendimentoFamilia = v ?? false;
                      if (!_outrosAtendimentoFamilia) {
                        _outrosOrgaosSociaisController.clear();
                      }
                    });
                  },
                ),
                EntrevistaComposicaoFamiliarTab(
                      readOnly: _readOnly,
                      linhas: _composicaoLinhas,
                      onAdicionar: _adicionarComposicao,
                      onRemover: _removerComposicao,
                      onLinhaChanged: _onComposicaoChanged,
                      onAdvanceAfterTab: _advanceAfterComposicao,
                    ),
                EntrevistaCondicaoTrabalhoTab(
                  readOnly: _readOnly,
                  linhas: _trabalhoLinhas,
                  nomesDisponiveis: _nomesFamilia,
                  quantidadePessoasComposicao: _quantidadePessoasComposicao,
                  onAdicionar: _adicionarTrabalho,
                  onRemover: _removerTrabalho,
                  onChanged: _refreshForm,
                  onAdvanceAfterTab: _advanceAfterTrabalho,
                ),
                EntrevistaCondicaoEducacionalTab(
                  readOnly: _readOnly,
                  linhas: _educacionalLinhas,
                  nomesDisponiveis: _nomesFamilia,
                  escolaridades: _escolaridades,
                  onAdicionar: _adicionarEducacional,
                  onRemover: _removerEducacional,
                  onChanged: _refreshForm,
                  onAdvanceAfterTab: _advanceAfterEducacional,
                ),
                EntrevistaCondicaoSaudeTab(
                  readOnly: _readOnly,
                  deficiencias: _deficienciaLinhas,
                  gestantes: _gestanteLinhas,
                  saudeFamilia: _saudeFamilia,
                  nomesDisponiveis: _nomesFamilia,
                  onAdicionarDeficiencia: _adicionarDeficiencia,
                  onRemoverDeficiencia: _removerDeficiencia,
                  onAdicionarGestante: _adicionarGestante,
                  onRemoverGestante: _removerGestante,
                  onLimparGestantes: _limparGestantes,
                  onChanged: _refreshForm,
                  onAdvanceAfterTab: _advanceToSubmit,
                ),
              ],
            ),
          ),
          if (!_readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.screenPaddingH,
                8,
                AppLayout.screenPaddingH,
                AppLayout.screenPaddingBottom,
              ),
              child: AppButton(
                label: widget.isEdicao
                    ? 'Salvar alterações'
                    : 'Salvar entrevista',
                focusNode: _submitFocusNode,
                onPressed: _submitting ? null : _salvar,
                loading: _submitting,
              ),
            ),
        ],
      ),
    );

    return PermissaoGate(
      programaCodigo: Programas.entrevistaAssistido,
      child: AppScaffold(
        appBar: AppScreenChrome.appBar(
          context,
          title: _titulo,
          actions: [
            if (_readOnly && _entrevistaCarregada != null)
              PopupMenuButton<String>(
                tooltip: 'PDF',
                enabled: !_exportandoPdf,
                icon: _exportandoPdf
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                onSelected: (value) {
                  if (value == 'visualizar') {
                    _gerarPdf(visualizar: true);
                  } else if (value == 'exportar') {
                    _gerarPdf(visualizar: false);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'visualizar',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Visualizar PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'exportar',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Baixar / compartilhar PDF'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: formContent,
      ),
    );
  }
}

class _AbaAssistencia extends StatelessWidget {
  const _AbaAssistencia({
    required this.readOnly,
    required this.outrosController,
    required this.formasSelecionadas,
    required this.onToggleForma,
  });

  final bool readOnly;
  final TextEditingController outrosController;
  final Set<FormaAcessoInstituicao> formasSelecionadas;
  final void Function(FormaAcessoInstituicao forma, bool? selected) onToggleForma;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mostrarOutros =
        formasSelecionadas.contains(FormaAcessoInstituicao.outros);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingTop,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        Text(
          FormaAcessoInstituicao.textoFixoAssistencia,
          style: textTheme.bodyLarge?.copyWith(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...FormaAcessoInstituicao.opcoesAssistencia.map((forma) {
          if (forma == FormaAcessoInstituicao.outros) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckboxListTile(
                  value: formasSelecionadas.contains(forma),
                  onChanged: readOnly ? null : (v) => onToggleForma(forma, v),
                  title: Text(
                    forma.rotulo,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (mostrarOutros) ...[
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: outrosController,
                    readOnly: readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Descreva (Outros)',
                      hintText: 'Informe como a família acessou a instituição',
                    ),
                    maxLength: 500,
                    maxLines: 3,
                  ),
                ],
              ],
            );
          }
          return CheckboxListTile(
            value: formasSelecionadas.contains(forma),
            onChanged: readOnly ? null : (v) => onToggleForma(forma, v),
            title: Text(
              forma.rotulo,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}
