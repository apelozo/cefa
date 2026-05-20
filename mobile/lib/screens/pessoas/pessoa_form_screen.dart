import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/urbano_rural.dart';
import '../../models/bairro.dart';
import '../../models/cidade.dart';
import '../../models/pessoa.dart';
import '../../providers/auth_provider.dart';
import '../../screens/bairros/bairro_form_screen.dart';
import '../../screens/cidades/cidade_form_screen.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/rg_formatter.dart';
import '../../utils/snackbar.dart';
import '../../utils/telefone_formatter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_form_text_field.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/app_searchable_select_field.dart';

class PessoaFormScreen extends ConsumerStatefulWidget {
  const PessoaFormScreen({super.key, this.pessoa});

  final Pessoa? pessoa;

  bool get isEditing => pessoa != null;

  @override
  ConsumerState<PessoaFormScreen> createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends ConsumerState<PessoaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _nomeSocialController;
  late final TextEditingController _nomeMaeController;
  late final TextEditingController _nomePaiController;
  late final TextEditingController _dtNascimentoController;
  late final TextEditingController _cpfController;
  late final TextEditingController _rgController;
  late final TextEditingController _rgOrgaoController;
  late final TextEditingController _nisController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _enderecoNumeroController;
  late final TextEditingController _enderecoComplementoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _telefone2Controller;
  late final FormEnterFocus _enterFocus;
  late bool _ativo;

