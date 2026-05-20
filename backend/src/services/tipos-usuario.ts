import { PerfilTipoUsuario } from "@prisma/client";
import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateTipoUsuarioInput,
  PermissoesBodyInput,
  UpdateTipoUsuarioInput,
} from "../validators/tipos-usuario.js";

export async function listTiposUsuario(ativo?: boolean) {
  return prisma.tipoUsuario.findMany({
    where: ativo !== undefined ? { ativo } : undefined,
    orderBy: [{ descricao: "asc" }],
  });
}

export async function getTipoUsuarioById(id: string) {
  return prisma.tipoUsuario.findUnique({ where: { id } });
}

export async function createTipoUsuario(
  data: CreateTipoUsuarioInput,
  usuarioId: string,
) {
  return prisma.tipoUsuario.create({
    data: {
      ...data,
      ...auditInclusao(usuarioId),
    },
  });
}

export async function updateTipoUsuario(
  id: string,
  data: UpdateTipoUsuarioInput,
  usuarioId: string,
) {
  const existing = await prisma.tipoUsuario.findUnique({ where: { id } });
  if (!existing) return null;

  return prisma.tipoUsuario.update({
    where: { id },
    data: {
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...(data.perfil !== undefined && { perfil: data.perfil }),
      ...(data.ativo !== undefined && { ativo: data.ativo }),
      ...auditAlteracao(usuarioId),
    },
  });
}

export async function deleteTipoUsuario(id: string) {
  const existing = await prisma.tipoUsuario.findUnique({ where: { id } });
  if (!existing) return null;

  const usuarios = await prisma.usuario.count({ where: { tipoUsuarioId: id } });
  if (usuarios > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem usuários vinculados a este tipo",
    );
  }

  await prisma.$transaction([
    prisma.tipoUsuarioPermissao.deleteMany({ where: { tipoUsuarioId: id } }),
    prisma.tipoUsuario.delete({ where: { id } }),
  ]);
  return existing;
}

export async function getPermissoesTipoUsuario(tipoUsuarioId: string) {
  const tipo = await prisma.tipoUsuario.findUnique({
    where: { id: tipoUsuarioId },
  });
  if (!tipo) return null;

  const [programas, permissoes] = await Promise.all([
    prisma.programa.findMany({ orderBy: { nome: "asc" } }),
    prisma.tipoUsuarioPermissao.findMany({ where: { tipoUsuarioId } }),
  ]);

  const porPrograma = new Map(permissoes.map((p) => [p.programaId, p]));

  return {
    tipo,
    permissoes: programas.map((prog) => {
      const p = porPrograma.get(prog.id);
      return {
        programaId: prog.id,
        programaCodigo: prog.codigo,
        programaNome: prog.nome,
        podeIncluir: p?.podeIncluir ?? false,
        podeAlterar: p?.podeAlterar ?? false,
        podeConsultar: p?.podeConsultar ?? false,
        podeExcluir: p?.podeExcluir ?? false,
        perfilAdmin: tipo.perfil === PerfilTipoUsuario.ADMINISTRADOR,
      };
    }),
  };
}

export async function setPermissoesTipoUsuario(
  tipoUsuarioId: string,
  body: PermissoesBodyInput,
  usuarioId: string,
) {
  const tipo = await prisma.tipoUsuario.findUnique({
    where: { id: tipoUsuarioId },
  });
  if (!tipo) return null;

  if (tipo.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    throw new Error("Tipo administrador possui permissão total");
  }

  const inclusao = auditInclusao(usuarioId);

  await prisma.$transaction(async (tx) => {
    await tx.tipoUsuarioPermissao.deleteMany({ where: { tipoUsuarioId } });
    if (body.permissoes.length > 0) {
      await tx.tipoUsuarioPermissao.createMany({
        data: body.permissoes.map((p) => ({
          tipoUsuarioId,
          programaId: p.programaId,
          podeIncluir: p.podeIncluir,
          podeAlterar: p.podeAlterar,
          podeConsultar: p.podeConsultar,
          podeExcluir: p.podeExcluir,
          ...inclusao,
        })),
      });
    }
    await tx.tipoUsuario.update({
      where: { id: tipoUsuarioId },
      data: auditAlteracao(usuarioId),
    });
  });

  return getPermissoesTipoUsuario(tipoUsuarioId);
}

export function mapTipoUsuario(t: {
  id: string;
  descricao: string;
  perfil: PerfilTipoUsuario;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
}) {
  return {
    id: t.id,
    descricao: t.descricao,
    perfil: t.perfil,
    ativo: t.ativo,
    ...mapAuditoria(t),
  };
}
