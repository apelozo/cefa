import '../constants/urbano_rural.dart';
import '../models/entrevista_assistido.dart';
import '../models/entrevista_composicao_familiar.dart';
import '../models/entrevista_condicao_educacional.dart';
import '../models/entrevista_condicao_trabalho.dart';
import '../models/entrevista_deficiencia_familiar.dart';
import '../models/entrevista_gestante_familiar.dart';
import '../models/pessoa.dart';
import 'cpf_formatter.dart';
import 'moeda_br.dart';

/// Resolve chaves do YAML (`pessoa.nome`, `composicao.linha1.cpf`, …) para texto ou marcador.
class EntrevistaPdfFieldResolver {
  EntrevistaPdfFieldResolver({
    required this.entrevista,
    required this.pessoa,
  });

  final EntrevistaAssistido entrevista;
  final Pessoa pessoa;

  bool isMarcadorAtivo(String chave) {
    if (chave.startsWith('forma.')) {
      final codigo = chave.substring('forma.'.length);
      return entrevista.formasAcesso.any((f) => f.formaAcesso == codigo);
    }

    if (chave.startsWith('programas.')) {
      final campo = chave.substring('programas.'.length);
      return _valorProgramaBool(campo) == true;
    }

    final saudeSimNao = RegExp(
      r'^saude\.(\w+)\.(SIM|NAO)$',
    ).firstMatch(chave);
    if (saudeSimNao != null) {
      final campo = saudeSimNao.group(1)!;
      final esperado = saudeSimNao.group(2)!;
      final valor = _valorSaude(campo);
      return valor != null && valor.toUpperCase() == esperado;
    }

    final educMarcador = RegExp(
      r'^educacional\.linha(\d+)\.(sabeLerEscrever|frequentaEscola)(?:\.(SIM|NAO))?$',
    ).firstMatch(chave);
    if (educMarcador != null) {
      final linha = _educacionalLinha(int.parse(educMarcador.group(1)!));
      if (linha == null) return false;
      final valor = educMarcador.group(2) == 'sabeLerEscrever'
          ? linha.sabeLerEscrever
          : linha.frequentaEscola;
      return _marcadorBoolSimNao(valor, educMarcador.group(3));
    }

    final defMarcador = RegExp(
      r'^deficiencia\.linha(\d+)\.necessitaCuidadosConstantes(?:\.(SIM|NAO))?$',
    ).firstMatch(chave);
    if (defMarcador != null) {
      final linha = _deficienciaLinha(int.parse(defMarcador.group(1)!));
      if (linha == null) return false;
      return _marcadorBoolSimNao(
        linha.necessitaCuidadosConstantes,
        defMarcador.group(2),
      );
    }

    final gestPreNatal = RegExp(
      r'^gestante\.linha(\d+)\.iniciouPreNatal\.(SIM|NAO)$',
    ).firstMatch(chave);
    if (gestPreNatal != null) {
      final linha = _gestanteLinha(int.parse(gestPreNatal.group(1)!));
      if (linha == null) return false;
      final esperado = gestPreNatal.group(2)!;
      return linha.iniciouPreNatal.toUpperCase() == esperado;
    }

    if (chave == 'pessoa.urbanoRural.URBANO') {
      return pessoa.urbanoRural == UrbanoRural.urbano;
    }
    if (chave == 'pessoa.urbanoRural.RURAL') {
      return pessoa.urbanoRural == UrbanoRural.rural;
    }

    return false;
  }

