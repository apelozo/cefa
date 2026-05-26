import '../constants/tipo_casa_aluno_capacitacao.dart';
import 'aluno_capacitacao_renda_familiar.dart';

class AlunoCapacitacao {
  const AlunoCapacitacao({
    required this.id,
    required this.nome,
    this.nomeSocial,
    this.estadoCivil,
    this.estadoCivilRotulo,
    this.rg,
    this.rgFormatado,
    this.orgaoExpedidor,
    this.cpf,
    this.cpfFormatado,
    this.dtNascimento,
    this.idade,
    this.nacionalidade,
    this.naturalidadeCodigo,
    this.naturalidadeNome,
    this.naturalidadeEstado,
    this.nomeMae,
    this.nomePai,
    this.escolaridadeCodigo,
    this.escolaridadeDescricao,
    this.nomeUltimaEscola,
    this.endereco,
    this.enderecoNumero,
    this.bairro,
    this.cep,
    this.cidadeCodigo,
    this.cidadeNome,
    this.cidadeEstado,
    this.tipoCasa,
    this.tipoCasaRotulo,
    this.valorAluguel,
    this.telefone,
    this.celular,
    this.telefoneRecado,
    this.email,
    this.redeSocial,
    this.jaFezCursoSenacSenai = false,
    this.cursoSenacSenaiDescricao,
    this.cursoSenacSenaiAno,
    this.encaminhamento,
    this.telefoneEncaminhamento,
    this.possuiNecessidadeEspecial = false,
    this.qualNecessidade,
    this.fazAcompanhamentoMedico = false,
    this.tomaMedicacao,
    this.vacinacao,
    this.alergias,
    this.rendasFamiliares = const [],
    this.rendaPerCapita = 0,
    required this.ativo,
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.createdAt,
  });

