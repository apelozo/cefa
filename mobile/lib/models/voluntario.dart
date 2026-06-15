import 'auditoria_campos.dart';

class Voluntario {
  const Voluntario({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.nomeCracha,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
    this.empresa,
    this.funcao,
    this.estadoCivil,
    this.estadoCivilRotulo,
    this.dtNascimento,
    this.endereco,
    this.enderecoNumero,
    this.bairro,
    this.cep,
    this.cidadeCodigo,
    this.cidadeNome,
    this.cidadeEstado,
    this.enderecoComplemento,
    this.rg,
    this.cpf,
    this.cnh,
    this.celular,
    this.telefoneResidencial,
    this.telefoneComercial,
    this.email,
    this.valorContribuicao,
    this.diaVencimento,
    this.tempoTrabalhoCentro,
    this.fichaMedica,
    this.usuarioInclusaoId,
    this.dataHoraInclusao,
    this.usuarioAlteracaoId,
    this.dataHoraAlteracao,
    this.createdAt,
  });

  final String id;
  final int codigo;
  final String nome;
  final String nomeCracha;
  final bool ativo;
  final AuditoriaCampos auditoria;
  final String? empresa;
  final String? funcao;
  final String? estadoCivil;
  final String? estadoCivilRotulo;
  final String? dtNascimento;
  final String? endereco;
  final String? enderecoNumero;
  final String? bairro;
  final String? cep;
  final int? cidadeCodigo;
  final String? cidadeNome;
  final String? cidadeEstado;
  final String? enderecoComplemento;
  final String? rg;
  final String? cpf;
  final String? cnh;
  final String? celular;
  final String? telefoneResidencial;
  final String? telefoneComercial;
  final String? email;
  final String? valorContribuicao;
  final int? diaVencimento;
  final int? tempoTrabalhoCentro;
  final String? fichaMedica;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory Voluntario.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    int? parseIntOpt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final codigoRaw = json['codigo'];
    final codigo = codigoRaw is int
        ? codigoRaw
        : int.parse(codigoRaw.toString());

    return Voluntario(
      id: json['id'] as String,
      codigo: codigo,
      nome: json['nome'] as String,
      nomeCracha: json['nomeCracha'] as String,
      ativo: json['ativo'] as bool,
      auditoria: AuditoriaCampos.fromJson(json),
      empresa: json['empresa'] as String?,
      funcao: json['funcao'] as String?,
      estadoCivil: json['estadoCivil'] as String?,
      estadoCivilRotulo: json['estadoCivilRotulo'] as String?,
      dtNascimento: json['dtNascimento'] as String?,
      endereco: json['endereco'] as String?,
      enderecoNumero: json['enderecoNumero'] as String?,
      bairro: json['bairro'] as String?,
      cep: json['cep'] as String?,
      cidadeCodigo: parseIntOpt(json['cidadeCodigo']),
      cidadeNome: json['cidadeNome'] as String?,
      cidadeEstado: json['cidadeEstado'] as String?,
      enderecoComplemento: json['enderecoComplemento'] as String?,
      rg: json['rg'] as String?,
      cpf: json['cpf'] as String?,
      cnh: json['cnh'] as String?,
      celular: json['celular'] as String?,
      telefoneResidencial: json['telefoneResidencial'] as String?,
      telefoneComercial: json['telefoneComercial'] as String?,
      email: json['email'] as String?,
      valorContribuicao: json['valorContribuicao']?.toString(),
      diaVencimento: parseIntOpt(json['diaVencimento']),
      tempoTrabalhoCentro: parseIntOpt(json['tempoTrabalhoCentro']),
      fichaMedica: json['fichaMedica'] as String?,
      usuarioInclusaoId: json['usuarioInclusaoId'] as String?,
      dataHoraInclusao: parseOpt(json['dataHoraInclusao'] as String?),
      usuarioAlteracaoId: json['usuarioAlteracaoId'] as String?,
      dataHoraAlteracao: parseOpt(json['dataHoraAlteracao'] as String?),
      createdAt: parseOpt(json['createdAt'] as String?),
    );
  }

  Map<String, dynamic> _camposJson() => {
        if (empresa != null) 'empresa': empresa,
        if (funcao != null) 'funcao': funcao,
        if (estadoCivil != null) 'estadoCivil': estadoCivil,
        if (dtNascimento != null) 'dtNascimento': dtNascimento,
        if (endereco != null) 'endereco': endereco,
        if (enderecoNumero != null) 'enderecoNumero': enderecoNumero,
        if (bairro != null) 'bairro': bairro,
        if (cep != null) 'cep': cep,
        if (cidadeCodigo != null) 'cidadeCodigo': cidadeCodigo,
        if (enderecoComplemento != null) 'enderecoComplemento': enderecoComplemento,
        if (rg != null) 'rg': rg,
        if (cpf != null) 'cpf': cpf,
        if (cnh != null) 'cnh': cnh,
        if (celular != null) 'celular': celular,
        if (telefoneResidencial != null) 'telefoneResidencial': telefoneResidencial,
        if (telefoneComercial != null) 'telefoneComercial': telefoneComercial,
        if (email != null) 'email': email,
        if (valorContribuicao != null) 'valorContribuicao': valorContribuicao,
        if (diaVencimento != null) 'diaVencimento': diaVencimento,
        if (tempoTrabalhoCentro != null) 'tempoTrabalhoCentro': tempoTrabalhoCentro,
        if (fichaMedica != null) 'fichaMedica': fichaMedica,
      };

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
        'nomeCracha': nomeCracha,
        ..._camposJson(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'nomeCracha': nomeCracha,
        ..._camposJson(),
        'empresa': empresa,
        'funcao': funcao,
        'estadoCivil': estadoCivil,
        'dtNascimento': dtNascimento,
        'endereco': endereco,
        'enderecoNumero': enderecoNumero,
        'bairro': bairro,
        'cep': cep,
        'cidadeCodigo': cidadeCodigo,
        'enderecoComplemento': enderecoComplemento,
        'rg': rg,
        'cpf': cpf,
        'cnh': cnh,
        'celular': celular,
        'telefoneResidencial': telefoneResidencial,
        'telefoneComercial': telefoneComercial,
        'email': email,
        'valorContribuicao': valorContribuicao,
        'diaVencimento': diaVencimento,
        'tempoTrabalhoCentro': tempoTrabalhoCentro,
        'fichaMedica': fichaMedica,
      };
}
