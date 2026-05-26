import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  auditSoftDelete,
  mapAuditoria,
  mapSoftDeleteAuditoria,
} from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateEscolaridadeInput,
  UpdateEscolaridadeInput,
} from "../validators/escolaridades.js";

export type ListEscolaridadesFilters = {
  ativo?: boolean;
  codigo?: number;
  descricao?: string;
};

async function nextEscolaridadeCodigo(): Promise<number> {
  const result = await prisma.escolaridade.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

export async function listEscolaridades(filters: ListEscolaridadesFilters = {}) {
  const where: Prisma.EscolaridadeWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  if (filters.codigo !== undefined) {
    where.codigo = filters.codigo;
  }

  const descricao = filters.descricao?.trim();
  if (descricao) {
    where.descricao = { contains: descricao, mode: "insensitive" };
  }

  return prisma.escolaridade.findMany({
    where,
    orderBy: [{ codigo: "asc" }],
  });
}

export async function getEscolaridadeById(id: string) {
  return prisma.escolaridade.findUnique({ where: { id } });
}

export async function getEscolaridadeByCodigo(codigo: number) {
  return prisma.escolaridade.findUnique({ where: { codigo } });
}

export async function assertEscolaridadeCodigo(
  codigo: number,
  options?: { somenteAtiva?: boolean },
) {
  const row = await prisma.escolaridade.findUnique({ where: { codigo } });
  if (!row) {
    throw new EscolaridadeNaoEncontradaError("Escolaridade não encontrada");
  }
  if (options?.somenteAtiva !== false && !row.ativo) {
    throw new EscolaridadeInativaError(
      "Escolaridade inativa não pode ser utilizada",
    );
  }
  return row;
}

export async function createEscolaridade(
  data: CreateEscolaridadeInput,
  usuarioId: string,
) {
  const codigo = await nextEscolaridadeCodigo();

  try {
    return await prisma.escolaridade.create({
      data: {
        codigo,
        descricao: data.descricao,
        ativo: true,
        ...auditInclusao(usuarioId),
      },
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new EscolaridadeConflictError(
        "Já existe uma escolaridade com este código",
      );
    }
    throw err;
  }
}

export async function updateEscolaridade(
  id: string,
  data: UpdateEscolaridadeInput,
  usuarioId: string,
) {
  const existing = await prisma.escolaridade.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new EscolaridadeInativaError(
      "Não é possível alterar uma escolaridade desativada",
    );
  }

  return prisma.escolaridade.update({
    where: { id },
    data: {
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...auditAlteracao(usuarioId),
    },
  });
}

/** Soft delete — não remove o registro do banco. */
export async function softDeleteEscolaridade(id: string, usuarioId: string) {
  const existing = await prisma.escolaridade.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) return existing;

  return prisma.escolaridade.update({
    where: { id },
    data: auditSoftDelete(usuarioId),
  });
}

export class EscolaridadeConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EscolaridadeConflictError";
  }
}

export class EscolaridadeInativaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EscolaridadeInativaError";
  }
}

export class EscolaridadeNaoEncontradaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EscolaridadeNaoEncontradaError";
  }
}

export function mapEscolaridade(e: {
  id: string;
  codigo: number;
  descricao: string;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  usuarioExclusaoId: string | null;
  dataHoraExclusao: Date | null;
}) {
  return {
    id: e.id,
    codigo: e.codigo,
    descricao: e.descricao,
    ativo: e.ativo,
    ...mapAuditoria(e),
    ...mapSoftDeleteAuditoria(e),
  };
}