  String? resolveTexto(String chave) {
    if (isMarcadorField(chave)) return null;

    if (chave.startsWith('pessoa.')) {
      return _resolvePessoa(chave.substring('pessoa.'.length));
    }
    if (chave.startsWith('entrevista.')) {
      return _resolveEntrevista(chave.substring('entrevista.'.length));
    }
    if (chave.startsWith('composicao.')) {
      return _resolveComposicao(chave.substring('composicao.'.length));
    }
    if (chave.startsWith('trabalho.')) {
      return _resolveTrabalho(chave.substring('trabalho.'.length));
    }
    if (chave.startsWith('educacional.')) {
      return _resolveEducacional(chave.substring('educacional.'.length));
    }
    if (chave.startsWith('deficiencia.')) {
      return _resolveDeficiencia(chave.substring('deficiencia.'.length));
    }
    if (chave.startsWith('gestante.')) {
      return _resolveGestante(chave.substring('gestante.'.length));
    }
    if (chave.startsWith('saude.')) {
      return _resolveSaude(chave.substring('saude.'.length));
    }
    if (chave.startsWith('programas.')) {
      return _resolveProgramas(chave.substring('programas.'.length));
    }
    return null;
  }

  static bool isMarcadorField(String chave) {
    if (chave.startsWith('forma.')) return true;
    if (chave.startsWith('programas.')) {
      return chave != 'programas.outrosProgramasSociais' &&
          chave != 'programas.outrosOrgaosSociais';
    }
    if (RegExp(r'^saude\.\w+\.(SIM|NAO)$').hasMatch(chave)) return true;
    if (RegExp(r'^gestante\.linha\d+\.iniciouPreNatal\.(SIM|NAO)$').hasMatch(chave)) {
      return true;
    }
    if (chave.contains('.sabeLerEscrever') || chave.contains('.frequentaEscola')) {
      return true;
    }
    if (chave.contains('.necessitaCuidadosConstantes')) return true;
    if (chave == 'pessoa.urbanoRural.URBANO' || chave == 'pessoa.urbanoRural.RURAL') {
      return true;
    }
    return false;
  }

  String? _resolvePessoa(String campo) {
    switch (campo) {
      case 'nome':
        return pessoa.nome;
      case 'nomeSocial':
        return _vazioNull(pessoa.nomeSocial);
      case 'nomeMae':
        return _vazioNull(pessoa.nomeMae);
      case 'nomePai':
        return _vazioNull(pessoa.nomePai);
      case 'dtNascimento':
        return pessoa.dtNascimento;
      case 'cpf':
        return pessoa.cpf;
      case 'cpfFormatado':
        return pessoa.cpfFormatado ?? formatCpfDisplay(pessoa.cpf);
      case 'rg':
        return pessoa.rg;
      case 'rgFormatado':
        return pessoa.rgFormatado ?? pessoa.rg;
      case 'rgOrgaoEmissao':
        return _vazioNull(pessoa.rgOrgaoEmissao);
      case 'nis':
        return _vazioNull(pessoa.nis);
      case 'endereco':
        return _vazioNull(pessoa.endereco);
      case 'enderecoNumero':
        return _vazioNull(pessoa.enderecoNumero);
      case 'enderecoComplemento':
        return _vazioNull(pessoa.enderecoComplemento);
      case 'bairroCodigo':
        return pessoa.bairroCodigo?.toString();
      case 'bairroNome':
        return _vazioNull(pessoa.bairroNome);
      case 'cidadeCodigo':
        return pessoa.cidadeCodigo?.toString();
      case 'cidadeNome':
        return _vazioNull(pessoa.cidadeNome);
      case 'cidadeEstado':
        return _vazioNull(pessoa.cidadeEstado);
      case 'municipioExibicao':
        return _vazioNull(pessoa.municipioExibicao);
      case 'telefone':
        return _vazioNull(pessoa.telefone);
      case 'telefoneFormatado':
        return _vazioNull(pessoa.telefoneFormatado ?? pessoa.telefone);
      case 'telefone2':
        return _vazioNull(pessoa.telefone2);
      case 'telefone2Formatado':
        return _vazioNull(pessoa.telefone2Formatado ?? pessoa.telefone2);
      case 'urbanoRuralRotulo':
        final v = pessoa.urbanoRural;
        if (v == null) return null;
        for (final o in UrbanoRural.opcoes) {
          if (o.valor == v) return o.rotulo;
        }
        return v;
      case 'ativo':
        return pessoa.ativo ? 'Sim' : 'Não';
      default:
        return null;
    }
  }

