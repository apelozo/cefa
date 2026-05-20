import 'package:flutter/material.dart';

import '../../constants/escolaridade_familiar.dart';
import '../../constants/ocupacao_familiar.dart';
import '../../constants/resposta_sim_nao.dart';
import '../../constants/tipo_deficiencia_familiar.dart';
import '../../models/entrevista_composicao_familiar.dart';
import '../../models/entrevista_condicao_educacional.dart';
import '../../models/entrevista_condicao_trabalho.dart';
import '../../models/entrevista_deficiencia_familiar.dart';
import '../../models/entrevista_gestante_familiar.dart';
import '../../models/entrevista_saude_familia.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/data_br_formatter.dart';
import '../../utils/moeda_br.dart';

class ComposicaoFamiliarLinha {
  ComposicaoFamiliarLinha()
      : nome = TextEditingController(),
        cpf = TextEditingController(),
        dtNascimento = TextEditingController(),
        parentesco = TextEditingController(),
        focusNome = FocusNode(),
        focusCpf = FocusNode(),
        focusDtNascimento = FocusNode(),
        focusParentesco = FocusNode();

  ComposicaoFamiliarLinha.fromItem(EntrevistaComposicaoFamiliar item)
      : nome = TextEditingController(text: item.nome),
        cpf = TextEditingController(
          text: item.cpf != null ? formatCpfDisplay(item.cpf!) : '',
        ),
        dtNascimento = TextEditingController(text: item.dtNascimento),
        parentesco = TextEditingController(text: item.parentesco),
        focusNome = FocusNode(),
        focusCpf = FocusNode(),
        focusDtNascimento = FocusNode(),
        focusParentesco = FocusNode();

  /// Linha criada em conjunto na aba Trabalho e Renda.
  CondicaoTrabalhoLinha? linhaTrabalhoVinculada;

  /// Linha criada em conjunto na aba Condições Educacionais.
  CondicaoEducacionalLinha? linhaEducacionalVinculada;

  final TextEditingController nome;
  final TextEditingController cpf;
  final TextEditingController dtNascimento;
  final TextEditingController parentesco;
  final FocusNode focusNome;
  final FocusNode focusCpf;
  final FocusNode focusDtNascimento;
  final FocusNode focusParentesco;

  bool get completamenteVazia =>
      nome.text.trim().isEmpty &&
      cpf.text.trim().isEmpty &&
      dtNascimento.text.trim().isEmpty &&
      parentesco.text.trim().isEmpty;

  bool get preenchida => nome.text.trim().isNotEmpty;

  EntrevistaComposicaoFamiliar? toModel() {
    if (!preenchida) return null;
    final cpfNorm = cpf.text.trim().isEmpty ? null : normalizeCpf(cpf.text);
    return EntrevistaComposicaoFamiliar(
      nome: nome.text.trim(),
      cpf: cpfNorm,
      dtNascimento: normalizarDataBr(dtNascimento.text.trim()),
      parentesco: parentesco.text.trim(),
    );
  }

  void dispose() {
    nome.dispose();
    cpf.dispose();
    dtNascimento.dispose();
    parentesco.dispose();
    focusNome.dispose();
    focusCpf.dispose();
    focusDtNascimento.dispose();
    focusParentesco.dispose();
  }
}

class CondicaoTrabalhoLinha {
  CondicaoTrabalhoLinha()
      : condicoesTrabalho = TextEditingController(),
        vrBeneficioSocial = TextEditingController(text: '0,00'),
        rendaMensal = TextEditingController(text: '0,00'),
        focusVrBeneficioSocial = FocusNode(),
        focusRendaMensal = FocusNode();

  CondicaoTrabalhoLinha.fromItem(EntrevistaCondicaoTrabalho item)
      : nomeSelecionado = item.nome,
        ocupacao = OcupacaoFamiliar.fromApi(item.ocupacao),
        condicoesTrabalho = TextEditingController(
          text: item.condicoesTrabalho ?? '',
        ),
        vrBeneficioSocial = TextEditingController(
          text: _moedaParaCampo(item.vrBeneficioSocial),
        ),
        rendaMensal = TextEditingController(
          text: _moedaParaCampo(item.rendaMensal),
        ),
        focusVrBeneficioSocial = FocusNode(),
        focusRendaMensal = FocusNode();

  String? nomeSelecionado;
  OcupacaoFamiliar? ocupacao;
  final TextEditingController condicoesTrabalho;
  final TextEditingController vrBeneficioSocial;
  final TextEditingController rendaMensal;
  final FocusNode focusVrBeneficioSocial;
  final FocusNode focusRendaMensal;

  static String _moedaParaCampo(String value) {
    return formatMoedaBr(parseMoedaBr(value));
  }

