import { Prisma } from "@prisma/client";
import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { normalizeCpf } from "../lib/cpf.js";
import { formatDataBr, parseDataBr } from "../lib/campo.js";
import { formatCpf } from "../lib/cpf.js";
import { ROTULO_FORMA_ACESSO } from "../lib/entrevista-assistido.js";
import { assertEscolaridadeCodigo } from "./escolaridades.js";
import {
  codigoOcupacaoFamiliar,
  rotuloOcupacaoFamiliar,
} from "../lib/ocupacao-familiar.js";
import { ROTULO_RESPOSTA_SIM_NAO } from "../lib/resposta-sim-nao.js";
import { rotuloTipoDeficienciaFamiliar } from "../lib/tipo-deficiencia-familiar.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateEntrevistaAssistidoInput,
  ListEntrevistasAssistidoQuery,
  UpdateEntrevistaAssistidoInput,
} from "../validators/entrevistas-assistido.js";
import { parseDtNascimento } from "../validators/pessoas.js";
import { mapPessoa } from "./pessoas.js";

export class EntrevistaAssistidoValidationError extends Error {
  constructor(
    message: string,
    public readonly details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "EntrevistaAssistidoValidationError";
  }
}

const entrevistaPessoaInclude = {
  bairro: { select: { codigo: true, nome: true } },
  cidade: { select: { codigo: true, nomeMunicipio: true, estado: true } },
} as const;

const entrevistaInclude = {
  pessoa: { include: entrevistaPessoaInclude },
  formasAcesso: { orderBy: { formaAcesso: "asc" as const } },
  composicaoFamiliar: { orderBy: { ordem: "asc" as const } },
  condicoesTrabalho: { orderBy: { ordem: "asc" as const } },
  condicoesEducacionais: {
    orderBy: { ordem: "asc" as const },
    include: { escolaridade: true },
  },
  deficienciasFamilia: { orderBy: { ordem: "asc" as const } },
  gestantesFamilia: { orderBy: { ordem: "asc" as const } },
} as const;

/** Transação com vários deleteMany/createMany (Neon pode ser lento). */
const TX_ENTREVISTA_OPTS = {
  maxWait: 10_000,
  timeout: 60_000,
} as const;

function dadosSaudeFamiliaEntrevista(
  saude: CreateEntrevistaAssistidoInput["saudeFamilia"],
) {
  const s = saude ?? {};
  return {
    remediosControladosMental: s.remediosControladosMental ?? null,
    remediosControladosQuais: s.remediosControladosQuais ?? null,
    usoAbusivoAlcool: s.usoAbusivoAlcool ?? null,
    usoAbusivoDrogas: s.usoAbusivoDrogas ?? null,
    usoAbusivoDrogasQuais: s.usoAbusivoDrogasQuais ?? null,
    temGestante: s.temGestante ?? null,
  };
}

function dadosProgramasSociaisEntrevista(
  programas: CreateEntrevistaAssistidoInput["programasSociais"],
) {
  const p = programas ?? {};
  const outrosProgramas = p.outrosProgramas ?? false;
  const outrosAtendimento = p.outrosAtendimentoFamilia ?? false;
  return {
    bolsaFamilia: p.bolsaFamilia ?? false,
    peti: p.peti ?? false,
    bpc: p.bpc ?? false,
    outrosProgramas,
    outrosProgramasSociais: outrosProgramas
      ? (p.outrosProgramasSociais?.trim() ?? null)
      : null,
    cras: p.cras ?? false,
    centroPop: p.centroPop ?? false,
    conselhoTutelar: p.conselhoTutelar ?? false,
    ubs: p.ubs ?? false,
    creas: p.creas ?? false,
    caps: p.caps ?? false,
    craf: p.craf ?? false,
    outrosAtendimentoFamilia: outrosAtendimento,
    outrosOrgaosSociais: outrosAtendimento
      ? (p.outrosOrgaosSociais?.trim() ?? null)
      : null,
  };
}

