import { PerfilTipoUsuario } from "@prisma/client";
import { auditAlteracao, auditInclusao } from "../lib/auditoria.js";
import { prisma } from "../lib/prisma.js";
import type { TiposFormularioAcessoBodyInput } from "../validators/tipos-formulario-acesso.js";
import { loadUsuarioComTipo } from "./permissoes.js";

export class TipoFormularioAcessoNegadoError extends Error {
  constructor(message = "Sem acesso a este tipo de formulário") {
    super(message);
    this.name = "TipoFormularioAcessoNegadoError";
  }
}

export type TiposFormularioAcessoResumo = {
  acessoTotal: boolean;
  usaOverride?: boolean;
  tipos: Array<{
    id: string;
    nome: string;
    descricao: string | null;
    ativo: boolean;
    liberado: boolean;
  }>;
};

async function listarTiposParaLiberacao() {
  return prisma.tipoFormulario.findMany({
    orderBy: [{ nome: "asc" }, { dataHoraInclusao: "asc" }],
    select: { id: true, nome: true, descricao: true, ativo: true },
  });
}

export async function resolveTiposFormularioIds(
  usuarioId: string,
): Promise<string[] | "all"> {
  const usuario = await loadUsuarioComTipo(usuarioId);
  if (!usuario || !usuario.ativo) return [];

  if (usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    return "all";
  }

  if (usuario.overrideTiposFormulario) {
    const rows = await prisma.usuarioTipoFormulario.findMany({
      where: { usuarioId },
      select: { tipoFormularioId: true },
    });
    return rows.map((r) => r.tipoFormularioId);
  }

  const rows = await prisma.tipoUsuarioTipoFormulario.findMany({
    where: { tipoUsuarioId: usuario.tipoUsuarioId },
    select: { tipoFormularioId: true },
  });
  return rows.map((r) => r.tipoFormularioId);
}

export async function usuarioTemAcessoTipoFormulario(
  usuarioId: string,
  tipoFormularioId: string,
): Promise<boolean> {
  const ids = await resolveTiposFormularioIds(usuarioId);
  if (ids === "all") return true;
  return ids.includes(tipoFormularioId);
}

export async function assertUsuarioAcessoTipoFormulario(
  usuarioId: string,
  tipoFormularioId: string,
): Promise<void> {
  const ok = await usuarioTemAcessoTipoFormulario(usuarioId, tipoFormularioId);
  if (!ok) {
    throw new TipoFormularioAcessoNegadoError();
  }
}

/** Filtro para listagens operacionais (perguntas, submissões). */
export async function buildFiltroTiposFormulario(
  usuarioId: string,
  tipoFormularioId?: string,
): Promise<{ tipoFormularioId?: string; tipoFormularioIds?: string[] }> {
  const ids = await resolveTiposFormularioIds(usuarioId);
  if (ids === "all") {
    return tipoFormularioId ? { tipoFormularioId } : {};
  }
  if (tipoFormularioId) {
    if (!ids.includes(tipoFormularioId)) {
      throw new TipoFormularioAcessoNegadoError();
    }
    return { tipoFormularioId };
  }
  return { tipoFormularioIds: ids };
}

export async function grantTipoFormularioAoTipoUsuario(
  tipoUsuarioId: string,
  tipoFormularioId: string,
  actorId: string,
) {
  const inclusao = auditInclusao(actorId);
  await prisma.tipoUsuarioTipoFormulario.upsert({
    where: {
      tipoUsuarioId_tipoFormularioId: { tipoUsuarioId, tipoFormularioId },
    },
    create: {
      tipoUsuarioId,
      tipoFormularioId,
      ...inclusao,
    },
    update: auditAlteracao(actorId),
  });
}