  final String id;
  final String nome;
  final String? nomeSocial;
  final String? estadoCivil;
  final String? estadoCivilRotulo;
  final String? rg;
  final String? rgFormatado;
  final String? orgaoExpedidor;
  final String? cpf;
  final String? cpfFormatado;
  final String? dtNascimento;
  final int? idade;
  final String? nacionalidade;
  final int? naturalidadeCodigo;
  final String? naturalidadeNome;
  final String? naturalidadeEstado;
  final String? nomeMae;
  final String? nomePai;
  final int? escolaridadeCodigo;
  final String? escolaridadeDescricao;
  final String? nomeUltimaEscola;
  final String? endereco;
  final String? enderecoNumero;
  final String? bairro;
  final String? cep;
  final int? cidadeCodigo;
  final String? cidadeNome;
  final String? cidadeEstado;
  final String? tipoCasa;
  final String? tipoCasaRotulo;
  final double? valorAluguel;
  final String? telefone;
  final String? celular;
  final String? telefoneRecado;
  final String? email;
  final String? redeSocial;
  final bool jaFezCursoSenacSenai;
  final String? cursoSenacSenaiDescricao;
  final int? cursoSenacSenaiAno;
  final String? encaminhamento;
  final String? telefoneEncaminhamento;
  final bool possuiNecessidadeEspecial;
  final String? qualNecessidade;
  final bool fazAcompanhamentoMedico;
  final String? tomaMedicacao;
  final String? vacinacao;
  final String? alergias;
  final List<AlunoCapacitacaoRendaFamiliar> rendasFamiliares;
  final double rendaPerCapita;
  final bool ativo;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory AlunoCapacitacao.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final rendas = (json['rendasFamiliares'] as List<dynamic>? ?? [])
        .map(
          (e) => AlunoCapacitacaoRendaFamiliar.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    return AlunoCapacitacao(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nomeSocial: json['nomeSocial'] as String?,
      estadoCivil: json['estadoCivil'] as String?,
      estadoCivilRotulo: json['estadoCivilRotulo'] as String?,
      rg: json['rg'] as String?,
      rgFormatado: json['rgFormatado'] as String?,
      orgaoExpedidor: json['orgaoExpedidor'] as String?,
      cpf: json['cpf'] as String?,
      cpfFormatado: json['cpfFormatado'] as String?,
      dtNascimento: json['dtNascimento'] as String?,
      idade: json['idade'] == null
          ? null
          : (json['idade'] is int
              ? json['idade'] as int
              : int.tryParse(json['idade'].toString())),
      nacionalidade: json['nacionalidade'] as String?,
      naturalidadeCodigo: json['naturalidadeCodigo'] == null
          ? null
          : (json['naturalidadeCodigo'] is int
              ? json['naturalidadeCodigo'] as int
              : int.parse(json['naturalidadeCodigo'].toString())),
      naturalidadeNome: json['naturalidadeNome'] as String?,
      naturalidadeEstado: json['naturalidadeEstado'] as String?,
      nomeMae: json['nomeMae'] as String?,
      nomePai: json['nomePai'] as String?,
      escolaridadeCodigo: json['escolaridadeCodigo'] == null
          ? null
          : (json['escolaridadeCodigo'] is int
              ? json['escolaridadeCodigo'] as int
              : int.parse(json['escolaridadeCodigo'].toString())),
      escolaridadeDescricao: json['escolaridadeDescricao'] as String?,
      nomeUltimaEscola: json['nomeUltimaEscola'] as String?,
      endereco: json['endereco'] as String?,
      enderecoNumero: json['enderecoNumero'] as String?,
      bairro: json['bairro'] as String?,
      cep: json['cep'] as String?,
      cidadeCodigo: json['cidadeCodigo'] == null
          ? null
          : (json['cidadeCodigo'] is int
              ? json['cidadeCodigo'] as int
              : int.parse(json['cidadeCodigo'].toString())),
      cidadeNome: json['cidadeNome'] as String?,
      cidadeEstado: json['cidadeEstado'] as String?,
      tipoCasa: json['tipoCasa'] as String?,
      tipoCasaRotulo: json['tipoCasaRotulo'] as String?,
      valorAluguel: parseDouble(json['valorAluguel']),
      telefone: json['telefone'] as String?,
      celular: json['celular'] as String?,
      telefoneRecado: json['telefoneRecado'] as String?,
      email: json['email'] as String?,
      redeSocial: json['redeSocial'] as String?,
      jaFezCursoSenacSenai: json['jaFezCursoSenacSenai'] as bool? ?? false,
      cursoSenacSenaiDescricao: json['cursoSenacSenaiDescricao'] as String?,
      cursoSenacSenaiAno: json['cursoSenacSenaiAno'] == null
          ? null
          : (json['cursoSenacSenaiAno'] is int
              ? json['cursoSenacSenaiAno'] as int
              : int.tryParse(json['cursoSenacSenaiAno'].toString())),
      encaminhamento: json['encaminhamento'] as String?,
      telefoneEncaminhamento: json['telefoneEncaminhamento'] as String?,
      possuiNecessidadeEspecial:
          json['possuiNecessidadeEspecial'] as bool? ?? false,
      qualNecessidade: json['qualNecessidade'] as String?,
      fazAcompanhamentoMedico:
          json['fazAcompanhamentoMedico'] as bool? ?? false,
      tomaMedicacao: json['tomaMedicacao'] as String?,
      vacinacao: json['vacinacao'] as String?,
      alergias: json['alergias'] as String?,
      rendasFamiliares: rendas,
      rendaPerCapita: parseDouble(json['rendaPerCapita']) ?? 0,
      ativo: json['ativo'] as bool? ?? true,
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      createdAt: parseOpt(json['createdAt'] as String?),
    );
  }