async function salvarFilhosEntrevista(
  tx: Prisma.TransactionClient,
  entrevistaId: string,
  input: Pick<
    CreateEntrevistaAssistidoInput,
    | "composicaoFamiliar"
    | "condicoesTrabalho"
    | "condicoesEducacionais"
    | "deficienciasFamilia"
    | "gestantesFamilia"
  >,
  usuarioId: string,
  options?: { somenteEscolaridadeAtiva?: boolean },
) {
  const composicao = input.composicaoFamiliar ?? [];
  const condicoes = input.condicoesTrabalho ?? [];
  const educacionais = input.condicoesEducacionais ?? [];
  for (const item of educacionais) {
    await assertEscolaridadeCodigo(item.escolaridadeCodigo, {
      somenteAtiva: options?.somenteEscolaridadeAtiva ?? true,
    });
  }
  const deficiencias = input.deficienciasFamilia ?? [];
  const gestantes = input.gestantesFamilia ?? [];
  const audit = auditInclusao(usuarioId);

  if (composicao.length > 0) {
    await tx.entrevistaComposicaoFamiliar.createMany({
      data: composicao.map((item, ordem) => ({
        entrevistaId,
        ordem,
        nome: item.nome,
        cpf: item.cpf,
        dtNascimento: parseDtNascimento(item.dtNascimento),
        parentesco: item.parentesco,
        ...audit,
      })),
    });
  }

  if (condicoes.length > 0) {
    await tx.entrevistaCondicaoTrabalho.createMany({
      data: condicoes.map((item, ordem) => ({
        entrevistaId,
        ordem,
        nome: item.nome,
        ocupacao: item.ocupacao,
        condicoesTrabalho: item.condicoesTrabalho,
        vrBeneficioSocial: new Prisma.Decimal(item.vrBeneficioSocial ?? 0),
        rendaMensal: new Prisma.Decimal(item.rendaMensal ?? 0),
        ...audit,
      })),
    });
  }

  if (educacionais.length > 0) {
    await tx.entrevistaCondicaoEducacional.createMany({
      data: educacionais.map((item, ordem) => ({
        entrevistaId,
        ordem,
        nome: item.nome,
        idade: item.idade,
        escolaridadeCodigo: item.escolaridadeCodigo,
        sabeLerEscrever: item.sabeLerEscrever ?? false,
        frequentaEscola: item.frequentaEscola ?? false,
        ...audit,
      })),
    });
  }

  if (deficiencias.length > 0) {
    await tx.entrevistaDeficienciaFamiliar.createMany({
      data: deficiencias.map((item, ordem) => ({
        entrevistaId,
        ordem,
        nome: item.nome,
        tipoDeficiencia: item.tipoDeficiencia,
        necessitaCuidadosConstantes: item.necessitaCuidadosConstantes ?? false,
        quemECuidador: item.quemECuidador,
        ...audit,
      })),
    });
  }

  if (gestantes.length > 0) {
    await tx.entrevistaGestanteFamiliar.createMany({
      data: gestantes.map((item, ordem) => ({
        entrevistaId,
        ordem,
        nome: item.nome,
        mesesGestacao: item.mesesGestacao,
        iniciouPreNatal: item.iniciouPreNatal,
        ...audit,
      })),
    });
  }
}

