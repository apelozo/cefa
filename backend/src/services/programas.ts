import { Prisma } from "@prisma/client";

import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import { isModuloRelatoriosId } from "../lib/modulos-relatorio.js";
import type {
  CreateProgramaInput,
  UpdateProgramaInput,
} from "../validators/programas.js";
import {
  assertRelatorioSubmoduloAtivo,
  RelatorioSubmoduloInativoError,
  RelatorioSubmoduloNaoEncontradoError,
} from "./relatorio-submodulos.js";

const programaInclude = {
  moduloSistema: {
    select: { id: true, codigo: true, nome: true },
  },
  relatorioSubmodulo: {
    select: { id: true, codigo: true, nome: true, ordem: true },
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

async function validarRelatorioSubmodulo(
  moduloSistemaId: string | null | undefined,
  relatorioSubmoduloId: string | null | undefined,
) {
  const emRelatorios = await isModuloRelatoriosId(prisma, moduloSistemaId);

  if (emRelatorios) {
    if (!relatorioSubmoduloId) {
      throw new ProgramaReferenciaError(
        "Programas do módulo Relatórios exigem um submódulo",
      );
    }
    try {
      await assertRelatorioSubmoduloAtivo(relatorioSubmoduloId);
    } catch (err) {
      if (
        err instanceof RelatorioSubmoduloNaoEncontradoError ||
        err instanceof RelatorioSubmoduloInativoError
      ) {
        throw new ProgramaReferenciaError(err.message);
      }
      throw err;
    }
    return;
  }

  if (relatorioSubmoduloId) {
    throw new ProgramaReferenciaError(
      "Submódulo de relatório só pode ser usado no módulo Relatórios",
    );
  }
}

export async function createPrograma(data: CreateProgramaInput, usuarioId: string) {
  await validarModuloSistema(data.moduloSistemaId);
  await validarRelatorioSubmodulo(
    data.moduloSistemaId,
    data.relatorioSubmoduloId,
  );
  try {
    return await prisma.programa.create({
      data: {
        codigo: data.codigo,
        nome: data.nome,
        autoListagem: data.autoListagem ?? false,
        moduloSistemaId: data.moduloSistemaId ?? null,
        relatorioSubmoduloId: data.relatorioSubmoduloId ?? null,
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

  const moduloFinal =
    data.moduloSistemaId !== undefined
      ? data.moduloSistemaId
      : existing.moduloSistemaId;
  const submoduloFinal =
    data.relatorioSubmoduloId !== undefined
      ? data.relatorioSubmoduloId
      : existing.relatorioSubmoduloId;

  if (
    data.moduloSistemaId !== undefined ||
    data.relatorioSubmoduloId !== undefined
  ) {
    await validarRelatorioSubmodulo(moduloFinal, submoduloFinal);
  }

  const emRelatorios = await isModuloRelatoriosId(prisma, moduloFinal);
  const relatorioSubmoduloId = emRelatorios
    ? submoduloFinal
    : data.moduloSistemaId !== undefined ||
        data.relatorioSubmoduloId !== undefined
      ? null
      : undefined;

  return prisma.programa.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome }),
      ...(data.autoListagem !== undefined && { autoListagem: data.autoListagem }),
      ...(data.moduloSistemaId !== undefined && {
        moduloSistemaId: data.moduloSistemaId,
      }),
      ...(relatorioSubmoduloId !== undefined && {
        relatorioSubmoduloId,
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
  relatorioSubmoduloId?: string | null;
  moduloSistema?: { id: string; codigo: number; nome: string } | null;
  relatorioSubmodulo?: {
    id: string;
    codigo: string;
    nome: string;
    ordem: number;
  } | null;
}, usuarios?: UsuarioAuditoriaMap) {
  return {
    id: p.id,
    codigo: p.codigo,
    nome: p.nome,
    autoListagem: p.autoListagem,
    moduloSistemaId: p.moduloSistemaId ?? p.moduloSistema?.id ?? null,
    moduloCodigo: p.moduloSistema?.codigo ?? null,
    moduloNome: p.moduloSistema?.nome ?? null,
    relatorioSubmoduloId:
      p.relatorioSubmoduloId ?? p.relatorioSubmodulo?.id ?? null,
    relatorioSubmoduloCodigo: p.relatorioSubmodulo?.codigo ?? null,
    relatorioSubmoduloNome: p.relatorioSubmodulo?.nome ?? null,
    relatorioSubmoduloOrdem: p.relatorioSubmodulo?.ordem ?? null,
    ...mapAuditoria(p, usuarios),
  };
}
