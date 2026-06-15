import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  enrichUsuarioMap,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { formatDataBr } from "../lib/campo.js";
import { formatCpf, normalizeCpf } from "../lib/cpf.js";
import { rotuloEstadoCivilVoluntario } from "../lib/estado-civil-voluntario.js";
import { calcularIdade } from "../lib/idade.js";
import { prisma } from "../lib/prisma.js";
import { formatRg } from "../lib/rg.js";
import { assertEscolaridadeCodigo } from "./escolaridades.js";
import type { CreateAlunoInput } from "../validators/alunos.js";
import {
  parseDtExpedicaoRgAluno,
  parseDtNascimentoAluno,
} from "../validators/alunos.js";

export type ListAlunosFilters = {
  ativo?: boolean;
  nome?: string;
  cpf?: string;
};

const alunoInclude = {
  naturalidade: {
    select: { codigo: true, nomeMunicipio: true, estado: true },
  },
  cidade: {
    select: { codigo: true, nomeMunicipio: true, estado: true },
  },
  escolaridade: { select: { codigo: true, descricao: true } },
} satisfies Prisma.AlunoInclude;

type AlunoComRelacoes = Prisma.AlunoGetPayload<{
  include: typeof alunoInclude;
}>;

async function validarCidadeAtiva(codigo: number, label: string) {
  const cidade = await prisma.cidade.findUnique({ where: { codigo } });
  if (!cidade || !cidade.ativo) {
    throw new AlunoReferenciaError(`${label} inválida ou inativa`);
  }
}

async function validarReferencias(data: {
  naturalidadeCodigo?: number | null;
  escolaridadeCodigo?: number | null;
  cidadeCodigo?: number | null;
}) {
  if (data.naturalidadeCodigo) {
    await validarCidadeAtiva(data.naturalidadeCodigo, "Naturalidade (município)");
  }
  if (data.cidadeCodigo) {
    await validarCidadeAtiva(data.cidadeCodigo, "Município (endereço)");
  }
  if (data.escolaridadeCodigo) {
    await assertEscolaridadeCodigo(data.escolaridadeCodigo, {
      somenteAtiva: true,
    });
  }
}

function dadosPrismaFromInput(data: CreateAlunoInput) {
  return {
    ...(data.nome !== undefined && { nome: data.nome }),
    ...(data.nomeSocial !== undefined && { nomeSocial: data.nomeSocial }),
    ...(data.estadoCivil !== undefined && { estadoCivil: data.estadoCivil }),
    ...(data.rg !== undefined && { rg: data.rg }),
    ...(data.orgaoExpedidor !== undefined && {
      orgaoExpedidor: data.orgaoExpedidor,
    }),
    ...(data.dtExpedicaoRg !== undefined && {
      dtExpedicaoRg: parseDtExpedicaoRgAluno(data.dtExpedicaoRg),
    }),
    ...(data.cpf !== undefined && { cpf: data.cpf }),
    ...(data.dtNascimento !== undefined && {
      dtNascimento: parseDtNascimentoAluno(data.dtNascimento),
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
    ...(data.cidadeCodigo !== undefined && {
      cidadeCodigo: data.cidadeCodigo ?? null,
    }),
    ...(data.telefone !== undefined && { telefone: data.telefone }),
    ...(data.celular !== undefined && { celular: data.celular }),
    ...(data.telefoneRecado !== undefined && {
      telefoneRecado: data.telefoneRecado,
    }),
    ...(data.email !== undefined && { email: data.email }),
  };
}

export async function listAlunos(filters: ListAlunosFilters = {}) {
  const where: Prisma.AlunoWhereInput = {};

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

  const rows = await prisma.aluno.findMany({
    where,
    select: {
      id: true,
      nome: true,
      cpf: true,
      dtNascimento: true,
      ativo: true,
    },
    orderBy: [{ nome: "asc" }],
  });

  return rows.map(mapAlunoLista);
}

export async function getAlunoById(id: string) {
  return prisma.aluno.findUnique({
    where: { id },
    include: alunoInclude,
  });
}

export async function createAluno(data: CreateAlunoInput, usuarioId: string) {
  await validarReferencias(data);

  try {
    const aluno = await prisma.aluno.create({
      data: {
        ...dadosPrismaFromInput(data),
        ativo: true,
        ...auditInclusao(usuarioId),
      } as Prisma.AlunoUncheckedCreateInput,
    });

    const loaded = await getAlunoById(aluno.id);
    if (!loaded) {
      throw new AlunoValidationError("Falha ao carregar aluno após o registro");
    }
    return loaded;
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new AlunoConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function updateAluno(
  id: string,
  data: CreateAlunoInput,
  usuarioId: string,
) {
  const existing = await prisma.aluno.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new AlunoInativoError("Não é possível alterar um aluno desativado");
  }

  await validarReferencias(data);

  try {
    await prisma.aluno.update({
      where: { id },
      data: {
        ...dadosPrismaFromInput(data),
        ...auditAlteracao(usuarioId),
      },
    });

    return getAlunoById(id);
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new AlunoConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function desativarAluno(id: string, usuarioId: string) {
  const existing = await prisma.aluno.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    return getAlunoById(id);
  }

  return prisma.aluno.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
    include: alunoInclude,
  });
}

export class AlunoConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoConflictError";
  }
}