export async function createEntrevistaAssistido(
  input: CreateEntrevistaAssistidoInput,
  usuarioId: string,
) {
  await validarPessoaEntrevista(input.pessoaId);

  let dataEntrevista: Date;
  try {
    dataEntrevista = parseDataBr(input.dataEntrevista);
  } catch (err) {
    throw new EntrevistaAssistidoValidationError(
      err instanceof Error ? err.message : "Data da entrevista inválida",
    );
  }

  const audit = auditInclusao(usuarioId);
  const outrosTexto = input.formasAcesso.includes("OUTROS")
    ? (input.outrosTexto?.trim() ?? null)
    : null;

  const entrevistaId = await prisma.$transaction(async (tx) => {
    const entrevista = await tx.entrevistaAssistido.create({
      data: {
        pessoaId: input.pessoaId,
        dataEntrevista,
        outrosTexto,
        ...dadosSaudeFamiliaEntrevista(input.saudeFamilia),
        ...dadosProgramasSociaisEntrevista(input.programasSociais),
        ...audit,
      },
    });

    await tx.entrevistaAssistidoFormaAcesso.createMany({
      data: input.formasAcesso.map((formaAcesso) => ({
        entrevistaId: entrevista.id,
        formaAcesso,
        ...audit,
      })),
    });

    await salvarFilhosEntrevista(tx, entrevista.id, input, usuarioId);

    return entrevista.id;
  }, TX_ENTREVISTA_OPTS);

  const entrevista = await getEntrevistaAssistidoById(entrevistaId);
  if (!entrevista) {
    throw new EntrevistaAssistidoValidationError(
      "Falha ao carregar entrevista após o registro",
    );
  }
  return entrevista;
}

export async function getEntrevistaAssistidoById(id: string) {
  return prisma.entrevistaAssistido.findUnique({
    where: { id },
    include: entrevistaInclude,
  });
}

export async function listEntrevistasAssistido(
  filters: ListEntrevistasAssistidoQuery = {},
) {
  const where: Prisma.EntrevistaAssistidoWhereInput = {};

  if (filters.pessoaId) {
    where.pessoaId = filters.pessoaId;
  }

  const nome = filters.nome?.trim();
  const cpfDigits = filters.cpf ? normalizeCpf(filters.cpf) : "";
  if (nome || cpfDigits.length > 0) {
    const pessoaWhere: Prisma.PessoaWhereInput = {};
    if (nome) {
      pessoaWhere.nome = { contains: nome, mode: "insensitive" };
    }
    if (cpfDigits.length > 0) {
      pessoaWhere.cpf = { contains: cpfDigits };
    }
    where.pessoa = pessoaWhere;
  }

  return prisma.entrevistaAssistido.findMany({
    where,
    include: {
      pessoa: { select: { id: true, nome: true, cpf: true } },
      _count: {
        select: {
          composicaoFamiliar: true,
          condicoesTrabalho: true,
          condicoesEducacionais: true,
          deficienciasFamilia: true,
          gestantesFamilia: true,
          formasAcesso: true,
        },
      },
    },
    orderBy: [{ dataEntrevista: "desc" }, { dataHoraInclusao: "desc" }],
  });
}

async function validarPessoaEntrevista(pessoaId: string) {
  const pessoa = await prisma.pessoa.findUnique({ where: { id: pessoaId } });
  if (!pessoa) {
    throw new EntrevistaAssistidoValidationError("Assistido não encontrado");
  }
  if (!pessoa.ativo) {
    throw new EntrevistaAssistidoValidationError("Assistido inativo");
  }
  return pessoa;
}

async function removerFilhosEntrevista(
  tx: Prisma.TransactionClient,
  entrevistaId: string,
) {
  await tx.entrevistaAssistidoFormaAcesso.deleteMany({
    where: { entrevistaId },
  });
  await tx.entrevistaComposicaoFamiliar.deleteMany({
    where: { entrevistaId },
  });
  await tx.entrevistaCondicaoTrabalho.deleteMany({
    where: { entrevistaId },
  });
  await tx.entrevistaCondicaoEducacional.deleteMany({
    where: { entrevistaId },
  });
  await tx.entrevistaDeficienciaFamiliar.deleteMany({
    where: { entrevistaId },
  });
  await tx.entrevistaGestanteFamiliar.deleteMany({
    where: { entrevistaId },
  });
}

