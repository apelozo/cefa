import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  enrichUsuarioMap,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { formatDataBr } from "../lib/campo.js";
import { formatCpf } from "../lib/cpf.js";
import { rotuloEstadoCivilVoluntario } from "../lib/estado-civil-voluntario.js";
import { calcularIdade } from "../lib/idade.js";
import { prisma } from "../lib/prisma.js";
import { formatRg } from "../lib/rg.js";
import { rotuloTipoCasaAlunoCapacitacao } from "../lib/tipo-casa-aluno-capacitacao.js";
import { assertEscolaridadeCodigo } from "./escolaridades.js";
import type { CreateAlunoCapacitacaoInput } from "../validators/alunos-capacitacao.js";
import { parseDtNascimentoAlunoCapacitacao } from "../validators/alunos-capacitacao.js";
import { normalizeCpf } from "../lib/cpf.js";

export type ListAlunosCapacitacaoFilters = {
  ativo?: boolean;
  nome?: string;
  cpf?: string;
};

const alunoInclude = {
  naturalidade: {
    select: { codigo: true, nomeMunicipio: true, estado: true },
  },
  cidade: { select: { codigo: true, nomeMunicipio: true, estado: true } },
  escolaridade: { select: { codigo: true, descricao: true } },
  rendasFamiliares: { orderBy: { ordem: "asc" as const } },
} satisfies Prisma.AlunoCapacitacaoProfissionalInclude;

type AlunoComRelacoes = Prisma.AlunoCapacitacaoProfissionalGetPayload<{
  include: typeof alunoInclude;
}>;

export function calcularRendaPerCapita(
  rendas: { nome: string; renda: Prisma.Decimal | number }[],
): number {
  const linhas = rendas.filter((r) => r.nome.trim().length > 0);
  if (linhas.length === 0) return 0;
  const total = linhas.reduce((s, r) => s + Number(r.renda), 0);
  return total / linhas.length;
}

async function validarReferencias(data: {
  naturalidadeCodigo?: number | null;
  cidadeCodigo?: number | null;
  escolaridadeCodigo?: number | null;
}) {
  if (data.naturalidadeCodigo) {
    const cidade = await prisma.cidade.findUnique({
      where: { codigo: data.naturalidadeCodigo },
    });
    if (!cidade || !cidade.ativo) {
      throw new AlunoCapacitacaoReferenciaError(
        "Naturalidade (município) inválida ou inativa",
      );
    }
  }
  if (data.cidadeCodigo) {
    const cidade = await prisma.cidade.findUnique({
      where: { codigo: data.cidadeCodigo },
    });
    if (!cidade || !cidade.ativo) {
      throw new AlunoCapacitacaoReferenciaError(
        "Município (endereço) inválido ou inativo",
      );
    }
  }
  if (data.escolaridadeCodigo) {
    await assertEscolaridadeCodigo(data.escolaridadeCodigo, {
      somenteAtiva: true,
    });
  }
}

