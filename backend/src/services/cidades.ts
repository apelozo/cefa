import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  auditSoftDelete,
  mapAuditoria,
  mapSoftDeleteAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type { CreateCidadeInput, UpdateCidadeInput } from "../validators/cidades.js";

export type ListCidadesFilters = {
  ativo?: boolean;
  nome?: string;
  estado?: string;
};

async function nextCidadeCodigo(): Promise<number> {
  const result = await prisma.cidade.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

export async function listCidades(filters: ListCidadesFilters = {}) {
  const where: Prisma.CidadeWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  const nome = filters.nome?.trim();
  if (nome) {
    where.nomeMunicipio = { contains: nome, mode: "insensitive" };
  }

  if (filters.estado) {
    where.estado = filters.estado as Prisma.EnumUfBrasilFilter;
  }

  return prisma.cidade.findMany({
    where,
    orderBy: [{ codigo: "asc" }],
  });
}

export async function getCidadeById(id: string) {
  return prisma.cidade.findUnique({ where: { id } });
}

export async function createCidade(data: CreateCidadeInput, usuarioId: string) {
  const codigo = await nextCidadeCodigo();

  try {
    return await prisma.cidade.create({
      data: {
        codigo,
        nomeMunicipio: data.nomeMunicipio,
        estado: data.estado,
        ativo: true,
        ...auditInclusao(usuarioId),
      },
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new CidadeConflictError(
        "Já existe município com este nome e estado",
      );
    }
    throw err;
  }
}

export async function updateCidade(
  id: string,
  data: UpdateCidadeInput,
  usuarioId: string,
) {
  const existing = await prisma.cidade.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new CidadeInativaError("Não é possível alterar uma cidade desativada");
  }

  try {
    return await prisma.cidade.update({
      where: { id },
      data: {
        ...(data.nomeMunicipio !== undefined && { nomeMunicipio: data.nomeMunicipio }),
        ...(data.estado !== undefined && { estado: data.estado }),
        ...auditAlteracao(usuarioId),
      },
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new CidadeConflictError(
        "Já existe município com este nome e estado",
      );
    }
    throw err;
  }
}

/** Soft delete — não remove o registro do banco. */
export async function softDeleteCidade(id: string, usuarioId: string) {
  const existing = await prisma.cidade.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) return existing;

  return prisma.cidade.update({
    where: { id },
    data: auditSoftDelete(usuarioId),
  });
}

export class CidadeConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CidadeConflictError";
  }
}

export class CidadeInativaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CidadeInativaError";
  }
}

export function mapCidade(
  c: {
    id: string;
    codigo: number;
    nomeMunicipio: string;
    estado: string;
    ativo: boolean;
    usuarioInclusaoId: string | null;
    dataHoraInclusao: Date;
    usuarioAlteracaoId: string | null;
    dataHoraAlteracao: Date | null;
    usuarioExclusaoId: string | null;
    dataHoraExclusao: Date | null;
  },
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    id: c.id,
    codigo: c.codigo,
    nomeMunicipio: c.nomeMunicipio,
    estado: c.estado,
    ativo: c.ativo,
    ...mapAuditoria(c, usuarios),
    ...mapSoftDeleteAuditoria(c, usuarios),
  };
}
