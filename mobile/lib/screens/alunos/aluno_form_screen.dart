import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/estado_civil_voluntario.dart';
import '../../models/aluno.dart';
import '../../models/cidade.dart';
import '../../models/escolaridade.dart';
import '../../providers/api_provider.dart';
import '../../screens/cidades/cidade_form_screen.dart';
import '../../screens/escolaridades/escolaridade_form_screen.dart';
import '../../theme/app_layout.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/idade.dart';
import '../../utils/rg_formatter.dart';
import '../../utils/snackbar.dart';
import '../../utils/telefone_formatter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_form_text_field.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/app_searchable_select_field.dart';
import '../../widgets/auditoria_section.dart';

class AlunoFormScreen extends ConsumerStatefulWidget {
  const AlunoFormScreen({super.key, this.aluno});

  final Aluno? aluno;

  bool get isEditing => aluno != null;

  @override
  ConsumerState<AlunoFormScreen> createState() => _AlunoFormScreenState();
}

class _AlunoFormScreenState extends ConsumerState<AlunoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final FormEnterFocus _enterFocus;
  late final FocusNode _cidadeEnderecoFocusNode;

  late final TextEditingController _nomeController;
  late final TextEditingController _nomeSocialController;
  late final TextEditingController _rgController;
  late final TextEditingController _orgaoExpedidorController;
  late final TextEditingController _dtExpedicaoRgController;
  late final TextEditingController _cpfController;
  late final TextEditingController _dtNascimentoController;
  late final TextEditingController _idadeController;
  late final TextEditingController _nacionalidadeController;
  late final TextEditingController _nomeMaeController;
  late final TextEditingController _nomePaiController;
  late final TextEditingController _nomeUltimaEscolaController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _enderecoNumeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cepController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _celularController;
  late final TextEditingController _telefoneRecadoController;
  late final TextEditingController _emailController;

  String? _estadoCivil;
  int? _naturalidadeCodigo;
  int? _escolaridadeCodigo;
  int? _cidadeCodigo;

  List<Cidade> _cidades = [];
  List<Escolaridade> _escolaridades = [];
  bool _refsLoaded = false;
  Future<void>? _loadReferenciasFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterFocus = FormEnterFocus.count(19);
    _cidadeEnderecoFocusNode = FocusNode();
    final a = widget.aluno;

    _nomeController = TextEditingController(text: a?.nome ?? '');
    _nomeSocialController = TextEditingController(text: a?.nomeSocial ?? '');
    _rgController = TextEditingController(
      text: a?.rg != null ? formatRgDisplay(a!.rg!) : '',
    );
    _orgaoExpedidorController =
        TextEditingController(text: a?.orgaoExpedidor ?? '');
    _dtExpedicaoRgController =
        TextEditingController(text: a?.dtExpedicaoRg ?? '');
    _cpfController = TextEditingController(
      text: a?.cpf != null ? formatCpfDisplay(a!.cpf!) : '',
    );
    _dtNascimentoController =
        TextEditingController(text: a?.dtNascimento ?? '');
    _idadeController = TextEditingController(
      text: a?.idade?.toString() ?? '',
    );
    _nacionalidadeController =
        TextEditingController(text: a?.nacionalidade ?? '');
    _nomeMaeController = TextEditingController(text: a?.nomeMae ?? '');
    _nomePaiController = TextEditingController(text: a?.nomePai ?? '');
    _nomeUltimaEscolaController =
        TextEditingController(text: a?.nomeUltimaEscola ?? '');
    _enderecoController = TextEditingController(text: a?.endereco ?? '');
    _enderecoNumeroController =
        TextEditingController(text: a?.enderecoNumero ?? '');
    _bairroController = TextEditingController(text: a?.bairro ?? '');
    _cepController = TextEditingController(text: a?.cep ?? '');
    _telefoneController = TextEditingController(
      text: a?.telefone != null ? formatTelefoneDisplay(a!.telefone!) : '',
    );
    _celularController = TextEditingController(
      text: a?.celular != null ? formatTelefoneDisplay(a!.celular!) : '',
    );
    _telefoneRecadoController = TextEditingController(
      text: a?.telefoneRecado != null
          ? formatTelefoneDisplay(a!.telefoneRecado!)
          : '',
    );
    _emailController = TextEditingController(text: a?.email ?? '');

    _estadoCivil = a?.estadoCivil;
    _naturalidadeCodigo = a?.naturalidadeCodigo;
    _escolaridadeCodigo = a?.escolaridadeCodigo;
    _cidadeCodigo = a?.cidadeCodigo;

    _atualizarIdade();
  }

  @override
  void dispose() {
    _enterFocus.dispose();
    _cidadeEnderecoFocusNode.dispose();
    _nomeController.dispose();
    _nomeSocialController.dispose();
    _rgController.dispose();
    _orgaoExpedidorController.dispose();
    _dtExpedicaoRgController.dispose();
    _cpfController.dispose();
    _dtNascimentoController.dispose();
    _idadeController.dispose();
    _nacionalidadeController.dispose();
    _nomeMaeController.dispose();
    _nomePaiController.dispose();
    _nomeUltimaEscolaController.dispose();
    _enderecoController.dispose();
    _enderecoNumeroController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _telefoneRecadoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _atualizarIdade() {
    final idade = calcularIdadeFromDataBr(_dtNascimentoController.text);
    _idadeController.text = idade?.toString() ?? '';
  }

  void _requestFocus(FocusNode node) {
    if (!node.canRequestFocus) return;
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && node.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  List<SearchableSelectOption<int?>> get _cidadeOptions => [
        ..._cidades.map(
          (c) => SearchableSelectOption<int?>(
            value: c.codigo,
            label: '${c.nomeMunicipio} — ${c.estado}',
          ),
        ),
      ];

  List<SearchableSelectOption<int?>> get _escolaridadeOptions => [
        ..._escolaridades.map(
          (e) => SearchableSelectOption<int?>(
            value: e.codigo,
            label: '${e.codigo} — ${e.descricao}',
          ),
        ),
      ];

  Future<void> _ensureReferencias() async {
    if (_refsLoaded) return;
    if (_loadReferenciasFuture != null) {
      await _loadReferenciasFuture;
      return;
    }
    _loadReferenciasFuture = _fetchReferencias();
    try {
      await _loadReferenciasFuture;
    } finally {
      _loadReferenciasFuture = null;
    }
  }

  Future<void> _fetchReferencias() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.listCidades(ativo: true),
        api.listEscolaridades(ativo: true),
      ]);
      if (!mounted) return;
      final cidades = List<Cidade>.from(results[0] as List<Cidade>)
        ..sort((a, b) {
          final porNome = a.nomeMunicipio
              .toLowerCase()
              .compareTo(b.nomeMunicipio.toLowerCase());
          if (porNome != 0) return porNome;
          return a.estado.compareTo(b.estado);
        });
      final escolaridades =
          List<Escolaridade>.from(results[1] as List<Escolaridade>)
            ..sort((a, b) => a.codigo.compareTo(b.codigo));
      setState(() {
        _cidades = cidades;
        _escolaridades = escolaridades;
        _refsLoaded = true;
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
      rethrow;
    }
  }

  Future<void> _onBeforeOpenSelect() => _ensureReferencias();

  void _appendCidade(Cidade cidade) {
    setState(() {
      _cidades = [..._cidades.where((c) => c.codigo != cidade.codigo), cidade]
        ..sort((a, b) {
          final porNome = a.nomeMunicipio
              .toLowerCase()
              .compareTo(b.nomeMunicipio.toLowerCase());
          if (porNome != 0) return porNome;
          return a.estado.compareTo(b.estado);
        });
      _refsLoaded = true;
    });
  }

  void _appendEscolaridade(Escolaridade escolaridade) {
    setState(() {
      _escolaridades = [
        ..._escolaridades.where((e) => e.codigo != escolaridade.codigo),
        escolaridade,
      ]..sort((a, b) => a.codigo.compareTo(b.codigo));
      _refsLoaded = true;
    });
  }

  String? _labelNaturalidade() {
    if (_naturalidadeCodigo == null) return null;
    final a = widget.aluno;
    if (a != null &&
        a.naturalidadeCodigo == _naturalidadeCodigo &&
        a.naturalidadeNome != null) {
      final uf = a.naturalidadeEstado;
      return uf != null ? '${a.naturalidadeNome} — $uf' : a.naturalidadeNome;
    }
    for (final c in _cidades) {
      if (c.codigo == _naturalidadeCodigo) {
        return '${c.nomeMunicipio} — ${c.estado}';
      }
    }
    return null;
  }

  String? _labelEscolaridade() {
    if (_escolaridadeCodigo == null) return null;
    final a = widget.aluno;
    if (a != null &&
        a.escolaridadeCodigo == _escolaridadeCodigo &&
        a.escolaridadeDescricao != null) {
      return '${a.escolaridadeCodigo} — ${a.escolaridadeDescricao}';
    }
    for (final e in _escolaridades) {
      if (e.codigo == _escolaridadeCodigo) {
        return '${e.codigo} — ${e.descricao}';
      }
    }
    return null;
  }

  String? _labelCidadeEndereco() {
    if (_cidadeCodigo == null) return null;
    final a = widget.aluno;
    if (a != null &&
        a.cidadeCodigo == _cidadeCodigo &&
        a.cidadeNome != null) {
      final uf = a.cidadeEstado;
      return uf != null ? '${a.cidadeNome} — $uf' : a.cidadeNome;
    }
    for (final c in _cidades) {
      if (c.codigo == _cidadeCodigo) {
        return '${c.nomeMunicipio} — ${c.estado}';
      }
    }
    return null;
  }

  String? _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String? _opt(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  String? _validateCep(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final d = _onlyDigits(value)!;
    if (d.length != 8) return 'CEP deve ter 8 dígitos';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final email = value.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'E-mail inválido';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final payload = Aluno(
        id: widget.aluno?.id ?? '',
        nome: _nomeController.text.trim(),
        nomeSocial: _opt(_nomeSocialController.text),
        estadoCivil: _estadoCivil,
        rg: _rgController.text.trim().isEmpty
            ? null
            : _onlyDigits(_rgController.text),
        orgaoExpedidor: _opt(_orgaoExpedidorController.text),
        dtExpedicaoRg: _dtExpedicaoRgController.text.trim().isEmpty
            ? null
            : normalizarDataBr(_dtExpedicaoRgController.text.trim()),
        cpf: _cpfController.text.trim().isEmpty
            ? null
            : _onlyDigits(_cpfController.text),
        dtNascimento: normalizarDataBr(_dtNascimentoController.text.trim()),
        nacionalidade: _opt(_nacionalidadeController.text),
        naturalidadeCodigo: _naturalidadeCodigo,
        nomeMae: _opt(_nomeMaeController.text),
        nomePai: _opt(_nomePaiController.text),
        escolaridadeCodigo: _escolaridadeCodigo,
        nomeUltimaEscola: _opt(_nomeUltimaEscolaController.text),
        endereco: _opt(_enderecoController.text),
        enderecoNumero: _opt(_enderecoNumeroController.text),
        bairro: _opt(_bairroController.text),
        cep: _opt(_cepController.text)?.replaceAll(RegExp(r'\D'), ''),
        cidadeCodigo: _cidadeCodigo,
        telefone: _opt(_telefoneController.text)?.replaceAll(RegExp(r'\D'), ''),
        celular: _opt(_celularController.text)?.replaceAll(RegExp(r'\D'), ''),
        telefoneRecado:
            _opt(_telefoneRecadoController.text)?.replaceAll(RegExp(r'\D'), ''),
        email: _opt(_emailController.text),
        ativo: widget.aluno?.ativo ?? true,
      );

      final api = ref.read(apiClientProvider);
      if (widget.isEditing) {
        await api.updateAluno(payload);
        if (mounted) {
          showSuccessSnackBar(context, 'Aluno atualizado');
          Navigator.pop(context, true);
        }
      } else {
        final created = await api.createAluno(payload);
        if (mounted) {
          showSuccessSnackBar(context, 'Aluno cadastrado');
          Navigator.pop(context, created);
        }
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _auditSection() {
    final a = widget.aluno;
    if (a == null) return const SizedBox.shrink();
    return AuditoriaSection(
      auditoria: a.auditoria,
      mostrarExclusao: !a.ativo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar aluno' : 'Novo aluno',
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                      padding: AppLayout.screenPadding,
                      children: [
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 0,
                          controller: _nomeController,
                          decoration: const InputDecoration(labelText: 'Nome'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Informe o nome'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 1,
                          controller: _nomeSocialController,
                          decoration:
                              const InputDecoration(labelText: 'Nome social'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          value: _estadoCivil,
                          decoration:
                              const InputDecoration(labelText: 'Estado civil'),
                          hint: const Text('Selecione'),
                          items: EstadoCivilVoluntario.opcoes.entries
                              .map(
                                (e) => DropdownMenuItem<String?>(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _estadoCivil = v),
                          validator: (v) =>
                              v == null ? 'Selecione o estado civil' : null,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 2,
                          controller: _rgController,
                          decoration: const InputDecoration(labelText: 'RG'),
                          inputFormatters: [RgFormatter()],
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 3,
                          controller: _orgaoExpedidorController,
                          decoration: const InputDecoration(
                            labelText: 'Órgão expedidor',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 4,
                          controller: _dtExpedicaoRgController,
                          decoration: const InputDecoration(
                            labelText: 'Data de expedição do RG',
                            hintText: 'dd/mm/aaaa',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [DataBrFormatter()],
                          validator: validateDataBrOpcional,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 5,
                          controller: _cpfController,
                          decoration: const InputDecoration(labelText: 'CPF'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [CpfFormatter()],
                          validator: validateCpfOpcional,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 6,
                          controller: _dtNascimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de nascimento',
                            hintText: 'dd/mm/aaaa',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [DataBrFormatter()],
                          validator: validateDataBr,
                          onChanged: (_) {
                            _atualizarIdade();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idadeController,
                          decoration:
                              const InputDecoration(labelText: 'Idade'),
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 7,
                          controller: _nacionalidadeController,
                          decoration:
                              const InputDecoration(labelText: 'Nacionalidade'),
                        ),
                        const SizedBox(height: 12),
                        AppSearchableSelectField<int?>(
                          label: 'Naturalidade (município)',
                          value: _naturalidadeCodigo,
                          selectedLabel: _labelNaturalidade(),
                          options: _cidadeOptions,
                          onBeforeOpen: _onBeforeOpenSelect,
                          onChanged: (v) =>
                              setState(() => _naturalidadeCodigo = v),
                          onCadastrar: () async {
                            final r = await Navigator.of(context).push<Object?>(
                              MaterialPageRoute(
                                builder: (_) => const CidadeFormScreen(),
                              ),
                            );
                            if (r is Cidade) {
                              _appendCidade(r);
                              setState(() => _naturalidadeCodigo = r.codigo);
                              return r.codigo;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 8,
                          controller: _nomeMaeController,
                          decoration:
                              const InputDecoration(labelText: 'Nome da mãe'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 9,
                          controller: _nomePaiController,
                          decoration:
                              const InputDecoration(labelText: 'Nome do pai'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppSearchableSelectField<int?>(
                          label: 'Código da escolaridade',
                          value: _escolaridadeCodigo,
                          selectedLabel: _labelEscolaridade(),
                          options: _escolaridadeOptions,
                          onBeforeOpen: _onBeforeOpenSelect,
                          onChanged: (v) =>
                              setState(() => _escolaridadeCodigo = v),
                          onCadastrar: () async {
                            final r = await Navigator.of(context).push<Object?>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EscolaridadeFormScreen(),
                              ),
                            );
                            if (r is Escolaridade) {
                              _appendEscolaridade(r);
                              setState(() => _escolaridadeCodigo = r.codigo);
                              return r.codigo;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 10,
                          controller: _nomeUltimaEscolaController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da última escola',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Endereço e contato',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 11,
                          controller: _enderecoController,
                          decoration:
                              const InputDecoration(labelText: 'Endereço'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 12,
                          controller: _enderecoNumeroController,
                          decoration:
                              const InputDecoration(labelText: 'Número'),
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 13,
                          controller: _bairroController,
                          decoration: const InputDecoration(labelText: 'Bairro'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 14,
                          controller: _cepController,
                          decoration: const InputDecoration(
                            labelText: 'CEP',
                            hintText: '00000000',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          validator: _validateCep,
                          onEnterAdvance: () =>
                              _requestFocus(_cidadeEnderecoFocusNode),
                        ),
                        const SizedBox(height: 12),
                        AppSearchableSelectField<int?>(
                          label: 'Cidade (município)',
                          value: _cidadeCodigo,
                          selectedLabel: _labelCidadeEndereco(),
                          options: _cidadeOptions,
                          focusNode: _cidadeEnderecoFocusNode,
                          onBeforeOpen: _onBeforeOpenSelect,
                          onEnterAdvance: () =>
                              _requestFocus(_enterFocus.fields[15]),
                          onChanged: (v) => setState(() => _cidadeCodigo = v),
                          onCadastrar: () async {
                            final r = await Navigator.of(context).push<Object?>(
                              MaterialPageRoute(
                                builder: (_) => const CidadeFormScreen(),
                              ),
                            );
                            if (r is Cidade) {
                              _appendCidade(r);
                              setState(() => _cidadeCodigo = r.codigo);
                              return r.codigo;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 15,
                          controller: _telefoneController,
                          decoration:
                              const InputDecoration(labelText: 'Telefone'),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [TelefoneFormatter()],
                          validator: validateTelefoneOpcional,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 16,
                          controller: _celularController,
                          decoration:
                              const InputDecoration(labelText: 'Celular'),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [TelefoneFormatter()],
                          validator: validateTelefoneOpcional,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 17,
                          controller: _telefoneRecadoController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone recado',
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [TelefoneFormatter()],
                          validator: validateTelefoneOpcional,
                        ),
                        const SizedBox(height: 12),
                        AppFormTextField(
                          enterFocus: _enterFocus,
                          enterIndex: 18,
                          controller: _emailController,
                          decoration:
                              const InputDecoration(labelText: 'E-mail'),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: AppLayout.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _auditSection(),
                  AppButton(
                    focusNode: _enterFocus.submitFocusNode,
                    label: widget.isEditing ? 'Salvar' : 'Criar',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
