import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import { temAcessoPrograma } from "./permissoes.js";
import type {
  CreateModuloSistemaInput,
  ModulosProgramasBodyInput,
  UpdateModuloSistemaInput,
} from "../validators/modulos-sistema.js";

const programaSelect = {
  id: true,
  codigo: true,
  nome: true,
  autoListagem: true,
} as const;

export async function listModulosSistema(ativo?: boolean) {
  return prisma.moduloSistema.findMany({
    where: ativo !== undefined ? { ativo } : undefined,
    orderBy: [{ ordem: "asc" }, { nome: "asc" }],
    include: {
      programas: {
        select: programaSelect,
        orderBy: { nome: "asc" },
      },
    },
  });
}

export async function getModuloSistemaById(id: string) {
  return prisma.moduloSistema.findUnique({
    where: { id },
    include: {
      programas: {
        select: programaSelect,
        orderBy: { nome: "asc" },
      },
    },
  });
}

export async function createModuloSistema(
  data: CreateModuloSistemaInput,
  usuarioId: string,
) {
  return prisma.moduloSistema.create({
    data: {
      ...data,
      ...auditInclusao(usuarioId),
    },
  });
}

export async function updateModuloSistema(
  id: string,
  data: UpdateModuloSistemaInput,
  usuarioId: string,
) {
  const existing = await prisma.moduloSistema.findUnique({ where: { id } });
  if (!existing) return null;

  return prisma.moduloSistema.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome }),
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...(data.ordem !== undefined && { ordem: data.ordem }),
      ...(data.ativo !== undefined && { ativo: data.ativo }),
      ...auditAlteracao(usuarioId),
    },
  });
}

export async function deleteModuloSistema(id: string) {
  const existing = await prisma.moduloSistema.findUnique({ where: { id } });
  if (!existing) return null;

  const programas = await prisma.programa.count({
    where: { moduloSistemaId: id },
  });
  if (programas > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem programas vinculados a este módulo. Reassocie os programas antes.",
    );
  }

  await prisma.moduloSistema.delete({ where: { id } });
  return existing;
}

export async function setModuloProgramas(
  moduloId: string,
  body: ModulosProgramasBodyInput,
  usuarioId: string,
) {
  const modulo = await prisma.moduloSistema.findUnique({ where: { id: moduloId } });
  if (!modulo) return null;

  const ids = [...new Set(body.programaIds)];
  const alteracao = auditAlteracao(usuarioId);

  await prisma.$transaction(async (tx) => {
    const desvinculados = await tx.programa.findMany({
      where: { moduloSistemaId: moduloId },
      select: { id: true },
    });
    if (desvinculados.length > 0) {
      await tx.programa.updateMany({
        where: { id: { in: desvinculados.map((p) => p.id) } },
        data: { moduloSistemaId: null, ...alteracao },
      });
    }
    if (ids.length > 0) {
      await tx.programa.updateMany({
        where: { id: { in: ids } },
        data: { moduloSistemaId: moduloId, ...alteracao },
      });
    }
    await tx.moduloSistema.update({
      where: { id: moduloId },
      data: alteracao,
    });
  });

  return getModuloSistemaById(moduloId);
}

export async function buildMenuModulos(
  permissaoMap: Awaited<
    ReturnType<typeof import("./permissoes.js").buildPermissaoMap>
  >,
  isAdmin = false,
) {
  const modulos = await prisma.moduloSistema.findMany({
    where: { ativo: true },
    orderBy: [{ ordem: "asc" }, { nome: "asc" }],
    include: {
      programas: {
        orderBy: { nome: "asc" },
      },
    },
  });

  return modulos
    .map((modulo) => {
      const programas = isAdmin
        ? modulo.programas
        : modulo.programas.filter((p) =>
            temAcessoPrograma(permissaoMap, p.codigo),
          );
      if (programas.length === 0) return null;
      return {
        id: modulo.id,
        codigo: modulo.codigo,
        nome: modulo.nome,
        descricao: modulo.descricao,
        ordem: modulo.ordem,
        programas: programas.map((p) => ({
          id: p.id,
          codigo: p.codigo,
          nome: p.nome,
        })),
      };
    })
    .filter((m): m is NonNullable<typeof m> => m !== null);
}

export function mapModuloSistema(m: {
  id: string;
  codigo: number;
  nome: string;
  descricao: string | null;
  ordem: number;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  programas?: {
    id: string;
    codigo: string;
    nome: string;
    autoListagem: boolean;
  }[];
}) {
  return {
    id: m.id,
    codigo: m.codigo,
    nome: m.nome,
    descricao: m.descricao,
    ordem: m.ordem,
    ativo: m.ativo,
    ...mapAuditoria(m),
    programas: m.programas?.map((p) => ({
      id: p.id,
      codigo: p.codigo,
      nome: p.nome,
      autoListagem: p.autoListagem,
    })),
  };
}
