import { Prisma } from "@prisma/client";

import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateRelatorioSubmoduloInput,
  UpdateRelatorioSubmoduloInput,
} from "../validators/relatorio-submodulos.js";

export type ListRelatorioSubmodulosFilters = {
  ativo?: boolean;
  codigo?: string;
  nome?: string;
};

export async function listRelatorioSubmodulos(
  filters: ListRelatorioSubmodulosFilters = {},
) {
  const where: Prisma.RelatorioSubmoduloWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  const codigo = filters.codigo?.trim().toLowerCase();
  if (codigo) {
    where.codigo = codigo;
  }

  const nome = filters.nome?.trim();
  if (nome) {
    where.nome = { contains: nome, mode: "insensitive" };
  }

  return prisma.relatorioSubmodulo.findMany({
    where,
    orderBy: [{ ordem: "asc" }, { nome: "asc" }],
  });
}

export async function getRelatorioSubmoduloById(id: string) {
  return prisma.relatorioSubmodulo.findUnique({ where: { id } });
}

export async function createRelatorioSubmodulo(
  data: CreateRelatorioSubmoduloInput,
  usuarioId: string,
) {
  try {
    return await prisma.relatorioSubmodulo.create({
      data: {
        codigo: data.codigo.trim().toLowerCase(),
        nome: data.nome.trim(),
        descricao: data.descricao?.trim() || null,
        ordem: data.ordem ?? 0,
        ativo: data.ativo ?? true,
        ...auditInclusao(usuarioId),
      },
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new RelatorioSubmoduloConflictError("Código de submódulo já cadastrado");
    }
    throw err;
  }
}

export async function updateRelatorioSubmodulo(
  id: string,
  data: UpdateRelatorioSubmoduloInput,
  usuarioId: string,
) {
  const existing = await prisma.relatorioSubmodulo.findUnique({ where: { id } });
  if (!existing) return null;

  return prisma.relatorioSubmodulo.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome.trim() }),
      ...(data.descricao !== undefined && {
        descricao: data.descricao?.trim() || null,
      }),
      ...(data.ordem !== undefined && { ordem: data.ordem }),
      ...(data.ativo !== undefined && { ativo: data.ativo }),
      ...auditAlteracao(usuarioId),
    },
  });
}

/** Exclusão física — bloqueada se houver programas vinculados. */
export async function deleteRelatorioSubmodulo(id: string) {
  const existing = await prisma.relatorioSubmodulo.findUnique({ where: { id } });
  if (!existing) return null;

  const programas = await prisma.programa.count({
    where: { relatorioSubmoduloId: id },
  });
  if (programas > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem programas vinculados a este submódulo.",
    );
  }

  await prisma.relatorioSubmodulo.delete({ where: { id } });
  return existing;
}

export async function assertRelatorioSubmoduloAtivo(id: string) {
  const row = await prisma.relatorioSubmodulo.findUnique({ where: { id } });
  if (!row) {
    throw new RelatorioSubmoduloNaoEncontradoError("Submódulo não encontrado");
  }
  if (!row.ativo) {
    throw new RelatorioSubmoduloInativoError(
      "Submódulo inativo não pode ser vinculado a programas",
    );
  }
  return row;
}

export class RelatorioSubmoduloConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelatorioSubmoduloConflictError";
  }
}

export class RelatorioSubmoduloNaoEncontradoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelatorioSubmoduloNaoEncontradoError";
  }
}

export class RelatorioSubmoduloInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelatorioSubmoduloInativoError";
  }
}

export function mapRelatorioSubmodulo(
  s: {
    id: string;
    codigo: string;
    nome: string;
    descricao: string | null;
    ordem: number;
    ativo: boolean;
    usuarioInclusaoId: string | null;
    dataHoraInclusao: Date;
    usuarioAlteracaoId: string | null;
    dataHoraAlteracao: Date | null;
  },
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    id: s.id,
    codigo: s.codigo,
    nome: s.nome,
    descricao: s.descricao,
    ordem: s.ordem,
    ativo: s.ativo,
    ...mapAuditoria(s, usuarios),
  };
}