function dadosPrismaFromInput(data: CreateAlunoCapacitacaoInput) {
  const jaFez = data.jaFezCursoSenacSenai ?? false;
  const possuiNec = data.possuiNecessidadeEspecial ?? false;
  const fazMed = data.fazAcompanhamentoMedico ?? false;

  return {
    ...(data.nome !== undefined && { nome: data.nome }),
    ...(data.nomeSocial !== undefined && { nomeSocial: data.nomeSocial }),
    ...(data.estadoCivil !== undefined && { estadoCivil: data.estadoCivil }),
    ...(data.rg !== undefined && { rg: data.rg }),
    ...(data.orgaoExpedidor !== undefined && {
      orgaoExpedidor: data.orgaoExpedidor,
    }),
    ...(data.cpf !== undefined && { cpf: data.cpf }),
    ...(data.dtNascimento !== undefined && {
      dtNascimento: parseDtNascimentoAlunoCapacitacao(data.dtNascimento),
    }),
    ...(data.nacionalidade !== undefined && {
      nacionalidade: data.nacionalidade,
    }),
    ...(data.naturalidadeCodigo !== undefined && {
      naturalidadeCodigo: data.naturalidadeCodigo ?? null,
    }),
    ...(data.nomeMae !== undefined && { nomeMae: data.nomeMae }),
    ...(data.nomePai !== undefined && { nomePai: data.nomePai }),
    ...(data.escolaridadeCodigo !== undefined && {
      escolaridadeCodigo: data.escolaridadeCodigo ?? null,
    }),
    ...(data.nomeUltimaEscola !== undefined && {
      nomeUltimaEscola: data.nomeUltimaEscola,
    }),
    ...(data.endereco !== undefined && { endereco: data.endereco }),
    ...(data.enderecoNumero !== undefined && {
      enderecoNumero: data.enderecoNumero,
    }),
    ...(data.bairro !== undefined && { bairro: data.bairro }),
    ...(data.cep !== undefined && { cep: data.cep }),
    ...(data.cidadeCodigo != null && { cidadeCodigo: data.cidadeCodigo }),
    ...(data.tipoCasa !== undefined && {
      tipoCasa: data.tipoCasa,
      valorAluguel:
        data.tipoCasa === "ALUGUEL" && data.valorAluguel != null
          ? new Prisma.Decimal(data.valorAluguel)
          : null,
    }),
    ...(data.telefone !== undefined && { telefone: data.telefone }),
    ...(data.celular !== undefined && { celular: data.celular }),
    ...(data.telefoneRecado !== undefined && {
      telefoneRecado: data.telefoneRecado,
    }),
    ...(data.email !== undefined && { email: data.email }),
    ...(data.redeSocial !== undefined && { redeSocial: data.redeSocial }),
    ...(data.jaFezCursoSenacSenai !== undefined && {
      jaFezCursoSenacSenai: jaFez,
      cursoSenacSenaiDescricao: jaFez
        ? (data.cursoSenacSenaiDescricao ?? null)
        : null,
      cursoSenacSenaiAno: jaFez ? (data.cursoSenacSenaiAno ?? null) : null,
    }),
    ...(data.encaminhamento !== undefined && {
      encaminhamento: data.encaminhamento,
    }),
    ...(data.telefoneEncaminhamento !== undefined && {
      telefoneEncaminhamento: data.telefoneEncaminhamento,
    }),
    ...(data.possuiNecessidadeEspecial !== undefined && {
      possuiNecessidadeEspecial: possuiNec,
      qualNecessidade: possuiNec ? (data.qualNecessidade ?? null) : null,
    }),
    ...(data.fazAcompanhamentoMedico !== undefined && {
      fazAcompanhamentoMedico: fazMed,
      tomaMedicacao: fazMed ? (data.tomaMedicacao ?? null) : null,
    }),
    ...(data.vacinacao !== undefined && { vacinacao: data.vacinacao }),
    ...(data.alergias !== undefined && { alergias: data.alergias }),
  };
}

async function salvarRendasFamiliares(
  tx: Prisma.TransactionClient,
  alunoId: string,
  rendas: CreateAlunoCapacitacaoInput["rendasFamiliares"],
  usuarioId: string,
) {
  const audit = auditInclusao(usuarioId);
  const linhas = (rendas ?? []).filter((r) => r.nome.trim().length > 0);
  if (linhas.length === 0) return;

  await tx.alunoCapacitacaoRendaFamiliar.createMany({
    data: linhas.map((item, ordem) => ({
      alunoCapacitacaoId: alunoId,
      ordem,
      nome: item.nome.trim(),
      idade: item.idade ?? null,
      renda: new Prisma.Decimal(item.renda ?? 0),
      parentesco: item.parentesco,
      profissao: item.profissao,
      ...audit,
    })),
  });
}

export async function listAlunosCapacitacao(
  filters: ListAlunosCapacitacaoFilters = {},
) {
  const where: Prisma.AlunoCapacitacaoProfissionalWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  const nome = filters.nome?.trim();
  if (nome) {
    where.nome = { contains: nome, mode: "insensitive" };
  }

  const cpfDigits = filters.cpf ? normalizeCpf(filters.cpf) : "";
  if (cpfDigits.length > 0) {
    where.cpf = { contains: cpfDigits };
  }

  const rows = await prisma.alunoCapacitacaoProfissional.findMany({
    where,
    include: {
      naturalidade: {
        select: { codigo: true, nomeMunicipio: true, estado: true },
      },
      escolaridade: { select: { codigo: true, descricao: true } },
      rendasFamiliares: { select: { nome: true, renda: true } },
    },
    orderBy: [{ nome: "asc" }],
  });

  const usuarios = await enrichUsuarioMap(rows);
  return rows.map((a) => mapAlunoCapacitacaoResumo(a, usuarios));
}

