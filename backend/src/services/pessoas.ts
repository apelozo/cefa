import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { formatDataBr } from "../lib/campo.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { formatCpf, normalizeCpf } from "../lib/cpf.js";
import { formatRg, normalizeRg } from "../lib/rg.js";
import { prisma } from "../lib/prisma.js";
import type { CreatePessoaInput, UpdatePessoaInput } from "../validators/pessoas.js";
import { parseDtNascimento } from "../validators/pessoas.js";

export type ListPessoasFilters = {
  ativo?: boolean;
  /** @deprecated Use nome, cpf ou rg */
  q?: string;
  nome?: string;
  cpf?: string;
  rg?: string;
};

const pessoaInclude = {
  bairro: { select: { codigo: true, nome: true } },
  cidade: { select: { codigo: true, nomeMunicipio: true, estado: true } },
} satisfies Prisma.PessoaInclude;

type PessoaComRelacoes = Prisma.PessoaGetPayload<{ include: typeof pessoaInclude }>;

export async function listPessoas(filters: ListPessoasFilters = {}) {
  const where: Prisma.PessoaWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  const nome = filters.nome?.trim();
  const cpfDigits = filters.cpf ? normalizeCpf(filters.cpf) : "";
  const rgNorm = filters.rg ? normalizeRg(filters.rg) : "";

  if (nome) {
    where.nome = { contains: nome, mode: "insensitive" };
  }
  if (cpfDigits.length > 0) {
    where.cpf = { contains: cpfDigits };
  }
  if (rgNorm.length > 0) {
    where.rg = { contains: rgNorm, mode: "insensitive" };
  }

  const legacyQ = filters.q?.trim();
  if (legacyQ && !nome && !cpfDigits && !rgNorm) {
    const digits = legacyQ.replace(/\D/g, "");
    const or: Prisma.PessoaWhereInput[] = [
      { nome: { contains: legacyQ, mode: "insensitive" } },
    ];
    const rgLegacy = normalizeRg(legacyQ);
    if (rgLegacy.length > 0) {
      or.push({ rg: { contains: rgLegacy, mode: "insensitive" } });
    }
    if (digits.length > 0) {
      or.push({ cpf: { contains: digits } });
    }
    where.OR = or;
  }

  return prisma.pessoa.findMany({
    where,
    include: pessoaInclude,
    orderBy: [{ nome: "asc" }, { dataHoraInclusao: "asc" }],
  });
}

export async function getPessoaById(id: string) {
  return prisma.pessoa.findUnique({
    where: { id },
    include: pessoaInclude,
  });
}

async function validarReferencias(data: {
  bairroCodigo?: number | null;
  cidadeCodigo?: number | null;
}) {
  if (data.bairroCodigo) {
    const bairro = await prisma.bairro.findUnique({
      where: { codigo: data.bairroCodigo },
    });
    if (!bairro || !bairro.ativo) {
      throw new PessoaReferenciaError("Bairro inválido ou inativo");
    }
  }

  if (data.cidadeCodigo) {
    const cidade = await prisma.cidade.findUnique({
      where: { codigo: data.cidadeCodigo },
    });
    if (!cidade || !cidade.ativo) {
      throw new PessoaReferenciaError("Município inválido ou inativo");
    }
  }
}

function dadosOpcionaisPessoa(data: CreatePessoaInput | UpdatePessoaInput) {
  return {
    ...(data.nomeSocial !== undefined && { nomeSocial: data.nomeSocial }),
    ...(data.nomeMae !== undefined && { nomeMae: data.nomeMae }),
    ...(data.nomePai !== undefined && { nomePai: data.nomePai }),
    ...(data.nis !== undefined && { nis: data.nis }),
    ...(data.rgOrgaoEmissao !== undefined && { rgOrgaoEmissao: data.rgOrgaoEmissao }),
    ...(data.endereco !== undefined && { endereco: data.endereco }),
    ...(data.enderecoNumero !== undefined && { enderecoNumero: data.enderecoNumero }),
    ...(data.enderecoComplemento !== undefined && {
      enderecoComplemento: data.enderecoComplemento,
    }),
    ...(data.bairroCodigo !== undefined && { bairroCodigo: data.bairroCodigo }),
    ...(data.cidadeCodigo !== undefined && { cidadeCodigo: data.cidadeCodigo }),
    ...(data.telefone !== undefined && { telefone: data.telefone }),
    ...(data.telefone2 !== undefined && { telefone2: data.telefone2 }),
    ...(data.urbanoRural !== undefined && { urbanoRural: data.urbanoRural }),
  };
}