  bool get completamenteVazia =>
      (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) &&
      ocupacao == null &&
      condicoesTrabalho.text.trim().isEmpty &&
      parseMoedaBr(vrBeneficioSocial.text) == 0 &&
      parseMoedaBr(rendaMensal.text) == 0;

  bool get preenchida =>
      (nomeSelecionado != null && nomeSelecionado!.trim().isNotEmpty) ||
      ocupacao != null ||
      condicoesTrabalho.text.trim().isNotEmpty ||
      parseMoedaBr(vrBeneficioSocial.text) > 0 ||
      parseMoedaBr(rendaMensal.text) > 0;

  EntrevistaCondicaoTrabalho? toModel() {
    if (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) {
      return null;
    }
    if (ocupacao == null) return null;
    return EntrevistaCondicaoTrabalho(
      nome: nomeSelecionado!.trim(),
      ocupacao: ocupacao!.apiValue,
      condicoesTrabalho: condicoesTrabalho.text.trim().isEmpty
          ? null
          : condicoesTrabalho.text.trim(),
      vrBeneficioSocial: parseMoedaBr(vrBeneficioSocial.text).toString(),
      rendaMensal: parseMoedaBr(rendaMensal.text).toString(),
    );
  }

  void dispose() {
    condicoesTrabalho.dispose();
    vrBeneficioSocial.dispose();
    rendaMensal.dispose();
    focusVrBeneficioSocial.dispose();
    focusRendaMensal.dispose();
  }
}

class CondicaoEducacionalLinha {
  CondicaoEducacionalLinha()
      : idade = TextEditingController(),
        focusIdade = FocusNode();

  CondicaoEducacionalLinha.fromItem(EntrevistaCondicaoEducacional item)
      : nomeSelecionado = item.nome,
        idade = TextEditingController(text: item.idade.toString()),
        escolaridade = EscolaridadeFamiliar.fromApi(item.escolaridade),
        sabeLerEscrever = item.sabeLerEscrever,
        frequentaEscola = item.frequentaEscola,
        focusIdade = FocusNode();

  String? nomeSelecionado;
  final TextEditingController idade;
  final FocusNode focusIdade;
  EscolaridadeFamiliar? escolaridade;
  bool sabeLerEscrever = false;
  bool frequentaEscola = false;

  bool get completamenteVazia =>
      (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) &&
      idade.text.trim().isEmpty &&
      escolaridade == null &&
      !sabeLerEscrever &&
      !frequentaEscola;

  bool get preenchida =>
      (nomeSelecionado != null && nomeSelecionado!.trim().isNotEmpty) ||
      idade.text.trim().isNotEmpty ||
      escolaridade != null ||
      sabeLerEscrever ||
      frequentaEscola;

  EntrevistaCondicaoEducacional? toModel() {
    if (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) {
      return null;
    }
    if (escolaridade == null) return null;
    final idadeNum = int.tryParse(idade.text.trim());
    if (idadeNum == null || idadeNum < 0 || idadeNum > 150) return null;
    return EntrevistaCondicaoEducacional(
      nome: nomeSelecionado!.trim(),
      idade: idadeNum,
      escolaridade: escolaridade!.apiValue,
      sabeLerEscrever: sabeLerEscrever,
      frequentaEscola: frequentaEscola,
    );
  }

  void dispose() {
    idade.dispose();
    focusIdade.dispose();
  }
}

class DeficienciaFamiliarLinha {
  DeficienciaFamiliarLinha()
      : quemECuidador = TextEditingController(),
        focusQuemECuidador = FocusNode();

  DeficienciaFamiliarLinha.fromItem(EntrevistaDeficienciaFamiliar item)
      : nomeSelecionado = item.nome,
        tipoDeficiencia = TipoDeficienciaFamiliar.fromApi(item.tipoDeficiencia),
        necessitaCuidadosConstantes = item.necessitaCuidadosConstantes,
        quemECuidador = TextEditingController(text: item.quemECuidador ?? ''),
        focusQuemECuidador = FocusNode();

  String? nomeSelecionado;
  TipoDeficienciaFamiliar? tipoDeficiencia;
  bool necessitaCuidadosConstantes = false;
  final TextEditingController quemECuidador;
  final FocusNode focusQuemECuidador;

  bool get completamenteVazia =>
      (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) &&
      tipoDeficiencia == null &&
      !necessitaCuidadosConstantes &&
      quemECuidador.text.trim().isEmpty;

  bool get preenchida =>
      (nomeSelecionado != null && nomeSelecionado!.trim().isNotEmpty) ||
      tipoDeficiencia != null ||
      necessitaCuidadosConstantes ||
      quemECuidador.text.trim().isNotEmpty;