export async function getAlunoCapacitacaoById(id: string) {
  return prisma.alunoCapacitacaoProfissional.findUnique({
    where: { id },
    include: alunoInclude,
  });
}

export async function createAlunoCapacitacao(
  data: CreateAlunoCapacitacaoInput,
  usuarioId: string,
) {
  await validarReferencias(data);

  try {
    const alunoId = await prisma.$transaction(async (tx) => {
      const aluno = await tx.alunoCapacitacaoProfissional.create({
        data: {
          ...dadosPrismaFromInput(data),
          ativo: true,
          ...auditInclusao(usuarioId),
        } as Prisma.AlunoCapacitacaoProfissionalUncheckedCreateInput,
      });

      await salvarRendasFamiliares(
        tx,
        aluno.id,
        data.rendasFamiliares,
        usuarioId,
      );

      return aluno.id;
    });

    const aluno = await getAlunoCapacitacaoById(alunoId);
    if (!aluno) {
      throw new AlunoCapacitacaoValidationError(
        "Falha ao carregar aluno após o registro",
      );
    }
    return aluno;
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new AlunoCapacitacaoConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function updateAlunoCapacitacao(
  id: string,
  data: CreateAlunoCapacitacaoInput,
  usuarioId: string,
) {
  const existing = await prisma.alunoCapacitacaoProfissional.findUnique({
    where: { id },
  });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new AlunoCapacitacaoInativoError(
      "Não é possível alterar um aluno desativado",
    );
  }

  await validarReferencias(data);

  try {
    await prisma.$transaction(async (tx) => {
      await tx.alunoCapacitacaoProfissional.update({
        where: { id },
        data: {
          ...dadosPrismaFromInput(data),
          ...auditAlteracao(usuarioId),
        },
      });

      await tx.alunoCapacitacaoRendaFamiliar.deleteMany({
        where: { alunoCapacitacaoId: id },
      });
      await salvarRendasFamiliares(
        tx,
        id,
        data.rendasFamiliares,
        usuarioId,
      );
    });

    return getAlunoCapacitacaoById(id);
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new AlunoCapacitacaoConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function desativarAlunoCapacitacao(
  id: string,
  usuarioId: string,
) {
  const existing = await prisma.alunoCapacitacaoProfissional.findUnique({
    where: { id },
  });
  if (!existing) return null;
  if (!existing.ativo) {
    return getAlunoCapacitacaoById(id);
  }

  return prisma.alunoCapacitacaoProfissional.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
    include: alunoInclude,
  });
}

export class AlunoCapacitacaoConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoCapacitacaoConflictError";
  }
}

export class AlunoCapacitacaoInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoCapacitacaoInativoError";
  }
}

export class AlunoCapacitacaoReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoCapacitacaoReferenciaError";
  }
}

export class AlunoCapacitacaoValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoCapacitacaoValidationError";
  }
}

function mapRendaFamiliar(
  r: AlunoComRelacoes["rendasFamiliares"][number],
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    id: r.id,
    ordem: r.ordem,
    nome: r.nome,
    idade: r.idade,
    renda: Number(r.renda),
    parentesco: r.parentesco,
    profissao: r.profissao,
    ...mapAuditoria(r, usuarios),
  };
}

function mapAlunoCapacitacaoResumo(
  a: Prisma.AlunoCapacitacaoProfissionalGetPayload<{
    include: {
      naturalidade: {
        select: { codigo: true; nomeMunicipio: true; estado: true };
      };
      escolaridade: { select: { codigo: true; descricao: true } };
      rendasFamiliares: { select: { nome: true; renda: true } };
    };
  }>,
  usuarios?: UsuarioAuditoriaMap,
) {
  const base = mapAlunoCapacitacaoCore(a, usuarios);
  return {
    ...base,
    rendaPerCapita: calcularRendaPerCapita(a.rendasFamiliares),
  };
}