  String? _resolveEntrevista(String campo) {
    switch (campo) {
      case 'dataEntrevista':
        return entrevista.dataEntrevista;
      case 'outrosTexto':
        return _vazioNull(entrevista.outrosTexto);
      default:
        return null;
    }
  }

  String? _resolveComposicao(String resto) {
    final m = RegExp(r'^linha(\d+)\.(.+)$').firstMatch(resto);
    if (m == null) return null;
    final linha = _composicaoLinha(int.parse(m.group(1)!));
    if (linha == null) return null;
    switch (m.group(2)) {
      case 'nome':
        return linha.nome;
      case 'cpf':
        final c = linha.cpf;
        if (c == null || c.isEmpty) return null;
        return formatCpfDisplay(c);
      case 'dtNascimento':
        return linha.dtNascimento;
      case 'parentesco':
        return linha.parentesco;
      default:
        return null;
    }
  }

  String? _resolveTrabalho(String resto) {
    if (resto == 'rendaTotal') {
      return formatMoedaBr(_rendaTotal);
    }
    if (resto == 'rendaPerCapita') {
      return formatMoedaBr(_rendaPerCapita);
    }
    final m = RegExp(r'^linha(\d+)\.(.+)$').firstMatch(resto);
    if (m == null) return null;
    final linha = _trabalhoLinha(int.parse(m.group(1)!));
    if (linha == null) return null;
    switch (m.group(2)) {
      case 'nome':
        return linha.nome;
      case 'ocupacao':
        return linha.ocupacaoEnum?.rotulo ?? linha.ocupacao;
      case 'condicoesTrabalho':
        return _vazioNull(linha.condicoesTrabalho);
      case 'vrBeneficioSocial':
        return formatMoedaBr(parseMoedaBr(linha.vrBeneficioSocial));
      case 'rendaMensal':
        return formatMoedaBr(parseMoedaBr(linha.rendaMensal));
      default:
        return null;
    }
  }

  String? _resolveEducacional(String resto) {
    final m = RegExp(r'^linha(\d+)\.(.+)$').firstMatch(resto);
    if (m == null) return null;
    final linha = _educacionalLinha(int.parse(m.group(1)!));
    if (linha == null) return null;
    switch (m.group(2)) {
      case 'nome':
        return linha.nome;
      case 'idade':
        return linha.idade.toString();
      case 'escolaridade':
        return linha.escolaridadeRotulo ??
            linha.escolaridadeCodigo.toString();
      default:
        return null;
    }
  }

  String? _resolveGestante(String resto) {
    final m = RegExp(r'^linha(\d+)\.(.+)$').firstMatch(resto);
    if (m == null) return null;
    final linha = _gestanteLinha(int.parse(m.group(1)!));
    if (linha == null) return null;
    switch (m.group(2)) {
      case 'nome':
        return linha.nome;
      case 'mesesGestacao':
        return linha.mesesGestacao.toString();
      default:
        return null;
    }
  }

  String? _resolveDeficiencia(String resto) {
    final m = RegExp(r'^linha(\d+)\.(.+)$').firstMatch(resto);
    if (m == null) return null;
    final linha = _deficienciaLinha(int.parse(m.group(1)!));
    if (linha == null) return null;
    switch (m.group(2)) {
      case 'nome':
        return linha.nome;
      case 'tipoDeficiencia':
        return linha.tipoEnum?.rotulo ?? linha.tipoDeficiencia;
      case 'quemECuidador':
        return _vazioNull(linha.quemECuidador);
      default:
        return null;
    }
  }

  String? _resolveProgramas(String campo) {
    final ps = entrevista.programasSociais;
    switch (campo) {
      case 'outrosProgramasSociais':
        return _vazioNull(ps.outrosProgramasSociais);
      case 'outrosOrgaosSociais':
        return _vazioNull(ps.outrosOrgaosSociais);
      default:
        return null;
    }
  }