export async function updateEntrevistaAssistido(
  id: string,
  input: UpdateEntrevistaAssistidoInput,
  usuarioId: string,
) {
  const existente = await prisma.entrevistaAssistido.findUnique({
    where: { id },
  });
  if (!existente) {
    return null;
  }

  await validarPessoaEntrevista(input.pessoaId);

  let dataEntrevista: Date;
  try {
    dataEntrevista = parseDataBr(input.dataEntrevista);
  } catch (err) {
    throw new EntrevistaAssistidoValidationError(
      err instanceof Error ? err.message : "Data da entrevista inválida",
    );
  }

  const outrosTexto = input.formasAcesso.includes("OUTROS")
    ? (input.outrosTexto?.trim() ?? null)
    : null;

  const auditInc = auditInclusao(usuarioId);
  const auditAlt = auditAlteracao(usuarioId);

  await prisma.$transaction(async (tx) => {
    await tx.entrevistaAssistido.update({
      where: { id },
      data: {
        pessoaId: input.pessoaId,
        dataEntrevista,
        outrosTexto,
        ...dadosSaudeFamiliaEntrevista(input.saudeFamilia),
        ...dadosProgramasSociaisEntrevista(input.programasSociais),
        ...auditAlt,
      },
    });

    await removerFilhosEntrevista(tx, id);

    await tx.entrevistaAssistidoFormaAcesso.createMany({
      data: input.formasAcesso.map((formaAcesso) => ({
        entrevistaId: id,
        formaAcesso,
        ...auditInc,
      })),
    });

    await salvarFilhosEntrevista(tx, id, input, usuarioId, {
      somenteEscolaridadeAtiva: false,
    });
  }, TX_ENTREVISTA_OPTS);

  return getEntrevistaAssistidoById(id);
}

export async function deleteEntrevistaAssistido(id: string) {
  const existente = await prisma.entrevistaAssistido.findUnique({
    where: { id },
  });
  if (!existente) {
    return false;
  }

  await prisma.$transaction(async (tx) => {
    await removerFilhosEntrevista(tx, id);
    await tx.entrevistaAssistido.delete({ where: { id } });
  }, TX_ENTREVISTA_OPTS);

  return true;
}

export function mapEntrevistaAssistidoResumo(
  e: Awaited<ReturnType<typeof listEntrevistasAssistido>>[number],
) {
  return {
    id: e.id,
    pessoaId: e.pessoaId,
    dataEntrevista: formatDataBr(e.dataEntrevista),
    pessoa: {
      id: e.pessoa.id,
      nome: e.pessoa.nome,
      cpf: e.pessoa.cpf,
      cpfFormatado: formatCpf(e.pessoa.cpf),
    },
    totalFormasAcesso: e._count.formasAcesso,
    totalComposicaoFamiliar: e._count.composicaoFamiliar,
    totalCondicoesTrabalho: e._count.condicoesTrabalho,
    totalCondicoesEducacionais: e._count.condicoesEducacionais,
    totalDeficienciasFamilia: e._count.deficienciasFamilia,
    totalGestantesFamilia: e._count.gestantesFamilia,
    ...mapAuditoria(e),
  };
}

