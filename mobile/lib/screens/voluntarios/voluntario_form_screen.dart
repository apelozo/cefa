import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/programas.dart';
import '../../constants/estado_civil_voluntario.dart';
import '../../models/cidade.dart';
import '../../models/voluntario.dart';
import '../../providers/auth_provider.dart';
import '../../screens/cidades/cidade_form_screen.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/datetime_display.dart';
import '../../utils/form_enter_focus.dart';
import '../../utils/rg_formatter.dart';
import '../../utils/snackbar.dart';
import '../../utils/telefone_formatter.dart';
import '../../validators/resposta_validator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_form_text_field.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/app_searchable_select_field.dart';
import '../../widgets/voluntario_departamento_horarios_editor.dart';

class VoluntarioFormScreen extends ConsumerStatefulWidget {
  const VoluntarioFormScreen({super.key, this.voluntario});

  final Voluntario? voluntario;

  bool get isEditing => voluntario != null;

  @override
  ConsumerState<VoluntarioFormScreen> createState() =>
      _VoluntarioFormScreenState();
}

class _VoluntarioFormScreenState extends ConsumerState<VoluntarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _empresaController;
  late final TextEditingController _funcaoController;
  late final TextEditingController _nomeController;
  late final TextEditingController _dtNascimentoController;
  late final TextEditingController _nomeCrachaController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _enderecoNumeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cepController;
  late final TextEditingController _enderecoComplementoController;
  late final TextEditingController _rgController;
  late final TextEditingController _cpfController;
  late final TextEditingController _cnhController;
  late final TextEditingController _celularController;
  late final TextEditingController _telefoneResidencialController;
  late final TextEditingController _telefoneComercialController;
  late final TextEditingController _emailController;
  late final TextEditingController _valorContribuicaoController;
  late final TextEditingController _diaVencimentoController;
  late final TextEditingController _tempoTrabalhoCentroController;
  late final TextEditingController _fichaMedicaController;
  late final FormEnterFocus _enterFocus;

  String? _estadoCivil;
  int? _cidadeCodigo;
  List<Cidade> _cidades = [];
  bool _loadingRefs = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voluntario;
    _enterFocus = FormEnterFocus.count(20);
    _nomeController = TextEditingController(text: v?.nome ?? '');
    _empresaController = TextEditingController(text: v?.empresa ?? '');
    _funcaoController = TextEditingController(text: v?.funcao ?? '');
    _dtNascimentoController =
        TextEditingController(text: v?.dtNascimento ?? '');
    _nomeCrachaController = TextEditingController(text: v?.nomeCracha ?? '');
    _enderecoController = TextEditingController(text: v?.endereco ?? '');
    _enderecoNumeroController =
        TextEditingController(text: v?.enderecoNumero ?? '');
    _bairroController = TextEditingController(text: v?.bairro ?? '');
    _cepController = TextEditingController(text: v?.cep ?? '');
    _enderecoComplementoController =
        TextEditingController(text: v?.enderecoComplemento ?? '');
    _rgController = TextEditingController(
      text: v?.rg != null ? formatRgDisplay(v!.rg!) : '',
    );
    _cpfController = TextEditingController(
      text: v?.cpf != null ? formatCpfDisplay(v!.cpf!) : '',
    );
    _cnhController = TextEditingController(text: v?.cnh ?? '');
    _celularController = TextEditingController(
      text: v?.celular != null ? formatTelefoneDisplay(v!.celular!) : '',
    );
    _telefoneResidencialController = TextEditingController(
      text: v?.telefoneResidencial != null
          ? formatTelefoneDisplay(v!.telefoneResidencial!)
          : '',
    );
    _telefoneComercialController = TextEditingController(
      text: v?.telefoneComercial != null
          ? formatTelefoneDisplay(v!.telefoneComercial!)
          : '',
    );
    _emailController = TextEditingController(text: v?.email ?? '');
    _valorContribuicaoController = TextEditingController(
      text: v?.valorContribuicao?.replaceAll('.', ',') ?? '',
    );
    _diaVencimentoController = TextEditingController(
      text: v?.diaVencimento?.toString() ?? '',
    );
    _tempoTrabalhoCentroController = TextEditingController(
      text: v?.tempoTrabalhoCentro?.toString() ?? '',
    );
    _fichaMedicaController = TextEditingController(text: v?.fichaMedica ?? '');
    _estadoCivil = v?.estadoCivil;
    _cidadeCodigo = v?.cidadeCodigo;
    _loadReferencias();
  }

  Future<void> _loadReferencias() async {
    try {
      final cidades = await ref.read(apiClientProvider).listCidades(ativo: true);
      if (!mounted) return;
      cidades.sort((a, b) {
        final porNome = a.nomeMunicipio
            .toLowerCase()
            .compareTo(b.nomeMunicipio.toLowerCase());
        if (porNome != 0) return porNome;
        return a.estado.compareTo(b.estado);
      });
      setState(() {
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

  @override
  void dispose() {
    _enterFocus.dispose();
    _nomeController.dispose();
    _empresaController.dispose();
    _funcaoController.dispose();
    _dtNascimentoController.dispose();
    _nomeCrachaController.dispose();
    _enderecoController.dispose();
    _enderecoNumeroController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    _enderecoComplementoController.dispose();
    _rgController.dispose();
    _cpfController.dispose();
    _cnhController.dispose();
    _celularController.dispose();
    _telefoneResidencialController.dispose();
    _telefoneComercialController.dispose();
    _emailController.dispose();
    _valorContribuicaoController.dispose();
    _diaVencimentoController.dispose();
    _tempoTrabalhoCentroController.dispose();
    _fichaMedicaController.dispose();
    super.dispose();
  }

  String? _opt(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  int? _parseIntOpt(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  String? _valorContribuicaoApi() {
    final t = _valorContribuicaoController.text.trim();
    if (t.isEmpty) return null;
    return t.replaceAll('.', '').replaceAll(',', '.');
  }

  Voluntario _buildVoluntario() {
    final cpfRaw = _opt(_cpfController.text);
    final rgRaw = _opt(_rgController.text);
    final cel = _opt(_celularController.text);
    final telRes = _opt(_telefoneResidencialController.text);
    final telCom = _opt(_telefoneComercialController.text);
    final cepRaw = _opt(_cepController.text)?.replaceAll(RegExp(r'\D'), '');

    return Voluntario(
      id: widget.voluntario?.id ?? '',
      codigo: widget.voluntario?.codigo ?? 0,
      nome: _nomeController.text.trim(),
      nomeCracha: _nomeCrachaController.text.trim(),
      ativo: widget.voluntario?.ativo ?? true,
      empresa: _opt(_empresaController.text),
      funcao: _opt(_funcaoController.text),
      estadoCivil: _estadoCivil,
      dtNascimento: _opt(_dtNascimentoController.text) != null
          ? normalizarDataBr(_dtNascimentoController.text.trim())
          : null,
      endereco: _opt(_enderecoController.text),
      enderecoNumero: _opt(_enderecoNumeroController.text),
      bairro: _opt(_bairroController.text),
      cep: cepRaw != null && cepRaw.isNotEmpty ? cepRaw : null,
      cidadeCodigo: _cidadeCodigo,
      enderecoComplemento: _opt(_enderecoComplementoController.text),
      rg: rgRaw != null ? normalizeRg(rgRaw) : null,
      cpf: cpfRaw != null ? normalizeCpf(cpfRaw) : null,
      cnh: _opt(_cnhController.text),
      celular: cel != null ? normalizeTelefone(cel) : null,
      telefoneResidencial: telRes != null ? normalizeTelefone(telRes) : null,
      telefoneComercial: telCom != null ? normalizeTelefone(telCom) : null,
      email: _opt(_emailController.text),
      valorContribuicao: _valorContribuicaoApi(),
      diaVencimento: _parseIntOpt(_diaVencimentoController.text),
      tempoTrabalhoCentro: _parseIntOpt(_tempoTrabalhoCentroController.text),
      fichaMedica: _opt(_fichaMedicaController.text),
      usuarioInclusaoId: widget.voluntario?.usuarioInclusaoId,
      dataHoraInclusao: widget.voluntario?.dataHoraInclusao,
      usuarioAlteracaoId: widget.voluntario?.usuarioAlteracaoId,
      dataHoraAlteracao: widget.voluntario?.dataHoraAlteracao,
      createdAt: widget.voluntario?.createdAt,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEditing && widget.voluntario!.id.isEmpty) {
        showErrorSnackBar(context, 'Registro inválido. Volte e tente novamente.');
        return;
      }

      final voluntario = _buildVoluntario();
      final api = ref.read(apiClientProvider);

      if (widget.isEditing) {
        await api.updateVoluntario(voluntario);
      } else {
        final created = await api.createVoluntario(voluntario);
        if (mounted) {
          showSuccessSnackBar(context, 'Voluntário criado');
          Navigator.pop(context, created);
        }
        return;
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Voluntário atualizado');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  Widget _auditLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  String? _validateCep(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    final d = t.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return 'CEP deve ter 8 dígitos';
    return null;
  }

  String? _validateDiaVencimento(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 1 || n > 31) {
      return 'Informe um dia entre 1 e 31';
    }
    return null;
  }

  String? _validateTempoCentro(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null || n < 0 || n > 100) {
      return 'Informe um valor entre 0 e 100';
    }
    return null;
  }

  String? _validateFichaMedica(String? value) {
    if (value != null && value.length > 1000) {
      return 'Máximo de 1000 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voluntario;
    final auth = ref.watch(authProvider);
    final podeCadastrarCidade = auth.podeIncluir(Programas.cidades);

    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing ? 'Editar voluntário' : 'Novo voluntário',
      ),
      body: _loadingRefs
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  if (widget.isEditing && v != null) ...[
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Código'),
                      child: Text(
                        v.codigo.toString(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'O código será gerado automaticamente ao salvar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(context, 'Identificação'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 0,
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 1,
                    controller: _nomeCrachaController,
                    decoration: const InputDecoration(
                      labelText: 'Nome no Crachá',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o nome no crachá';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 2,
                    controller: _empresaController,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 3,
                    controller: _funcaoController,
                    decoration: const InputDecoration(labelText: 'Função'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _estadoCivil,
                    decoration: const InputDecoration(labelText: 'Estado civil'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Não informado'),
                      ),
                      ...EstadoCivilVoluntario.opcoes.entries.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (val) => setState(() => _estadoCivil = val),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 4,
                    controller: _dtNascimentoController,
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'dd/mm/aa',
                    ),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [DataBrFormatter()],
                    validator: validateDataBrOpcional,
                  ),
                  _sectionTitle(context, 'Endereço'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 5,
                    controller: _enderecoController,
                    decoration: const InputDecoration(labelText: 'Endereço'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 6,
                    controller: _enderecoNumeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 7,
                    controller: _bairroController,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 8,
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
                  ),
                  const SizedBox(height: 16),
                  AppSearchableSelectField<int?>(
                    label: 'Município (código da cidade)',
                    value: _cidadeCodigo,
                    options: _cidadeOptions,
                    enabled: !_saving,
                    searchLabel: 'Pesquisar município',
                    emptyListMessage: 'Nenhum município encontrado.',
                    cadastrarLabel: 'Cadastrar município',
                    onCadastrar:
                        podeCadastrarCidade ? _cadastrarCidade : null,
                    onChanged: (val) => setState(() => _cidadeCodigo = val),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 9,
                    controller: _enderecoComplementoController,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                  _sectionTitle(context, 'Documentos e contato'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 10,
                    controller: _rgController,
                    decoration: const InputDecoration(
                      labelText: 'RG',
                      hintText: '00.000.000-0',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [RgFormatter()],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 11,
                    controller: _cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfFormatter()],
                    validator: validateCpfOpcional,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 12,
                    controller: _cnhController,
                    decoration: const InputDecoration(labelText: 'CNH'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 13,
                    controller: _celularController,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      hintText: '(00) 00000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneFormatter()],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 14,
                    controller: _telefoneResidencialController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone residencial',
                      hintText: '(00) 0000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneFormatter()],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 15,
                    controller: _telefoneComercialController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone comercial',
                      hintText: '(00) 0000-0000',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneFormatter()],
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 16,
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _sectionTitle(context, 'Contribuição e centro'),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 17,
                    controller: _valorContribuicaoController,
                    decoration: const InputDecoration(
                      labelText: 'Valor da contribuição',
                      hintText: '0,00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 18,
                    controller: _diaVencimentoController,
                    decoration: const InputDecoration(
                      labelText: 'Qual o melhor dia de Vencimento?',
                      hintText: '1 a 31',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: _validateDiaVencimento,
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    enterFocus: _enterFocus,
                    enterIndex: 19,
                    controller: _tempoTrabalhoCentroController,
                    decoration: const InputDecoration(
                      labelText: 'Quantos Anos trabalha no Centro?',
                      hintText: 'Ex.: 5',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: _validateTempoCentro,
                  ),
                  _sectionTitle(context, 'Ficha médica'),
                  TextFormField(
                    controller: _fichaMedicaController,
                    decoration: const InputDecoration(
                      labelText: 'Ficha médica',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    maxLength: 1000,
                    validator: _validateFichaMedica,
                  ),
                  const SizedBox(height: 24),
                  if (widget.isEditing && v != null && v.id.isNotEmpty) ...[
                    VoluntarioDepartamentoHorariosEditor(voluntarioId: v.id),
                    const SizedBox(height: 24),
                  ] else if (!widget.isEditing) ...[
                    Text(
                      'Salve o voluntário para vincular departamentos e horários.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (widget.isEditing && v != null) ...[
                    Text(
                      'Auditoria',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _auditLine(
                      'Inclusão',
                      '${formatDateTimeBr(v.dataHoraInclusao)}'
                      '${v.usuarioInclusaoId != null ? ' · usuário ${v.usuarioInclusaoId}' : ''}',
                    ),
                    _auditLine(
                      'Última alteração',
                      '${formatDateTimeBr(v.dataHoraAlteracao)}'
                      '${v.usuarioAlteracaoId != null ? ' · usuário ${v.usuarioAlteracaoId}' : ''}',
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppButton(
                    focusNode: _enterFocus.submitFocusNode,
                    label: widget.isEditing ? 'Salvar' : 'Criar',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}