export async function createPessoa(data: CreatePessoaInput, usuarioId: string) {
  await validarReferencias(data);

  return prisma.pessoa.create({
    data: {
      nome: data.nome,
      dtNascimento: parseDtNascimento(data.dtNascimento),
      cpf: data.cpf,
      rg: data.rg,
      ativo: data.ativo,
      ...dadosOpcionaisPessoa(data),
      ...auditInclusao(usuarioId),
    },
    include: pessoaInclude,
  });
}

export async function updatePessoa(
  id: string,
  data: UpdatePessoaInput,
  usuarioId: string,
) {
  const existing = await prisma.pessoa.findUnique({ where: { id } });
  if (!existing) return null;

  await validarReferencias({
    bairroCodigo:
      data.bairroCodigo !== undefined ? data.bairroCodigo : existing.bairroCodigo,
    cidadeCodigo:
      data.cidadeCodigo !== undefined ? data.cidadeCodigo : existing.cidadeCodigo,
  });

  try {
    return await prisma.pessoa.update({
      where: { id },
      data: {
        ...(data.nome !== undefined && { nome: data.nome }),
        ...(data.dtNascimento !== undefined && {
          dtNascimento: parseDtNascimento(data.dtNascimento),
        }),
        ...(data.cpf !== undefined && { cpf: data.cpf }),
        ...(data.rg !== undefined && { rg: data.rg }),
        ...(data.ativo !== undefined && { ativo: data.ativo }),
        ...dadosOpcionaisPessoa(data),
        ...auditAlteracao(usuarioId),
      },
      include: pessoaInclude,
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new PessoaConflictError("CPF já cadastrado");
    }
    throw err;
  }
}

export async function deletePessoa(id: string) {
  const existing = await prisma.pessoa.findUnique({
    where: { id },
    include: pessoaInclude,
  });
  if (!existing) return null;

  const submissoes = await prisma.submissao.count({ where: { pessoaId: id } });
  if (submissoes > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem lançamentos vinculados a este assistido",
    );
  }

  const entrevistas = await prisma.entrevistaAssistido.count({
    where: { pessoaId: id },
  });
  if (entrevistas > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem entrevistas vinculadas a este assistido",
    );
  }

  await prisma.pessoa.delete({ where: { id } });
  return existing;
}

export class PessoaConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PessoaConflictError";
  }
}

export class PessoaReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PessoaReferenciaError";
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

export function mapPessoa(p: PessoaComRelacoes, usuarios?: UsuarioAuditoriaMap) {
  return {
    id: p.id,
    nome: p.nome,
    nomeSocial: p.nomeSocial,
    nomeMae: p.nomeMae,
    nomePai: p.nomePai,
    dtNascimento: formatDataBr(p.dtNascimento),
    cpf: p.cpf,
    cpfFormatado: formatCpf(p.cpf),
    rg: p.rg,
    rgFormatado: formatRg(p.rg),
    rgOrgaoEmissao: p.rgOrgaoEmissao,
    nis: p.nis,
    endereco: p.endereco,
    enderecoNumero: p.enderecoNumero,
    enderecoComplemento: p.enderecoComplemento,
    bairroCodigo: p.bairroCodigo,
    bairroNome: p.bairro?.nome ?? null,
    cidadeCodigo: p.cidadeCodigo,
    cidadeNome: p.cidade?.nomeMunicipio ?? null,
    cidadeEstado: p.cidade?.estado ?? null,
    telefone: p.telefone,
    telefoneFormatado: formatTelefoneExibicao(p.telefone),
    telefone2: p.telefone2,
    telefone2Formatado: formatTelefoneExibicao(p.telefone2),
    urbanoRural: p.urbanoRural,
    ativo: p.ativo,
    ...mapAuditoria(p, usuarios),
  };
}