export class AlunoInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoInativoError";
  }
}

export class AlunoReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoReferenciaError";
  }
}

export class AlunoValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AlunoValidationError";
  }
}

function formatTelefoneExibicao(tel: string | null | undefined): string | null {
  if (!tel) return null;
  const d = tel.replace(/\D/g, "");
  if (d.length === 11) {
    return `(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}`;
  }
  if (d.length === 10) {
    return `(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}`;
  }
  return tel;
}

function formatCepExibicao(cep: string | null | undefined): string | null {
  if (!cep) return null;
  const d = cep.replace(/\D/g, "");
  if (d.length === 8) {
    return `${d.substring(0, 5)}-${d.substring(5)}`;
  }
  return cep;
}

function mapAlunoCore(
  a: Pick<
    AlunoComRelacoes,
    | "id"
    | "nome"
    | "nomeSocial"
    | "estadoCivil"
    | "rg"
    | "orgaoExpedidor"
    | "dtExpedicaoRg"
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
    | "telefone"
    | "celular"
    | "telefoneRecado"
    | "email"
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
    dtExpedicaoRg: a.dtExpedicaoRg ? formatDataBr(a.dtExpedicaoRg) : null,
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
    cepFormatado: formatCepExibicao(a.cep),
    cidadeCodigo: a.cidadeCodigo,
    cidadeNome: a.cidade?.nomeMunicipio ?? null,
    cidadeEstado: a.cidade?.estado ?? null,
    telefone: a.telefone,
    telefoneFormatado: formatTelefoneExibicao(a.telefone),
    celular: a.celular,
    celularFormatado: formatTelefoneExibicao(a.celular),
    telefoneRecado: a.telefoneRecado,
    telefoneRecadoFormatado: formatTelefoneExibicao(a.telefoneRecado),
    email: a.email,
    ativo: a.ativo,
    ...mapAuditoria(a, usuarios),
  };
}

export function mapAluno(a: AlunoComRelacoes, usuarios?: UsuarioAuditoriaMap) {
  return mapAlunoCore(a, usuarios);
}

type AlunoListaRow = {
  id: string;
  nome: string;
  cpf: string | null;
  dtNascimento: Date | null;
  ativo: boolean;
};

/** Resposta enxuta para `GET /alunos` (listagem — sem joins nem auditoria). */
export function mapAlunoLista(a: AlunoListaRow) {
  const idade =
    a.dtNascimento != null ? calcularIdade(a.dtNascimento) : null;

  return {
    id: a.id,
    nome: a.nome,
    cpf: a.cpf,
    cpfFormatado: a.cpf ? formatCpf(a.cpf) : null,
    dtNascimento: a.dtNascimento ? formatDataBr(a.dtNascimento) : null,
    idade,
    ativo: a.ativo,
  };
}
