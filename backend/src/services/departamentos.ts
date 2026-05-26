import { Prisma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
} from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import { countHorariosPorDepartamentoCodigo } from "./voluntario-departamento-horarios.js";
import type {
  CreateDepartamentoInput,
  UpdateDepartamentoInput,
} from "../validators/departamentos.js";

export type ListDepartamentosFilters = {
  ativo?: boolean;
  codigo?: number;
  descricao?: string;
};

async function nextDepartamentoCodigo(): Promise<number> {
  const result = await prisma.departamento.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

export async function listDepartamentos(
  filters: ListDepartamentosFilters = {},
) {
  const where: Prisma.DepartamentoWhereInput = {};

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

  return prisma.departamento.findMany({
    where,
    orderBy: [{ codigo: "asc" }],
  });
}

export async function getDepartamentoById(id: string) {
  return prisma.departamento.findUnique({ where: { id } });
}

export async function createDepartamento(
  data: CreateDepartamentoInput,
  usuarioId: string,
) {
  const codigo = await nextDepartamentoCodigo();

  try {
    return await prisma.departamento.create({
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
      throw new DepartamentoConflictError(
        "Já existe um departamento com este código",
      );
    }
    throw err;
  }
}

export async function updateDepartamento(
  id: string,
  data: UpdateDepartamentoInput,
  usuarioId: string,
) {
  const existing = await prisma.departamento.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new DepartamentoInativoError(
      "Não é possível alterar um departamento desativado",
    );
  }

  return prisma.departamento.update({
    where: { id },
    data: {
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...auditAlteracao(usuarioId),
    },
  });
}

/** Desativa (`ativo = false`) — registro permanece no banco. */
export async function desativarDepartamento(id: string, usuarioId: string) {
  const existing = await prisma.departamento.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) return existing;

  const vinculos = await countHorariosPorDepartamentoCodigo(existing.codigo);
  if (vinculos > 0) {
    throw new DeleteBlockedError(
      "Não é possível desativar: existem voluntários vinculados a este departamento",
    );
  }

  return prisma.departamento.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
  });
}

export class DepartamentoConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DepartamentoConflictError";
  }
}

export class DepartamentoInativoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DepartamentoInativoError";
  }
}

export function mapDepartamento(d: {
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
    id: d.id,
    codigo: d.codigo,
    descricao: d.descricao,
    ativo: d.ativo,
    ...mapAuditoria(d),
  };
}