  int? _bairroCodigo;
  int? _cidadeCodigo;
  String? _urbanoRural;
  List<Bairro> _bairros = [];
  List<Cidade> _cidades = [];
  bool _loadingRefs = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pessoa;
    _enterFocus = FormEnterFocus.count(14);
    _nomeController = TextEditingController(text: p?.nome ?? '');
    _nomeSocialController = TextEditingController(text: p?.nomeSocial ?? '');
    _nomeMaeController = TextEditingController(text: p?.nomeMae ?? '');
    _nomePaiController = TextEditingController(text: p?.nomePai ?? '');
    _dtNascimentoController =
        TextEditingController(text: p?.dtNascimento ?? '');
    _cpfController = TextEditingController(
      text: p != null ? formatCpfDisplay(p.cpf) : '',
    );
    _rgController = TextEditingController(
      text: p != null ? formatRgDisplay(p.rg) : '',
    );
    _rgOrgaoController = TextEditingController(text: p?.rgOrgaoEmissao ?? '');
    _nisController = TextEditingController(text: p?.nis ?? '');
    _enderecoController = TextEditingController(text: p?.endereco ?? '');
    _enderecoNumeroController =
        TextEditingController(text: p?.enderecoNumero ?? '');
    _enderecoComplementoController =
        TextEditingController(text: p?.enderecoComplemento ?? '');
    _telefoneController = TextEditingController(
      text: p?.telefone != null ? formatTelefoneDisplay(p!.telefone!) : '',
    );
    _telefone2Controller = TextEditingController(
      text: p?.telefone2 != null ? formatTelefoneDisplay(p!.telefone2!) : '',
    );
    _bairroCodigo = p?.bairroCodigo;
    _cidadeCodigo = p?.cidadeCodigo;
    _urbanoRural = p?.urbanoRural;
    _ativo = p?.ativo ?? true;
    _loadReferencias();
  }

  Future<int?> _cadastrarBairro() async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => const BairroFormScreen()),
    );
    if (!mounted) return null;
    if (result is Bairro) {
      await _loadReferencias();
      return result.codigo;
    }
    return null;
  }

  Future<int?> _cadastrarCidade() async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => const CidadeFormScreen()),
    );
    if (!mounted) return null;
    if (result is Cidade) {
      await _loadReferencias();
      return result.codigo;
    }
    return null;
  }

  Future<void> _loadReferencias() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.listBairros(ativo: true),
        api.listCidades(ativo: true),
      ]);
      if (!mounted) return;
      final bairros = List<Bairro>.from(results[0] as List<Bairro>)
        ..sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
      final cidades = List<Cidade>.from(results[1] as List<Cidade>)
        ..sort((a, b) {
          final porNome = a.nomeMunicipio
              .toLowerCase()
              .compareTo(b.nomeMunicipio.toLowerCase());
          if (porNome != 0) return porNome;
          return a.estado.compareTo(b.estado);
        });
      setState(() {
        _bairros = bairros;
        _cidades = cidades;
        _loadingRefs = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRefs = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _nomeSocialController.dispose();
    _nomeMaeController.dispose();
    _nomePaiController.dispose();
    _dtNascimentoController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    _rgOrgaoController.dispose();
    _nisController.dispose();
    _enderecoController.dispose();
    _enderecoNumeroController.dispose();
    _enderecoComplementoController.dispose();
    _telefoneController.dispose();
    _telefone2Controller.dispose();
    super.dispose();
  }

  String? _opt(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.pessoa!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final tel1 = _opt(_telefoneController.text);
      final tel2 = _opt(_telefone2Controller.text);
      final nis = _opt(_nisController.text);

      final pessoa = Pessoa(
        id: widget.pessoa?.id ?? '',
        nome: _nomeController.text.trim(),
        nomeSocial: _opt(_nomeSocialController.text),
        nomeMae: _opt(_nomeMaeController.text),
        nomePai: _opt(_nomePaiController.text),
        dtNascimento: normalizarDataBr(_dtNascimentoController.text.trim()),
        cpf: normalizeCpf(_cpfController.text),
        rg: normalizeRg(_rgController.text),
        rgOrgaoEmissao: _opt(_rgOrgaoController.text),
        nis: nis != null ? normalizeTelefone(nis) : null,
        endereco: _opt(_enderecoController.text),
        enderecoNumero: _opt(_enderecoNumeroController.text),
        enderecoComplemento: _opt(_enderecoComplementoController.text),
        bairroCodigo: _bairroCodigo,
        cidadeCodigo: _cidadeCodigo,
        telefone: tel1 != null ? normalizeTelefone(tel1) : null,
        telefone2: tel2 != null ? normalizeTelefone(tel2) : null,
        urbanoRural: _urbanoRural,
        ativo: _ativo,
        createdAt: widget.pessoa?.createdAt ?? DateTime.now(),
      );

      final api = ref.read(apiClientProvider);
      if (widget.isEditing) {
        await api.updatePessoa(pessoa);
      } else {
        await api.createPessoa(pessoa);
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isEditing ? 'Pessoa atualizada' : 'Pessoa criada',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<SearchableSelectOption<int?>> get _bairroOptions => [
        const SearchableSelectOption<int?>(
          value: null,
          label: 'Não informado',
          searchText: 'nao informado',
        ),
        ..._bairros.map(
          (b) => SearchableSelectOption<int?>(
            value: b.codigo,
            label: '${b.codigo} — ${b.nome}',
            searchText: '${b.codigo} ${b.nome}',
          ),
        ),
      ];

  List<SearchableSelectOption<int?>> get _cidadeOptions => [
        const SearchableSelectOption<int?>(
          value: null,
          label: 'Não informado',
          searchText: 'nao informado',
        ),
        ..._cidades.map(
          (c) => SearchableSelectOption<int?>(
            value: c.codigo,
            label: c.rotuloSelect,
            searchText: '${c.codigo} ${c.nomeMunicipio} ${c.estado}',
          ),
        ),
      ];

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final podeCadastrarBairro = auth.podeIncluir(Programas.bairros);
    final podeCadastrarCidade = auth.podeIncluir(Programas.cidades);

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar pessoa' : 'Nova pessoa',
      ),
      body: _loadingRefs
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  _sectionTitle(context, 'Identificação'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 0,
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 1,
                    controller: _nomeSocialController,
                    decoration: const InputDecoration(labelText: 'Nome social'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 2,
                    controller: _dtNascimentoController,
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'dd/mm/aa',
                    ),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [DataBrFormatter()],
                    validator: validateDataBr,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 3,
                    controller: _cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfFormatter()],
                    validator: validateCpf,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 4,
                    controller: _rgController,
                    decoration: const InputDecoration(
                      labelText: 'RG',
                      hintText: '00.000.000-0',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [RgFormatter()],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o RG';
                      if (normalizeRg(v).length < 4) return 'RG inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 5,
                    controller: _rgOrgaoController,
                    decoration: const InputDecoration(
                      labelText: 'Órgão emissor do RG',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  _sectionTitle(context, 'Filiação'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 6,
                    controller: _nomeMaeController,
                    decoration: const InputDecoration(labelText: 'Nome da mãe'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 7,
                    controller: _nomePaiController,
                    decoration: const InputDecoration(labelText: 'Nome do pai'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  _sectionTitle(context, 'Documentos'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 8,
                    controller: _nisController,
                    decoration: const InputDecoration(
                      labelText: 'NIS',
                      hintText: '11 dígitos',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [NisFormatter()],
                    validator: validateNisOpcional,
                  ),
                  _sectionTitle(context, 'Endereço'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 9,
                    controller: _enderecoController,
                    decoration: const InputDecoration(labelText: 'Endereço'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 10,
                    controller: _enderecoNumeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 11,
                    controller: _enderecoComplementoController,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                  const SizedBox(height: 16),
                  AppSearchableSelectField<int?>(
                    label: 'Bairro',
                    value: _bairroCodigo,
                    options: _bairroOptions,
                    enabled: !_saving,
                    searchLabel: 'Pesquisar bairro',
                    emptyListMessage: 'Nenhum bairro encontrado.',
                    cadastrarLabel: 'Cadastrar bairro',
                    onCadastrar:
                        podeCadastrarBairro ? _cadastrarBairro : null,
                    onChanged: (v) => setState(() => _bairroCodigo = v),
                  ),
                  const SizedBox(height: 16),
                  AppSearchableSelectField<int?>(
                    label: 'Município',
                    value: _cidadeCodigo,
                    options: _cidadeOptions,
                    enabled: !_saving,
                    searchLabel: 'Pesquisar município',
                    emptyListMessage: 'Nenhum município encontrado.',
                    cadastrarLabel: 'Cadastrar município',
                    onCadastrar:
                        podeCadastrarCidade ? _cadastrarCidade : null,
                    onChanged: (v) => setState(() => _cidadeCodigo = v),
                  ),
                  if (_cidades.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cadastre municípios em Cadastrar cidades.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _urbanoRural,
                    decoration: const InputDecoration(labelText: 'Urbano / Rural'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Não informado'),
                      ),
                      ...UrbanoRural.opcoes.map(
                        (o) => DropdownMenuItem<String?>(
                          value: o.valor,
                          child: Text(o.rotulo),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _urbanoRural = v),
                  ),
                  _sectionTitle(context, 'Contato'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 12,
                    controller: _telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: '(00) 00000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneFormatter()],
                    validator: validateTelefoneOpcional,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 13,
                    controller: _telefone2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Telefone 2',
                      hintText: '(00) 00000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneFormatter()],
                    validator: validateTelefoneOpcional,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: widget.isEditing ? 'Salvar' : 'Criar',
                    focusNode: _enterFocus.submitFocusNode,
                    onPressed: _saving ? null : _save,
                    loading: _saving,
                  ),
                ],
              ),
            ),
    );
  }
}