export async function getTiposFormularioAcessoTipoUsuario(
  tipoUsuarioId: string,
): Promise<TiposFormularioAcessoResumo | null> {
  const tipo = await prisma.tipoUsuario.findUnique({
    where: { id: tipoUsuarioId },
  });
  if (!tipo) return null;

  const tipos = await listarTiposParaLiberacao();
  if (tipo.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    return {
      acessoTotal: true,
      tipos: tipos.map((t) => ({ ...t, liberado: true })),
    };
  }

  const liberados = await prisma.tipoUsuarioTipoFormulario.findMany({
    where: { tipoUsuarioId },
    select: { tipoFormularioId: true },
  });
  const set = new Set(liberados.map((l) => l.tipoFormularioId));

  return {
    acessoTotal: false,
    tipos: tipos.map((t) => ({
      ...t,
      liberado: set.has(t.id),
    })),
  };
}

export async function setTiposFormularioAcessoTipoUsuario(
  tipoUsuarioId: string,
  body: TiposFormularioAcessoBodyInput,
  actorId: string,
) {
  const tipo = await prisma.tipoUsuario.findUnique({
    where: { id: tipoUsuarioId },
  });
  if (!tipo) return null;

  if (tipo.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    throw new Error("Tipo administrador possui acesso a todos os tipos de formulário");
  }

  const ids = [...new Set(body.tipoFormularioIds)];
  const inclusao = auditInclusao(actorId);

  await prisma.$transaction(async (tx) => {
    await tx.tipoUsuarioTipoFormulario.deleteMany({ where: { tipoUsuarioId } });
    if (ids.length > 0) {
      await tx.tipoUsuarioTipoFormulario.createMany({
        data: ids.map((tipoFormularioId) => ({
          tipoUsuarioId,
          tipoFormularioId,
          ...inclusao,
        })),
      });
    }
    await tx.tipoUsuario.update({
      where: { id: tipoUsuarioId },
      data: auditAlteracao(actorId),
    });
  });

  return getTiposFormularioAcessoTipoUsuario(tipoUsuarioId);
}

export async function getTiposFormularioAcessoUsuario(
  usuarioId: string,
): Promise<TiposFormularioAcessoResumo | null> {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: { tipoUsuario: true },
  });
  if (!usuario) return null;

  const tipos = await listarTiposParaLiberacao();
  if (usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    return {
      acessoTotal: true,
      tipos: tipos.map((t) => ({ ...t, liberado: true })),
    };
  }

  let liberadoIds: Set<string>;
  if (usuario.overrideTiposFormulario) {
    const rows = await prisma.usuarioTipoFormulario.findMany({
      where: { usuarioId },
      select: { tipoFormularioId: true },
    });
    liberadoIds = new Set(rows.map((r) => r.tipoFormularioId));
  } else {
    const rows = await prisma.tipoUsuarioTipoFormulario.findMany({
      where: { tipoUsuarioId: usuario.tipoUsuarioId },
      select: { tipoFormularioId: true },
    });
    liberadoIds = new Set(rows.map((r) => r.tipoFormularioId));
  }

  return {
    acessoTotal: false,
    usaOverride: usuario.overrideTiposFormulario,
    tipos: tipos.map((t) => ({
      ...t,
      liberado: liberadoIds.has(t.id),
    })),
  };
}

export async function setTiposFormularioAcessoUsuario(
  usuarioId: string,
  body: TiposFormularioAcessoBodyInput,
  actorId: string,
) {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: { tipoUsuario: true },
  });
  if (!usuario) return null;

  if (usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    throw new Error("Usuário administrador possui acesso a todos os tipos de formulário");
  }

  const ids = [...new Set(body.tipoFormularioIds)];
  const inclusao = auditInclusao(actorId);

  await prisma.$transaction(async (tx) => {
    await tx.usuarioTipoFormulario.deleteMany({ where: { usuarioId } });
    if (ids.length > 0) {
      await tx.usuarioTipoFormulario.createMany({
        data: ids.map((tipoFormularioId) => ({
          usuarioId,
          tipoFormularioId,
          ...inclusao,
        })),
      });
    }
    await tx.usuario.update({
      where: { id: usuarioId },
      data: {
        overrideTiposFormulario: true,
        ...auditAlteracao(actorId),
      },
    });
  });

  return getTiposFormularioAcessoUsuario(usuarioId);
}