  EntrevistaDeficienciaFamiliar? toModel() {
    if (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) {
      return null;
    }
    if (tipoDeficiencia == null) return null;
    return EntrevistaDeficienciaFamiliar(
      nome: nomeSelecionado!.trim(),
      tipoDeficiencia: tipoDeficiencia!.apiValue,
      necessitaCuidadosConstantes: necessitaCuidadosConstantes,
      quemECuidador: quemECuidador.text.trim().isEmpty
          ? null
          : quemECuidador.text.trim(),
    );
  }

  void dispose() {
    quemECuidador.dispose();
    focusQuemECuidador.dispose();
  }
}

class GestanteFamiliarLinha {
  GestanteFamiliarLinha()
      : mesesGestacao = TextEditingController(),
        focusMesesGestacao = FocusNode();

  GestanteFamiliarLinha.fromItem(EntrevistaGestanteFamiliar item)
      : nomeSelecionado = item.nome,
        mesesGestacao = TextEditingController(
          text: item.mesesGestacao.toString(),
        ),
        iniciouPreNatal = item.preNatalEnum,
        focusMesesGestacao = FocusNode();

  String? nomeSelecionado;
  final TextEditingController mesesGestacao;
  RespostaSimNao? iniciouPreNatal;
  final FocusNode focusMesesGestacao;

  bool get completamenteVazia =>
      (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) &&
      mesesGestacao.text.trim().isEmpty &&
      iniciouPreNatal == null;

  bool get preenchida =>
      (nomeSelecionado != null && nomeSelecionado!.trim().isNotEmpty) ||
      mesesGestacao.text.trim().isNotEmpty ||
      iniciouPreNatal != null;

  EntrevistaGestanteFamiliar? toModel() {
    if (nomeSelecionado == null || nomeSelecionado!.trim().isEmpty) {
      return null;
    }
    final meses = int.tryParse(mesesGestacao.text.trim());
    if (meses == null || meses < 0 || meses > 10) return null;
    if (iniciouPreNatal == null) return null;
    return EntrevistaGestanteFamiliar(
      nome: nomeSelecionado!.trim(),
      mesesGestacao: meses,
      iniciouPreNatal: iniciouPreNatal!.apiValue,
    );
  }

  void dispose() {
    mesesGestacao.dispose();
    focusMesesGestacao.dispose();
  }
}

class SaudeFamiliaForm {
  SaudeFamiliaForm()
      : remediosControladosQuais = TextEditingController(),
        usoAbusivoDrogasQuais = TextEditingController(),
        focusRemediosControladosQuais = FocusNode(),
        focusUsoAbusivoDrogasQuais = FocusNode();

  SaudeFamiliaForm.fromEntrevista(EntrevistaSaudeFamilia s)
      : remediosControladosMental = s.remediosMentalEnum,
        remediosControladosQuais =
            TextEditingController(text: s.remediosControladosQuais ?? ''),
        usoAbusivoAlcool = s.alcoolEnum,
        usoAbusivoDrogas = s.drogasEnum,
        usoAbusivoDrogasQuais =
            TextEditingController(text: s.usoAbusivoDrogasQuais ?? ''),
        temGestante = s.gestanteEnum,
        focusRemediosControladosQuais = FocusNode(),
        focusUsoAbusivoDrogasQuais = FocusNode();

  RespostaSimNao? remediosControladosMental;
  final TextEditingController remediosControladosQuais;
  RespostaSimNao? usoAbusivoAlcool;
  RespostaSimNao? usoAbusivoDrogas;
  final TextEditingController usoAbusivoDrogasQuais;
  RespostaSimNao? temGestante;
  final FocusNode focusRemediosControladosQuais;
  final FocusNode focusUsoAbusivoDrogasQuais;

  EntrevistaSaudeFamilia toModel() {
    return EntrevistaSaudeFamilia(
      remediosControladosMental: remediosControladosMental?.apiValue,
      remediosControladosQuais: remediosControladosMental == RespostaSimNao.sim
          ? remediosControladosQuais.text.trim()
          : null,
      usoAbusivoAlcool: usoAbusivoAlcool?.apiValue,
      usoAbusivoDrogas: usoAbusivoDrogas?.apiValue,
      usoAbusivoDrogasQuais: usoAbusivoDrogas == RespostaSimNao.sim
          ? usoAbusivoDrogasQuais.text.trim()
          : null,
      temGestante: temGestante?.apiValue,
    );
  }

  void dispose() {
    remediosControladosQuais.dispose();
    usoAbusivoDrogasQuais.dispose();
    focusRemediosControladosQuais.dispose();
    focusUsoAbusivoDrogasQuais.dispose();
  }
}
