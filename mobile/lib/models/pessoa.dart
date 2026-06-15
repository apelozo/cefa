import 'auditoria_campos.dart';

class Pessoa {
  const Pessoa({
    required this.id,
    required this.nome,
    this.nomeSocial,
    this.nomeMae,
    this.nomePai,
    required this.dtNascimento,
    required this.cpf,
    this.cpfFormatado,
    required this.rg,
    this.rgFormatado,
    this.rgOrgaoEmissao,
    this.nis,
    this.endereco,
    this.enderecoNumero,
    this.enderecoComplemento,
    this.bairroCodigo,
    this.bairroNome,
    this.cidadeCodigo,
    this.cidadeNome,
    this.cidadeEstado,
    this.telefone,
    this.telefoneFormatado,
    this.telefone2,
    this.telefone2Formatado,
    this.urbanoRural,
    required this.ativo,
    required this.createdAt,
    this.auditoria = const AuditoriaCampos(),
  });

  final String id;
  final String nome;
  final String? nomeSocial;
  final String? nomeMae;
  final String? nomePai;
  final String dtNascimento;
  final String cpf;
  final String? cpfFormatado;
  final String rg;
  final String? rgFormatado;
  final String? rgOrgaoEmissao;
  final String? nis;
  final String? endereco;
  final String? enderecoNumero;
  final String? enderecoComplemento;
  final int? bairroCodigo;
  final String? bairroNome;
  final int? cidadeCodigo;
  final String? cidadeNome;
  final String? cidadeEstado;
  final String? telefone;
  final String? telefoneFormatado;
  final String? telefone2;
  final String? telefone2Formatado;
  final String? urbanoRural;
  final bool ativo;
  final DateTime createdAt;
  final AuditoriaCampos auditoria;

  String get cpfExibicao => cpfFormatado ?? cpf;
  String get rgExibicao => rgFormatado ?? rg;
  String get nomeExibicao =>
      (nomeSocial != null && nomeSocial!.trim().isNotEmpty) ? nomeSocial! : nome;

  String? get municipioExibicao {
    if (cidadeNome == null || cidadeNome!.isEmpty) return null;
    if (cidadeEstado != null && cidadeEstado!.isNotEmpty) {
      return '$cidadeNome — $cidadeEstado';
    }
    return cidadeNome;
  }

  factory Pessoa.fromJson(Map<String, dynamic> json) {
    return Pessoa(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nomeSocial: json['nomeSocial'] as String?,
      nomeMae: json['nomeMae'] as String?,
      nomePai: json['nomePai'] as String?,
      dtNascimento: json['dtNascimento'] as String,
      cpf: json['cpf'] as String,
      cpfFormatado: json['cpfFormatado'] as String?,
      rg: json['rg'] as String,
      rgFormatado: json['rgFormatado'] as String?,
      rgOrgaoEmissao: json['rgOrgaoEmissao'] as String?,
      nis: json['nis'] as String?,
      endereco: json['endereco'] as String?,
      enderecoNumero: json['enderecoNumero'] as String?,
      enderecoComplemento: json['enderecoComplemento'] as String?,
      bairroCodigo: json['bairroCodigo'] == null
          ? null
          : (json['bairroCodigo'] is int
              ? json['bairroCodigo'] as int
              : int.tryParse(json['bairroCodigo'].toString())),
      bairroNome: json['bairroNome'] as String?,
      cidadeCodigo: json['cidadeCodigo'] == null
          ? null
          : (json['cidadeCodigo'] is int
              ? json['cidadeCodigo'] as int
              : int.tryParse(json['cidadeCodigo'].toString())),
      cidadeNome: json['cidadeNome'] as String?,
      cidadeEstado: json['cidadeEstado'] as String?,
      telefone: json['telefone'] as String?,
      telefoneFormatado: json['telefoneFormatado'] as String?,
      telefone2: json['telefone2'] as String?,
      telefone2Formatado: json['telefone2Formatado'] as String?,
      urbanoRural: json['urbanoRural'] as String?,
      ativo: json['ativo'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      auditoria: AuditoriaCampos.fromJson(json),
    );
  }

  Map<String, dynamic> _camposOpcionais() => {
        if (nomeSocial != null) 'nomeSocial': nomeSocial,
        if (nomeMae != null) 'nomeMae': nomeMae,
        if (nomePai != null) 'nomePai': nomePai,
        if (rgOrgaoEmissao != null) 'rgOrgaoEmissao': rgOrgaoEmissao,
        if (nis != null) 'nis': nis,
        if (endereco != null) 'endereco': endereco,
        if (enderecoNumero != null) 'enderecoNumero': enderecoNumero,
        if (enderecoComplemento != null) 'enderecoComplemento': enderecoComplemento,
        if (bairroCodigo != null) 'bairroCodigo': bairroCodigo,
        if (cidadeCodigo != null) 'cidadeCodigo': cidadeCodigo,
        if (telefone != null) 'telefone': telefone,
        if (telefone2 != null) 'telefone2': telefone2,
        if (urbanoRural != null) 'urbanoRural': urbanoRural,
      };

  Map<String, dynamic> toCreateJson() => {
        'nome': nome,
        'dtNascimento': dtNascimento,
        'cpf': cpf,
        'rg': rg,
        'ativo': ativo,
        ..._camposOpcionais(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'nome': nome,
        'dtNascimento': dtNascimento,
        'cpf': cpf,
        'rg': rg,
        'ativo': ativo,
        ..._camposOpcionais(),
        'nomeSocial': nomeSocial,
        'nomeMae': nomeMae,
        'nomePai': nomePai,
        'rgOrgaoEmissao': rgOrgaoEmissao,
        'nis': nis,
        'endereco': endereco,
        'enderecoNumero': enderecoNumero,
        'enderecoComplemento': enderecoComplemento,
        'bairroCodigo': bairroCodigo,
        'cidadeCodigo': cidadeCodigo,
        'telefone': telefone,
        'telefone2': telefone2,
        'urbanoRural': urbanoRural,
      };
}