function mapAlunoCapacitacaoCore(
  a: Pick<
    AlunoComRelacoes,
    | "id"
    | "nome"
    | "nomeSocial"
    | "estadoCivil"
    | "rg"
    | "orgaoExpedidor"
    | "cpf"
    | "dtNascimento"
    | "nacionalidade"
    | "naturalidadeCodigo"
    | "nomeMae"
    | "nomePai"
    | "escolaridadeCodigo"
    | "nomeUltimaEscola"
    | "endereco"
    | "enderecoNumero"
    | "bairro"
    | "cep"
    | "cidadeCodigo"
    | "tipoCasa"
    | "valorAluguel"
    | "telefone"
    | "celular"
    | "telefoneRecado"
    | "email"
    | "redeSocial"
    | "jaFezCursoSenacSenai"
    | "cursoSenacSenaiDescricao"
    | "cursoSenacSenaiAno"
    | "encaminhamento"
    | "telefoneEncaminhamento"
    | "possuiNecessidadeEspecial"
    | "qualNecessidade"
    | "fazAcompanhamentoMedico"
    | "tomaMedicacao"
    | "vacinacao"
    | "alergias"
    | "ativo"
    | "usuarioInclusaoId"
    | "dataHoraInclusao"
    | "usuarioAlteracaoId"
    | "dataHoraAlteracao"
  > & {
    naturalidade?: {
      codigo: number;
      nomeMunicipio: string;
      estado: string;
    } | null;
    cidade?: {
      codigo: number;
      nomeMunicipio: string;
      estado: string;
    } | null;
    escolaridade?: { codigo: number; descricao: string } | null;
  },
  usuarios?: UsuarioAuditoriaMap,
) {
  const idade =
    a.dtNascimento != null ? calcularIdade(a.dtNascimento) : null;

  return {
    id: a.id,
    nome: a.nome,
    nomeSocial: a.nomeSocial,
    estadoCivil: a.estadoCivil,
    estadoCivilRotulo: a.estadoCivil
      ? rotuloEstadoCivilVoluntario(a.estadoCivil)
      : null,
    rg: a.rg,
    rgFormatado: a.rg ? formatRg(a.rg) : null,
    orgaoExpedidor: a.orgaoExpedidor,
    cpf: a.cpf,
    cpfFormatado: a.cpf ? formatCpf(a.cpf) : null,
    dtNascimento: a.dtNascimento ? formatDataBr(a.dtNascimento) : null,
    idade,
    nacionalidade: a.nacionalidade,
    naturalidadeCodigo: a.naturalidadeCodigo,
    naturalidadeNome: a.naturalidade?.nomeMunicipio ?? null,
    naturalidadeEstado: a.naturalidade?.estado ?? null,
    nomeMae: a.nomeMae,
    nomePai: a.nomePai,
    escolaridadeCodigo: a.escolaridadeCodigo,
    escolaridadeDescricao: a.escolaridade?.descricao ?? null,
    nomeUltimaEscola: a.nomeUltimaEscola,
    endereco: a.endereco,
    enderecoNumero: a.enderecoNumero,
    bairro: a.bairro,
    cep: a.cep,
    cidadeCodigo: a.cidadeCodigo,
    cidadeNome: a.cidade?.nomeMunicipio ?? null,
    cidadeEstado: a.cidade?.estado ?? null,
    tipoCasa: a.tipoCasa,
    tipoCasaRotulo: a.tipoCasa
      ? rotuloTipoCasaAlunoCapacitacao(a.tipoCasa)
      : null,
    valorAluguel: a.valorAluguel != null ? Number(a.valorAluguel) : null,
    telefone: a.telefone,
    celular: a.celular,
    telefoneRecado: a.telefoneRecado,
    email: a.email,
    redeSocial: a.redeSocial,
    jaFezCursoSenacSenai: a.jaFezCursoSenacSenai,
    cursoSenacSenaiDescricao: a.cursoSenacSenaiDescricao,
    cursoSenacSenaiAno: a.cursoSenacSenaiAno,
    encaminhamento: a.encaminhamento,
    telefoneEncaminhamento: a.telefoneEncaminhamento,
    possuiNecessidadeEspecial: a.possuiNecessidadeEspecial,
    qualNecessidade: a.qualNecessidade,
    fazAcompanhamentoMedico: a.fazAcompanhamentoMedico,
    tomaMedicacao: a.tomaMedicacao,
    vacinacao: a.vacinacao,
    alergias: a.alergias,
    ativo: a.ativo,
    ...mapAuditoria(a, usuarios),
  };
}

export function mapAlunoCapacitacao(
  a: AlunoComRelacoes,
  usuarios?: UsuarioAuditoriaMap,
) {
  const core = mapAlunoCapacitacaoCore(a, usuarios);
  return {
    ...core,
    rendasFamiliares: a.rendasFamiliares.map((r) =>
      mapRendaFamiliar(r, usuarios),
    ),
    rendaPerCapita: calcularRendaPerCapita(a.rendasFamiliares),
  };
}
