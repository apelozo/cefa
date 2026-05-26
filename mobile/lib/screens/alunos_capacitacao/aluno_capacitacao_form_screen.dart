import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/estado_civil_voluntario.dart';
import '../../constants/tipo_casa_aluno_capacitacao.dart';
import '../../models/aluno_capacitacao.dart';
import '../../models/aluno_capacitacao_renda_familiar.dart';
import '../../models/cidade.dart';
import '../../models/escolaridade.dart';
import '../../providers/api_provider.dart';
import '../../screens/cidades/cidade_form_screen.dart';
import '../../screens/escolaridades/escolaridade_form_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_theme.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/datetime_display.dart';
import '../../utils/idade.dart';
import '../../utils/moeda_br.dart';
import '../../utils/rg_formatter.dart';
import '../../utils/snackbar.dart';
import '../../utils/telefone_formatter.dart';
import '../../validators/resposta_validator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_screen_chrome.dart';
import '../../widgets/app_searchable_select_field.dart';
import 'aluno_capacitacao_renda_linha.dart';

class AlunoCapacitacaoFormScreen extends ConsumerStatefulWidget {
  const AlunoCapacitacaoFormScreen({super.key, this.aluno});

  final AlunoCapacitacao? aluno;

  bool get isEditing => aluno != null;

  @override
  ConsumerState<AlunoCapacitacaoFormScreen> createState() =>
      _AlunoCapacitacaoFormScreenState();
}

