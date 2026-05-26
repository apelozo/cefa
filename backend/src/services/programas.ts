import { Prisma } from "@prisma/client";

import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateProgramaInput,
  UpdateProgramaInput,
} from "../validators/programas.js";

const programaInclude = {
  moduloSistema: {
    select: { id: true, codigo: true, nome: true },
  },
} satisfies Prisma.ProgramaInclude;

export async function listProgramas() {
  return prisma.programa.findMany({
    orderBy: [{ nome: "asc" }],
    include: programaInclude,
  });
}

/** Mesma listagem usada em módulos do sistema e liberação de acessos. */
export const listProgramasParaPermissoes = listProgramas;

export async function getProgramaById(id: string) {
  return prisma.programa.findUnique({
    where: { id },
    include: programaInclude,
  });
}

async function validarModuloSistema(moduloSistemaId: string | null | undefined) {
  if (moduloSistemaId == null) return;
  const modulo = await prisma.moduloSistema.findUnique({
    where: { id: moduloSistemaId },
  });
  if (!modulo?.ativo) {
    throw new ProgramaReferenciaError("Módulo inválido ou inativo");
  }
}

export async function createPrograma(data: CreateProgramaInput, usuarioId: string) {
  await validarModuloSistema(data.moduloSistemaId);
  try {
    return await prisma.programa.create({
      data: {
        codigo: data.codigo,
        nome: data.nome,
        autoListagem: data.autoListagem ?? false,
        moduloSistemaId: data.moduloSistemaId ?? null,
        ...auditInclusao(usuarioId),
      },
      include: programaInclude,
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      throw new ProgramaConflictError("Código de programa já cadastrado");
    }
    throw err;
  }
}

export async function updatePrograma(
  id: string,
  data: UpdateProgramaInput,
  usuarioId: string,
) {
  const existing = await prisma.programa.findUnique({ where: { id } });
  if (!existing) return null;

  if (data.moduloSistemaId !== undefined) {
    await validarModuloSistema(data.moduloSistemaId);
  }

  return prisma.programa.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome }),
      ...(data.autoListagem !== undefined && { autoListagem: data.autoListagem }),
      ...(data.moduloSistemaId !== undefined && {
        moduloSistemaId: data.moduloSistemaId,
      }),
      ...auditAlteracao(usuarioId),
    },
    include: programaInclude,
  });
}

export class ProgramaConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ProgramaConflictError";
  }
}

export class ProgramaReferenciaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ProgramaReferenciaError";
  }
}

export function mapPrograma(p: {
  id: string;
  codigo: string;
  nome: string;
  autoListagem: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  moduloSistemaId?: string | null;
  moduloSistema?: { id: string; codigo: number; nome: string } | null;
}) {
  return {
    id: p.id,
    codigo: p.codigo,
    nome: p.nome,
    autoListagem: p.autoListagem,
    moduloSistemaId: p.moduloSistemaId ?? p.moduloSistema?.id ?? null,
    moduloCodigo: p.moduloSistema?.codigo ?? null,
    moduloNome: p.moduloSistema?.nome ?? null,
    ...mapAuditoria(p),
  };
}
