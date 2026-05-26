import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
} from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type { CreateCursoInput, UpdateCursoInput } from "../validators/cursos.js";

export type ListCursosFilters = {
  ativo?: boolean;
  codigo?: number;
  descricao?: string;
};

async function nextCursoCodigo(): Promise<number> {
  const result = await prisma.curso.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

export async function listCursos(filters: ListCursosFilters = {}) {
  const where: Prisma.CursoWhereInput = {};

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

  return prisma.curso.findMany({
    where,
    orderBy: [{ codigo: "asc" }],
  });
}

export async function getCursoById(id: string) {
  return prisma.curso.findUnique({ where: { id } });
}

export async function getCursoByCodigo(codigo: number) {
  return prisma.curso.findUnique({ where: { codigo } });
}

export async function assertCursoCodigo(
  codigo: number,
  options?: { somenteAtivo?: boolean },
) {
  const row = await prisma.curso.findUnique({ where: { codigo } });
  if (!row) {
    throw new CursoNaoEncontradoError("Curso não encontrado");
  }
  if (options?.somenteAtivo !== false && !row.ativo) {
    throw new CursoInativoError("Curso inativo não pode ser utilizado");
  }
  return row;
}

export async function createCurso(data: CreateCursoInput, usuarioId: string) {
  const codigo = await nextCursoCodigo();

  try {
    return await prisma.curso.create({
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
      throw new CursoConflictError("Já existe um curso com este código");
    }
    throw err;
  }
}

export async function updateCurso(
  id: string,
  data: UpdateCursoInput,
  usuarioId: string,
) {
  const existing = await prisma.curso.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new CursoInativoError("Não é possível alterar um curso desativado");
  }

  return prisma.curso.update({
    where: { id },
    data: {
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...auditAlteracao(usuarioId),
    },
  });
}

/** Desativa (`ativo = false`) — registro permanece no banco. */
export async function desativarCurso(id: string, usuarioId: string) {
  const existing = await prisma.curso.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) return existing;

  return prisma.curso.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
  });
}

export class CursoConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CursoConflictError";
  }
}

export class CursoInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CursoInativoError";
  }
}

export class CursoNaoEncontradoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CursoNaoEncontradoError";
  }
}

export function mapCurso(c: {
  id: string;
  codigo: number;
  descricao: string;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
}) {
  return {
    id: c.id,
    codigo: c.codigo,
    descricao: c.descricao,
    ativo: c.ativo,
    ...mapAuditoria(c),
  };
}