export function mapEntrevistaAssistido(
  e: NonNullable<Awaited<ReturnType<typeof getEntrevistaAssistidoById>>>,
) {
  return {
    id: e.id,
    pessoaId: e.pessoaId,
    dataEntrevista: formatDataBr(e.dataEntrevista),
    outrosTexto: e.outrosTexto,
    pessoa: mapPessoa(e.pessoa),
    formasAcesso: e.formasAcesso.map((f) => ({
      id: f.id,
      formaAcesso: f.formaAcesso,
      rotulo: ROTULO_FORMA_ACESSO[f.formaAcesso],
    })),
    composicaoFamiliar: e.composicaoFamiliar.map((c) => ({
      id: c.id,
      ordem: c.ordem,
      nome: c.nome,
      cpf: c.cpf,
      cpfFormatado: c.cpf ? formatCpf(c.cpf) : null,
      dtNascimento: formatDataBr(c.dtNascimento),
      parentesco: c.parentesco,
    })),
    condicoesTrabalho: e.condicoesTrabalho.map((c) => ({
      id: c.id,
      ordem: c.ordem,
      nome: c.nome,
      ocupacao: c.ocupacao,
      ocupacaoCodigo: codigoOcupacaoFamiliar(c.ocupacao),
      ocupacaoRotulo: rotuloOcupacaoFamiliar(c.ocupacao),
      condicoesTrabalho: c.condicoesTrabalho,
      vrBeneficioSocial: c.vrBeneficioSocial.toString(),
      rendaMensal: c.rendaMensal.toString(),
    })),
    condicoesEducacionais: e.condicoesEducacionais.map((c) => ({
      id: c.id,
      ordem: c.ordem,
      nome: c.nome,
      idade: c.idade,
      escolaridadeCodigo: c.escolaridadeCodigo,
      escolaridadeRotulo: c.escolaridade.descricao,
      sabeLerEscrever: c.sabeLerEscrever,
      frequentaEscola: c.frequentaEscola,
    })),
    deficienciasFamilia: e.deficienciasFamilia.map((d) => ({
      id: d.id,
      ordem: d.ordem,
      nome: d.nome,
      tipoDeficiencia: d.tipoDeficiencia,
      tipoDeficienciaRotulo: rotuloTipoDeficienciaFamiliar(d.tipoDeficiencia),
      necessitaCuidadosConstantes: d.necessitaCuidadosConstantes,
      quemECuidador: d.quemECuidador,
    })),
    gestantesFamilia: e.gestantesFamilia.map((g) => ({
      id: g.id,
      ordem: g.ordem,
      nome: g.nome,
      mesesGestacao: g.mesesGestacao,
      iniciouPreNatal: g.iniciouPreNatal,
      iniciouPreNatalRotulo: ROTULO_RESPOSTA_SIM_NAO[g.iniciouPreNatal],
    })),
    programasSociais: {
      bolsaFamilia: e.bolsaFamilia,
      peti: e.peti,
      bpc: e.bpc,
      outrosProgramas: e.outrosProgramas,
      outrosProgramasSociais: e.outrosProgramasSociais,
      cras: e.cras,
      centroPop: e.centroPop,
      conselhoTutelar: e.conselhoTutelar,
      ubs: e.ubs,
      creas: e.creas,
      caps: e.caps,
      craf: e.craf,
      outrosAtendimentoFamilia: e.outrosAtendimentoFamilia,
      outrosOrgaosSociais: e.outrosOrgaosSociais,
    },
    saudeFamilia: {
      remediosControladosMental: e.remediosControladosMental,
      remediosControladosMentalRotulo: e.remediosControladosMental
        ? ROTULO_RESPOSTA_SIM_NAO[e.remediosControladosMental]
        : null,
      remediosControladosQuais: e.remediosControladosQuais,
      usoAbusivoAlcool: e.usoAbusivoAlcool,
      usoAbusivoAlcoolRotulo: e.usoAbusivoAlcool
        ? ROTULO_RESPOSTA_SIM_NAO[e.usoAbusivoAlcool]
        : null,
      usoAbusivoDrogas: e.usoAbusivoDrogas,
      usoAbusivoDrogasRotulo: e.usoAbusivoDrogas
        ? ROTULO_RESPOSTA_SIM_NAO[e.usoAbusivoDrogas]
        : null,
      usoAbusivoDrogasQuais: e.usoAbusivoDrogasQuais,
      temGestante: e.temGestante,
      temGestanteRotulo: e.temGestante
        ? ROTULO_RESPOSTA_SIM_NAO[e.temGestante]
        : null,
    },
    ...mapAuditoria(e),
  };
}