  bool? _valorProgramaBool(String campo) {
    final ps = entrevista.programasSociais;
    switch (campo) {
      case 'bolsaFamilia':
        return ps.bolsaFamilia;
      case 'peti':
        return ps.peti;
      case 'bpc':
        return ps.bpc;
      case 'outrosProgramas':
        return ps.outrosProgramas;
      case 'cras':
        return ps.cras;
      case 'centroPop':
        return ps.centroPop;
      case 'conselhoTutelar':
        return ps.conselhoTutelar;
      case 'ubs':
        return ps.ubs;
      case 'creas':
        return ps.creas;
      case 'caps':
        return ps.caps;
      case 'craf':
        return ps.craf;
      case 'outrosAtendimentoFamilia':
        return ps.outrosAtendimentoFamilia;
      default:
        return null;
    }
  }

  String? _resolveSaude(String campo) {
    final s = entrevista.saudeFamilia;
    final primeiraGestante = _gestanteLinha(1);
    switch (campo) {
      case 'remediosControladosQuais':
        return _vazioNull(s.remediosControladosQuais);
      case 'usoAbusivoDrogasQuais':
        return _vazioNull(s.usoAbusivoDrogasQuais);
      case 'gestanteNome':
        return primeiraGestante == null
            ? null
            : _vazioNull(primeiraGestante.nome);
      case 'gestanteMesesGestacao':
        return primeiraGestante?.mesesGestacao.toString();
      default:
        return null;
    }
  }

  String? _valorSaude(String campo) {
    final s = entrevista.saudeFamilia;
    final primeiraGestante = _gestanteLinha(1);
    switch (campo) {
      case 'remediosControladosMental':
        return s.remediosControladosMental;
      case 'usoAbusivoAlcool':
        return s.usoAbusivoAlcool;
      case 'usoAbusivoDrogas':
        return s.usoAbusivoDrogas;
      case 'temGestante':
        return s.temGestante;
      case 'gestanteIniciouPreNatal':
        return primeiraGestante?.iniciouPreNatal;
      default:
        return null;
    }
  }

  EntrevistaComposicaoFamiliar? _composicaoLinha(int numero) {
    final idx = numero - 1;
    final list = [...entrevista.composicaoFamiliar]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  EntrevistaCondicaoTrabalho? _trabalhoLinha(int numero) {
    final idx = numero - 1;
    final list = [...entrevista.condicoesTrabalho]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  EntrevistaCondicaoEducacional? _educacionalLinha(int numero) {
    final idx = numero - 1;
    final list = [...entrevista.condicoesEducacionais]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  EntrevistaDeficienciaFamiliar? _deficienciaLinha(int numero) {
    final idx = numero - 1;
    final list = [...entrevista.deficienciasFamilia]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  EntrevistaGestanteFamiliar? _gestanteLinha(int numero) {
    final idx = numero - 1;
    final list = [...entrevista.gestantesFamilia]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    if (idx < 0 || idx >= list.length) return null;
    return list[idx];
  }

  double get _rendaTotal {
    var total = 0.0;
    for (final linha in entrevista.condicoesTrabalho) {
      total += parseMoedaBr(linha.vrBeneficioSocial);
      total += parseMoedaBr(linha.rendaMensal);
    }
    return total;
  }

  double get _rendaPerCapita {
    final qtd = entrevista.composicaoFamiliar
        .where((c) => c.nome.trim().isNotEmpty)
        .length;
    if (qtd == 0) return 0;
    return _rendaTotal / qtd;
  }

  static String? _vazioNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Campos booleanos no YAML: `.SIM` / `.NAO` em posições distintas.
  /// Sem sufixo (legado): marca só quando [valor] é true.
  static bool _marcadorBoolSimNao(bool valor, String? sufixo) {
    if (sufixo == null) return valor;
    if (sufixo == 'SIM') return valor;
    return !valor;
  }
}
