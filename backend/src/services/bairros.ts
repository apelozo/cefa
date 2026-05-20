import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  auditSoftDelete,
  mapAuditoria,
  mapSoftDeleteAuditoria,
} from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type { CreateBairroInput, UpdateBairroInput } from "../validators/bairros.js";

export type ListBairrosFilters = {
  ativo?: boolean;
  codigo?: number;
  nome?: string;
};

async function nextBairroCodigo(): Promise<number> {
  const result = await prisma.bairro.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

export async function listBairros(filters: ListBairrosFilters = {}) {
  const where: Prisma.BairroWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  if (filters.codigo !== undefined) {
    where.codigo = filters.codigo;
  }

  const nome = filters.nome?.trim();
  if (nome) {
    where.nome = { contains: nome, mode: "insensitive" };
  }

  return prisma.bairro.findMany({
    where,
    orderBy: [{ codigo: "asc" }],
  });
}

export async function getBairroById(id: string) {
  return prisma.bairro.findUnique({ where: { id } });
}

export async function createBairro(data: CreateBairroInput, usuarioId: string) {
  const codigo = await nextBairroCodigo();

  try {
    return await prisma.bairro.create({
      data: {
        codigo,
        nome: data.nome,
        ativo: true,
        ...auditInclusao(usuarioId),
      },
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new BairroConflictError("Já existe um bairro com este código");
    }
    throw err;
  }
}

export async function updateBairro(
  id: string,
  data: UpdateBairroInput,
  usuarioId: string,
) {
  const existing = await prisma.bairro.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new BairroInativoError("Não é possível alterar um bairro desativado");
  }

  return prisma.bairro.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome }),
      ...auditAlteracao(usuarioId),
    },
  });
}

/** Soft delete — não remove o registro do banco. */
export async function softDeleteBairro(id: string, usuarioId: string) {
  const existing = await prisma.bairro.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) return existing;

  return prisma.bairro.update({
    where: { id },
    data: auditSoftDelete(usuarioId),
  });
}

export class BairroConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "BairroConflictError";
  }
}

export class BairroInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "BairroInativoError";
  }
}

export function mapBairro(b: {
  id: string;
  codigo: number;
  nome: string;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  usuarioExclusaoId: string | null;
  dataHoraExclusao: Date | null;
}) {
  return {
    id: b.id,
    codigo: b.codigo,
    nome: b.nome,
    ativo: b.ativo,
    ...mapAuditoria(b),
    ...mapSoftDeleteAuditoria(b),
  };
}