  Map<String, dynamic> toSaveJson() => {
        'nome': nome.trim(),
        if (nomeSocial != null && nomeSocial!.trim().isNotEmpty)
          'nomeSocial': nomeSocial!.trim(),
        if (estadoCivil != null) 'estadoCivil': estadoCivil,
        if (rg != null && rg!.isNotEmpty) 'rg': rg,
        if (orgaoExpedidor != null && orgaoExpedidor!.trim().isNotEmpty)
          'orgaoExpedidor': orgaoExpedidor!.trim(),
        if (cpf != null && cpf!.isNotEmpty) 'cpf': cpf,
        'dtNascimento': dtNascimento,
        if (nacionalidade != null && nacionalidade!.trim().isNotEmpty)
          'nacionalidade': nacionalidade!.trim(),
        if (naturalidadeCodigo != null)
          'naturalidadeCodigo': naturalidadeCodigo,
        if (nomeMae != null && nomeMae!.trim().isNotEmpty)
          'nomeMae': nomeMae!.trim(),
        if (nomePai != null && nomePai!.trim().isNotEmpty)
          'nomePai': nomePai!.trim(),
        if (escolaridadeCodigo != null)
          'escolaridadeCodigo': escolaridadeCodigo,
        if (nomeUltimaEscola != null && nomeUltimaEscola!.trim().isNotEmpty)
          'nomeUltimaEscola': nomeUltimaEscola!.trim(),
        if (endereco != null && endereco!.trim().isNotEmpty)
          'endereco': endereco!.trim(),
        if (enderecoNumero != null && enderecoNumero!.trim().isNotEmpty)
          'enderecoNumero': enderecoNumero!.trim(),
        if (bairro != null && bairro!.trim().isNotEmpty) 'bairro': bairro!.trim(),
        if (cep != null && cep!.isNotEmpty) 'cep': cep,
        if (cidadeCodigo != null) 'cidadeCodigo': cidadeCodigo,
        if (tipoCasa != null) 'tipoCasa': tipoCasa,
        if (tipoCasa == TipoCasaAlunoCapacitacao.aluguel && valorAluguel != null)
          'valorAluguel': valorAluguel,
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
        if (celular != null && celular!.isNotEmpty) 'celular': celular,
        if (telefoneRecado != null && telefoneRecado!.isNotEmpty)
          'telefoneRecado': telefoneRecado,
        if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
        if (redeSocial != null && redeSocial!.trim().isNotEmpty)
          'redeSocial': redeSocial!.trim(),
        'jaFezCursoSenacSenai': jaFezCursoSenacSenai,
        if (jaFezCursoSenacSenai) ...{
          if (cursoSenacSenaiDescricao != null &&
              cursoSenacSenaiDescricao!.trim().isNotEmpty)
            'cursoSenacSenaiDescricao': cursoSenacSenaiDescricao!.trim(),
          if (cursoSenacSenaiAno != null) 'cursoSenacSenaiAno': cursoSenacSenaiAno,
        },
        if (encaminhamento != null && encaminhamento!.trim().isNotEmpty)
          'encaminhamento': encaminhamento!.trim(),
        if (telefoneEncaminhamento != null && telefoneEncaminhamento!.isNotEmpty)
          'telefoneEncaminhamento': telefoneEncaminhamento,
        'possuiNecessidadeEspecial': possuiNecessidadeEspecial,
        if (possuiNecessidadeEspecial &&
            qualNecessidade != null &&
            qualNecessidade!.trim().isNotEmpty)
          'qualNecessidade': qualNecessidade!.trim(),
        'fazAcompanhamentoMedico': fazAcompanhamentoMedico,
        if (fazAcompanhamentoMedico &&
            tomaMedicacao != null &&
            tomaMedicacao!.trim().isNotEmpty)
          'tomaMedicacao': tomaMedicacao!.trim(),
        if (vacinacao != null && vacinacao!.trim().isNotEmpty)
          'vacinacao': vacinacao!.trim(),
        if (alergias != null && alergias!.trim().isNotEmpty)
          'alergias': alergias!.trim(),
        'rendasFamiliares':
            rendasFamiliares.map((r) => r.toJson()).toList(),
      };
}