class _AlunoCapacitacaoFormScreenState
    extends ConsumerState<AlunoCapacitacaoFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  late final TextEditingController _nomeController;
  late final TextEditingController _nomeSocialController;
  late final TextEditingController _rgController;
  late final TextEditingController _orgaoExpedidorController;
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
  late final TextEditingController _valorAluguelController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _celularController;
  late final TextEditingController _telefoneRecadoController;
  late final TextEditingController _emailController;
  late final TextEditingController _redeSocialController;
  late final TextEditingController _cursoSenacDescricaoController;
  late final TextEditingController _cursoSenacAnoController;
  late final TextEditingController _encaminhamentoController;
  late final TextEditingController _telefoneEncaminhamentoController;
  late final TextEditingController _qualNecessidadeController;
  late final TextEditingController _tomaMedicacaoController;
  late final TextEditingController _vacinacaoController;
  late final TextEditingController _alergiasController;

  String? _estadoCivil;
  int? _naturalidadeCodigo;
  int? _escolaridadeCodigo;
  int? _cidadeCodigo;
  String? _tipoCasa;
  bool _jaFezCursoSenacSenai = false;
  bool _possuiNecessidadeEspecial = false;
  bool _fazAcompanhamentoMedico = false;

  List<Cidade> _cidades = [];
  List<Escolaridade> _escolaridades = [];
  final List<AlunoCapacitacaoRendaLinha> _rendaLinhas = [];
  bool _loadingRefs = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final a = widget.aluno;

    _nomeController = TextEditingController(text: a?.nome ?? '');
    _nomeSocialController = TextEditingController(text: a?.nomeSocial ?? '');
    _rgController = TextEditingController(
      text: a?.rg != null ? formatRgDisplay(a!.rg!) : '',
    );
    _orgaoExpedidorController =
        TextEditingController(text: a?.orgaoExpedidor ?? '');
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
    _valorAluguelController = TextEditingController(
      text: a?.valorAluguel != null ? formatMoedaBr(a!.valorAluguel!) : '',
    );
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
    _redeSocialController = TextEditingController(text: a?.redeSocial ?? '');
    _cursoSenacDescricaoController =
        TextEditingController(text: a?.cursoSenacSenaiDescricao ?? '');
    _cursoSenacAnoController = TextEditingController(
      text: a?.cursoSenacSenaiAno?.toString() ?? '',
    );
    _encaminhamentoController =
        TextEditingController(text: a?.encaminhamento ?? '');
    _telefoneEncaminhamentoController = TextEditingController(
      text: a?.telefoneEncaminhamento != null
          ? formatTelefoneDisplay(a!.telefoneEncaminhamento!)
          : '',
    );
    _qualNecessidadeController =
        TextEditingController(text: a?.qualNecessidade ?? '');
    _tomaMedicacaoController =
        TextEditingController(text: a?.tomaMedicacao ?? '');
    _vacinacaoController = TextEditingController(text: a?.vacinacao ?? '');
    _alergiasController = TextEditingController(text: a?.alergias ?? '');

    _estadoCivil = a?.estadoCivil;
    _naturalidadeCodigo = a?.naturalidadeCodigo;
    _escolaridadeCodigo = a?.escolaridadeCodigo;
    _cidadeCodigo = a?.cidadeCodigo;
    _tipoCasa = a?.tipoCasa;
    _jaFezCursoSenacSenai = a?.jaFezCursoSenacSenai ?? false;
    _possuiNecessidadeEspecial = a?.possuiNecessidadeEspecial ?? false;
    _fazAcompanhamentoMedico = a?.fazAcompanhamentoMedico ?? false;

    for (final r in a?.rendasFamiliares ?? []) {
      _rendaLinhas.add(
        AlunoCapacitacaoRendaLinha(
          nome: r.nome,
          idade: r.idade?.toString() ?? '',
          renda: r.renda > 0 ? formatMoedaBr(r.renda) : '',
          parentesco: r.parentesco ?? '',
          profissao: r.profissao ?? '',
        ),
      );
    }
    _atualizarIdade();
    _loadReferencias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _nomeSocialController.dispose();
    _rgController.dispose();
    _orgaoExpedidorController.dispose();
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
    _valorAluguelController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _telefoneRecadoController.dispose();
    _emailController.dispose();
    _redeSocialController.dispose();
    _cursoSenacDescricaoController.dispose();
    _cursoSenacAnoController.dispose();
    _encaminhamentoController.dispose();
    _telefoneEncaminhamentoController.dispose();
    _qualNecessidadeController.dispose();
    _tomaMedicacaoController.dispose();
    _vacinacaoController.dispose();
    _alergiasController.dispose();
    for (final l in _rendaLinhas) {
      l.dispose();
    }
    super.dispose();
  }

  void _atualizarIdade() {
    final idade = calcularIdadeFromDataBr(_dtNascimentoController.text);
    _idadeController.text = idade?.toString() ?? '';
  }

  List<SearchableSelectOption<int?>> get _cidadeOptions => [
        const SearchableSelectOption<int?>(value: null, label: '—'),
        ..._cidades.map(
          (c) => SearchableSelectOption<int?>(
            value: c.codigo,
            label: '${c.nomeMunicipio} — ${c.estado}',
          ),
        ),
      ];

  List<SearchableSelectOption<int?>> get _escolaridadeOptions => [
        const SearchableSelectOption<int?>(value: null, label: '—'),
        ..._escolaridades.map(
          (e) => SearchableSelectOption<int?>(
            value: e.codigo,
            label: '${e.codigo} — ${e.descricao}',
          ),
        ),
      ];

  double get _rendaPerCapita {
    final linhas = _rendaLinhas.where((l) => l.preenchida).toList();
    if (linhas.isEmpty) return 0;
    var total = 0.0;
    for (final l in linhas) {
      total += parseMoedaBr(l.renda.text);
    }
    return total / linhas.length;
  }

  Future<void> _loadReferencias() async {
    try {
      final api = ref.read(apiClientProvider);
      final cidades = await api.listCidades(ativo: true);
      final escolaridades = await api.listEscolaridades(ativo: true);
      if (!mounted) return;
      cidades.sort((a, b) {
        final porNome = a.nomeMunicipio
            .toLowerCase()
            .compareTo(b.nomeMunicipio.toLowerCase());
        if (porNome != 0) return porNome;
        return a.estado.compareTo(b.estado);
      });
      escolaridades.sort((a, b) => a.codigo.compareTo(b.codigo));
      setState(() {
        _cidades = cidades;
        _escolaridades = escolaridades;
        _loadingRefs = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRefs = false);
        showErrorSnackBar(context, e.toString());
      }
    }
  }

  void _adicionarRendaLinha() {
    setState(() => _rendaLinhas.add(AlunoCapacitacaoRendaLinha()));
  }

  void _removerRendaLinha(int index) {
    setState(() {
      _rendaLinhas[index].dispose();
      _rendaLinhas.removeAt(index);
    });
  }

  String? _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoCasa == TipoCasaAlunoCapacitacao.aluguel) {
      formatarMoedaBrNoController(_valorAluguelController);
      if (parseMoedaBr(_valorAluguelController.text) <= 0) {
        showErrorSnackBar(context, 'Informe o valor do aluguel');
        _tabController.animateTo(0);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final rendas = <AlunoCapacitacaoRendaFamiliar>[];
      for (final linha in _rendaLinhas) {
        if (!linha.preenchida) continue;
        rendas.add(
          AlunoCapacitacaoRendaFamiliar(
            nome: linha.nome.text.trim(),
            idade: int.tryParse(linha.idade.text.trim()),
            renda: parseMoedaBr(linha.renda.text),
            parentesco: linha.parentesco.text.trim().isEmpty
                ? null
                : linha.parentesco.text.trim(),
            profissao: linha.profissao.text.trim().isEmpty
                ? null
                : linha.profissao.text.trim(),
          ),
        );
      }

      final payload = AlunoCapacitacao(
        id: widget.aluno?.id ?? '',
        nome: _nomeController.text.trim(),
        nomeSocial: _nomeSocialController.text.trim().isEmpty
            ? null
            : _nomeSocialController.text.trim(),
        estadoCivil: _estadoCivil,
        rg: _rgController.text.trim().isEmpty
            ? null
            : _onlyDigits(_rgController.text),
        orgaoExpedidor: _orgaoExpedidorController.text.trim().isEmpty
            ? null
            : _orgaoExpedidorController.text.trim(),
        cpf: _cpfController.text.trim().isEmpty
            ? null
            : _onlyDigits(_cpfController.text),
        dtNascimento: normalizarDataBr(_dtNascimentoController.text.trim()),
        nacionalidade: _nacionalidadeController.text.trim().isEmpty
            ? null
            : _nacionalidadeController.text.trim(),
        naturalidadeCodigo: _naturalidadeCodigo,
        nomeMae: _nomeMaeController.text.trim().isEmpty
            ? null
            : _nomeMaeController.text.trim(),
        nomePai: _nomePaiController.text.trim().isEmpty
            ? null
            : _nomePaiController.text.trim(),
        escolaridadeCodigo: _escolaridadeCodigo,
        nomeUltimaEscola: _nomeUltimaEscolaController.text.trim().isEmpty
            ? null
            : _nomeUltimaEscolaController.text.trim(),
        endereco: _enderecoController.text.trim().isEmpty
            ? null
            : _enderecoController.text.trim(),
        enderecoNumero: _enderecoNumeroController.text.trim().isEmpty
            ? null
            : _enderecoNumeroController.text.trim(),
        bairro: _bairroController.text.trim().isEmpty
            ? null
            : _bairroController.text.trim(),
        cep: _cepController.text.trim().isEmpty
            ? null
            : _onlyDigits(_cepController.text),
        cidadeCodigo: _cidadeCodigo,
        tipoCasa: _tipoCasa,
        valorAluguel: _tipoCasa == TipoCasaAlunoCapacitacao.aluguel
            ? parseMoedaBr(_valorAluguelController.text)
            : null,
        telefone: _telefoneController.text.trim().isEmpty
            ? null
            : _onlyDigits(_telefoneController.text),
        celular: _celularController.text.trim().isEmpty
            ? null
            : _onlyDigits(_celularController.text),
        telefoneRecado: _telefoneRecadoController.text.trim().isEmpty
            ? null
            : _onlyDigits(_telefoneRecadoController.text),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        redeSocial: _redeSocialController.text.trim().isEmpty
            ? null
            : _redeSocialController.text.trim(),
        jaFezCursoSenacSenai: _jaFezCursoSenacSenai,
        cursoSenacSenaiDescricao: _jaFezCursoSenacSenai
            ? _cursoSenacDescricaoController.text.trim()
            : null,
        cursoSenacSenaiAno: _jaFezCursoSenacSenai
            ? int.tryParse(_cursoSenacAnoController.text.trim())
            : null,
        encaminhamento: _encaminhamentoController.text.trim().isEmpty
            ? null
            : _encaminhamentoController.text.trim(),
        telefoneEncaminhamento:
            _telefoneEncaminhamentoController.text.trim().isEmpty
                ? null
                : _onlyDigits(_telefoneEncaminhamentoController.text),
        possuiNecessidadeEspecial: _possuiNecessidadeEspecial,
        qualNecessidade: _possuiNecessidadeEspecial
            ? _qualNecessidadeController.text.trim()
            : null,
        fazAcompanhamentoMedico: _fazAcompanhamentoMedico,
        tomaMedicacao: _fazAcompanhamentoMedico
            ? _tomaMedicacaoController.text.trim()
            : null,
        vacinacao: _vacinacaoController.text.trim().isEmpty
            ? null
            : _vacinacaoController.text.trim(),
        alergias: _alergiasController.text.trim().isEmpty
            ? null
            : _alergiasController.text.trim(),
        rendasFamiliares: rendas,
        ativo: widget.aluno?.ativo ?? true,
      );

      final api = ref.read(apiClientProvider);
      if (widget.isEditing) {
        await api.updateAlunoCapacitacao(payload);
        if (mounted) {
          showSuccessSnackBar(context, 'Aluno atualizado');
          Navigator.pop(context, true);
        }
      } else {
        final created = await api.createAlunoCapacitacao(payload);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auditoria', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Inclusão: ${formatDateTimeBr(a.dataHoraInclusao)}'
          '${a.usuarioInclusaoId != null ? ' · ${a.usuarioInclusaoId}' : ''}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Última alteração: ${formatDateTimeBr(a.dataHoraAlteracao)}'
          '${a.usuarioAlteracaoId != null ? ' · ${a.usuarioAlteracaoId}' : ''}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDadosPessoais() {
    if (_loadingRefs) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(labelText: 'Nome'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeSocialController,
            decoration: const InputDecoration(labelText: 'Nome social'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _estadoCivil,
            decoration: const InputDecoration(labelText: 'Estado civil'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('—'),
              ),
              ...EstadoCivilVoluntario.opcoes.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (v) => setState(() => _estadoCivil = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rgController,
            decoration: const InputDecoration(labelText: 'RG'),
            inputFormatters: [RgFormatter()],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _orgaoExpedidorController,
            decoration: const InputDecoration(labelText: 'Órgão expedidor'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cpfController,
            decoration: const InputDecoration(labelText: 'CPF'),
            keyboardType: TextInputType.number,
            inputFormatters: [CpfFormatter()],
            validator: validateCpfOpcional,
          ),
          const SizedBox(height: 12),
          TextFormField(
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
            decoration: const InputDecoration(labelText: 'Idade'),
            readOnly: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nacionalidadeController,
            decoration: const InputDecoration(labelText: 'Nacionalidade'),
          ),
          const SizedBox(height: 12),
          AppSearchableSelectField<int?>(
            label: 'Naturalidade (município)',
            value: _naturalidadeCodigo,
            options: _cidadeOptions,
            onChanged: (v) => setState(() => _naturalidadeCodigo = v),
            onCadastrar: () async {
              final r = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(builder: (_) => const CidadeFormScreen()),
              );
              if (r is Cidade) {
                await _loadReferencias();
                setState(() => _naturalidadeCodigo = r.codigo);
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeMaeController,
            decoration: const InputDecoration(labelText: 'Nome da mãe'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomePaiController,
            decoration: const InputDecoration(labelText: 'Nome do pai'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          AppSearchableSelectField<int?>(
            label: 'Código da escolaridade',
            value: _escolaridadeCodigo,
            options: _escolaridadeOptions,
            onChanged: (v) => setState(() => _escolaridadeCodigo = v),
            onCadastrar: () async {
              final r = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => const EscolaridadeFormScreen(),
                ),
              );
              if (r is Escolaridade) {
                await _loadReferencias();
                setState(() => _escolaridadeCodigo = r.codigo);
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomeUltimaEscolaController,
            decoration: const InputDecoration(labelText: 'Nome da última escola'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEnderecoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        16,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        TextFormField(
          controller: _enderecoController,
          decoration: const InputDecoration(labelText: 'Endereço'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _enderecoNumeroController,
          decoration: const InputDecoration(labelText: 'Número'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bairroController,
          decoration: const InputDecoration(labelText: 'Bairro'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cepController,
          decoration: const InputDecoration(labelText: 'CEP'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
        ),
        const SizedBox(height: 12),
        AppSearchableSelectField<int?>(
          label: 'Cidade (município)',
          value: _cidadeCodigo,
          options: _cidadeOptions,
          onChanged: (v) => setState(() => _cidadeCodigo = v),
          onCadastrar: () async {
            final r = await Navigator.of(context).push<Object?>(
              MaterialPageRoute(builder: (_) => const CidadeFormScreen()),
            );
            if (r is Cidade) {
              await _loadReferencias();
              setState(() => _cidadeCodigo = r.codigo);
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _tipoCasa,
          decoration: const InputDecoration(labelText: 'Tipo de casa'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            ...TipoCasaAlunoCapacitacao.opcoes.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: (v) => setState(() {
            _tipoCasa = v;
            if (v != TipoCasaAlunoCapacitacao.aluguel) {
              _valorAluguelController.clear();
            }
          }),
        ),
        if (_tipoCasa == TipoCasaAlunoCapacitacao.aluguel) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _valorAluguelController,
            decoration: const InputDecoration(labelText: 'Valor do aluguel'),
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _telefoneController,
          decoration: const InputDecoration(labelText: 'Telefone'),
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefoneFormatter()],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _celularController,
          decoration: const InputDecoration(labelText: 'Celular'),
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefoneFormatter()],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telefoneRecadoController,
          decoration: const InputDecoration(labelText: 'Telefone recado'),
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefoneFormatter()],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'E-mail'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _redeSocialController,
          decoration: const InputDecoration(labelText: 'Rede social'),
        ),
      ],
    );
  }

  Widget _buildAdicionaisTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        16,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        CheckboxListTile(
          value: _jaFezCursoSenacSenai,
          onChanged: (v) => setState(() => _jaFezCursoSenacSenai = v ?? false),
          title: Text(
            'Já fez cursos no Senac ou Senai',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_jaFezCursoSenacSenai) ...[
          TextFormField(
            controller: _cursoSenacDescricaoController,
            decoration: const InputDecoration(labelText: 'Curso'),
            validator: (v) => _jaFezCursoSenacSenai &&
                    (v == null || v.trim().isEmpty)
                ? 'Informe o curso'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cursoSenacAnoController,
            decoration: const InputDecoration(labelText: 'Ano'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => _jaFezCursoSenacSenai &&
                    (v == null || v.trim().isEmpty)
                ? 'Informe o ano'
                : null,
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _encaminhamentoController,
          decoration: const InputDecoration(labelText: 'Encaminhamento'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telefoneEncaminhamentoController,
          decoration: const InputDecoration(labelText: 'Telefone encaminhamento'),
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefoneFormatter()],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _possuiNecessidadeEspecial,
          onChanged: (v) =>
              setState(() => _possuiNecessidadeEspecial = v ?? false),
          title: Text(
            'Possui alguma necessidade especial',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_possuiNecessidadeEspecial) ...[
          TextFormField(
            controller: _qualNecessidadeController,
            decoration: const InputDecoration(labelText: 'Qual necessidade'),
            maxLines: 2,
            validator: (v) => _possuiNecessidadeEspecial &&
                    (v == null || v.trim().isEmpty)
                ? 'Descreva a necessidade'
                : null,
          ),
          const SizedBox(height: 12),
        ],
        CheckboxListTile(
          value: _fazAcompanhamentoMedico,
          onChanged: (v) =>
              setState(() => _fazAcompanhamentoMedico = v ?? false),
          title: Text(
            'Faz algum acompanhamento médico',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_fazAcompanhamentoMedico) ...[
          TextFormField(
            controller: _tomaMedicacaoController,
            decoration: const InputDecoration(labelText: 'Toma medicação'),
            maxLines: 2,
            validator: (v) => _fazAcompanhamentoMedico &&
                    (v == null || v.trim().isEmpty)
                ? 'Informe a medicação'
                : null,
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _vacinacaoController,
          decoration: const InputDecoration(labelText: 'Vacinação'),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _alergiasController,
          decoration: const InputDecoration(labelText: 'Alergias'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildRendaTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        16,
        AppLayout.screenPaddingH,
        16,
      ),
      children: [
        Text(
          'Informe os integrantes da renda familiar (sem vínculo com cadastro de assistidos).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.neutralGray,
              ),
        ),
        const SizedBox(height: 12),
        ..._rendaLinhas.asMap().entries.map((entry) {
          final i = entry.key;
          final linha = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Integrante ${i + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          onPressed: () => _removerRendaLinha(i),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: linha.nome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: linha.idade,
                            decoration:
                                const InputDecoration(labelText: 'Idade'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: linha.renda,
                            decoration:
                                const InputDecoration(labelText: 'Renda R\$'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: linha.parentesco,
                      decoration:
                          const InputDecoration(labelText: 'Parentesco'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: linha.profissao,
                      decoration: const InputDecoration(labelText: 'Profissão'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _adicionarRendaLinha,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar integrante'),
        ),
        const SizedBox(height: 24),
        Text(
          'Renda Per Capita R\$ ${formatMoedaBr(_rendaPerCapita)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppScreenChrome.appBar(
        context,
        title: widget.isEditing
            ? 'Editar aluno de capacitação'
            : 'Novo aluno de capacitação',
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(child: _buildDadosPessoais()),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              indicatorColor: AppColors.accentOrange,
              tabs: const [
                Tab(text: 'Endereço e Contato'),
                Tab(text: 'Informações Adicionais'),
                Tab(text: 'Renda Familiar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEnderecoTab(),
                  _buildAdicionaisTab(),
                  _buildRendaTab(),
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
