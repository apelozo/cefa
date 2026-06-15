import 'auditoria_campos.dart';

class Aluno {
  const Aluno({
    required this.id,
    required this.nome,
    this.nomeSocial,
    this.estadoCivil,
    this.estadoCivilRotulo,
    this.rg,
    this.rgFormatado,
    this.orgaoExpedidor,
    this.dtExpedicaoRg,
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
    this.cepFormatado,
    this.cidadeCodigo,
    this.cidadeNome,
    this.cidadeEstado,
    this.telefone,
    this.telefoneFormatado,
    this.celular,
    this.celularFormatado,
    this.telefoneRecado,
    this.telefoneRecadoFormatado,
    this.email,
    required this.ativo,
    this.auditoria = const AuditoriaCampos(),
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
  final String? dtExpedicaoRg;
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
  final String? cepFormatado;
  final int? cidadeCodigo;
  final String? cidadeNome;
  final String? cidadeEstado;
  final String? telefone;
  final String? telefoneFormatado;
  final String? celular;
  final String? celularFormatado;
  final String? telefoneRecado;
  final String? telefoneRecadoFormatado;
  final String? email;
  final bool ativo;
  final AuditoriaCampos auditoria;
  final String? usuarioInclusaoId;
  final DateTime? dataHoraInclusao;
  final String? usuarioAlteracaoId;
  final DateTime? dataHoraAlteracao;
  final DateTime? createdAt;

  factory Aluno.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String? v) =>
        v == null || v.isEmpty ? null : DateTime.tryParse(v);

    int? parseIntOpt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Aluno(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nomeSocial: json['nomeSocial'] as String?,
      estadoCivil: json['estadoCivil'] as String?,
      estadoCivilRotulo: json['estadoCivilRotulo'] as String?,
      rg: json['rg'] as String?,
      rgFormatado: json['rgFormatado'] as String?,
      orgaoExpedidor: json['orgaoExpedidor'] as String?,
      dtExpedicaoRg: json['dtExpedicaoRg'] as String?,
      cpf: json['cpf'] as String?,
      cpfFormatado: json['cpfFormatado'] as String?,
      dtNascimento: json['dtNascimento'] as String?,
      idade: parseIntOpt(json['idade']),
      nacionalidade: json['nacionalidade'] as String?,
      naturalidadeCodigo: parseIntOpt(json['naturalidadeCodigo']),
      naturalidadeNome: json['naturalidadeNome'] as String?,
      naturalidadeEstado: json['naturalidadeEstado'] as String?,
      nomeMae: json['nomeMae'] as String?,
      nomePai: json['nomePai'] as String?,
      escolaridadeCodigo: parseIntOpt(json['escolaridadeCodigo']),
      escolaridadeDescricao: json['escolaridadeDescricao'] as String?,
      nomeUltimaEscola: json['nomeUltimaEscola'] as String?,
      endereco: json['endereco'] as String?,
      enderecoNumero: json['enderecoNumero'] as String?,
      bairro: json['bairro'] as String?,
      cep: json['cep'] as String?,
      cepFormatado: json['cepFormatado'] as String?,
      cidadeCodigo: parseIntOpt(json['cidadeCodigo']),
      cidadeNome: json['cidadeNome'] as String?,
      cidadeEstado: json['cidadeEstado'] as String?,
      telefone: json['telefone'] as String?,
      telefoneFormatado: json['telefoneFormatado'] as String?,
      celular: json['celular'] as String?,
      celularFormatado: json['celularFormatado'] as String?,
      telefoneRecado: json['telefoneRecado'] as String?,
      telefoneRecadoFormatado: json['telefoneRecadoFormatado'] as String?,
      email: json['email'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      auditoria: AuditoriaCampos.fromJson(json),
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
        if (dtExpedicaoRg != null && dtExpedicaoRg!.trim().isNotEmpty)
          'dtExpedicaoRg': dtExpedicaoRg,
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
        if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
        if (celular != null && celular!.isNotEmpty) 'celular': celular,
        if (telefoneRecado != null && telefoneRecado!.isNotEmpty)
          'telefoneRecado': telefoneRecado,
        if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      };
}
