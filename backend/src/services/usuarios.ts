import { PerfilTipoUsuario } from "@prisma/client";
import { listProgramasParaPermissoes } from "./programas.js";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { hashSenha } from "../lib/password.js";
import { prisma } from "../lib/prisma.js";
import type { PermissoesBodyInput } from "../validators/tipos-usuario.js";
import type {
  CreateUsuarioInput,
  UpdateUsuarioInput,
} from "../validators/usuarios.js";

export async function listUsuarios(ativo?: boolean) {
  return prisma.usuario.findMany({
    where: ativo !== undefined ? { ativo } : undefined,
    include: { tipoUsuario: true },
    orderBy: [{ nome: "asc" }],
  });
}

export async function getUsuarioById(id: string) {
  return prisma.usuario.findUnique({
    where: { id },
    include: { tipoUsuario: true },
  });
}

export async function createUsuario(
  data: CreateUsuarioInput,
  usuarioId: string,
) {
  const senhaHash = await hashSenha(data.senha);
  return prisma.usuario.create({
    data: {
      nomeUsuario: data.nomeUsuario,
      nome: data.nome,
      email: data.email,
      senhaHash,
      tipoUsuarioId: data.tipoUsuarioId,
      ativo: data.ativo ?? true,
      ...auditInclusao(usuarioId),
    },
    include: { tipoUsuario: true },
  });
}

export async function updateUsuario(
  id: string,
  data: UpdateUsuarioInput,
  usuarioId: string,
) {
  const existing = await prisma.usuario.findUnique({
    where: { id },
    include: { tipoUsuario: true },
  });
  if (!existing) return null;

  const senhaHash =
    data.senha !== undefined ? await hashSenha(data.senha) : undefined;

  return prisma.usuario.update({
    where: { id },
    data: {
      ...(data.nomeUsuario !== undefined && { nomeUsuario: data.nomeUsuario }),
      ...(data.nome !== undefined && { nome: data.nome }),
      ...(data.email !== undefined && { email: data.email }),
      ...(senhaHash !== undefined && { senhaHash }),
      ...(data.tipoUsuarioId !== undefined && {
        tipoUsuarioId: data.tipoUsuarioId,
      }),
      ...(data.ativo !== undefined && { ativo: data.ativo }),
      ...auditAlteracao(usuarioId),
    },
    include: { tipoUsuario: true },
  });
}

async function countAdminsAtivos(excluirId?: string) {
  return prisma.usuario.count({
    where: {
      ativo: true,
      ...(excluirId ? { id: { not: excluirId } } : {}),
      tipoUsuario: { perfil: PerfilTipoUsuario.ADMINISTRADOR },
    },
  });
}

export async function deleteUsuario(id: string) {
  const existing = await prisma.usuario.findUnique({
    where: { id },
    include: { tipoUsuario: true },
  });
  if (!existing) return null;

  if (
    existing.ativo &&
    existing.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR
  ) {
    const outros = await countAdminsAtivos(id);
    if (outros === 0) {
      throw new DeleteBlockedError(
        "Não é possível excluir o último administrador ativo do sistema",
      );
    }
  }

  await prisma.$transaction([
    prisma.usuarioPermissao.deleteMany({ where: { usuarioId: id } }),
    prisma.usuarioTipoFormulario.deleteMany({ where: { usuarioId: id } }),
    prisma.usuario.delete({ where: { id } }),
  ]);
  return existing;
}

export async function getPermissoesUsuario(usuarioId: string) {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: { tipoUsuario: true },
  });
  if (!usuario) return null;

  const [programas, permissoes] = await Promise.all([
    listProgramasParaPermissoes(),
    prisma.usuarioPermissao.findMany({ where: { usuarioId } }),
  ]);

  const porPrograma = new Map(permissoes.map((p) => [p.programaId, p]));
  const isAdmin =
    usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR;

  return {
    usuario,
    permissoes: programas.map((prog) => {
      const p = porPrograma.get(prog.id);
      return {
        programaId: prog.id,
        programaCodigo: prog.codigo,
        programaNome: prog.nome,
        podeIncluir: isAdmin ? true : (p?.podeIncluir ?? false),
        podeAlterar: isAdmin ? true : (p?.podeAlterar ?? false),
        podeConsultar: isAdmin ? true : (p?.podeConsultar ?? false),
        podeExcluir: isAdmin ? true : (p?.podeExcluir ?? false),
        perfilAdmin: isAdmin,
        usaOverride: p != null,
      };
    }),
  };
}

export async function setPermissoesUsuario(
  usuarioId: string,
  body: PermissoesBodyInput,
  actorId: string,
) {
  const usuario = await prisma.usuario.findUnique({
    where: { id: usuarioId },
    include: { tipoUsuario: true },
  });
  if (!usuario) return null;

  if (usuario.tipoUsuario.perfil === PerfilTipoUsuario.ADMINISTRADOR) {
    throw new Error("Usuário administrador possui permissão total");
  }

  const inclusao = auditInclusao(actorId);

  await prisma.$transaction(async (tx) => {
    await tx.usuarioPermissao.deleteMany({ where: { usuarioId } });
    if (body.permissoes.length > 0) {
      await tx.usuarioPermissao.createMany({
        data: body.permissoes.map((p) => ({
          usuarioId,
          programaId: p.programaId,
          podeIncluir: p.podeIncluir,
          podeAlterar: p.podeAlterar,
          podeConsultar: p.podeConsultar,
          podeExcluir: p.podeExcluir,
          ...inclusao,
        })),
      });
    }
    await tx.usuario.update({
      where: { id: usuarioId },
      data: auditAlteracao(actorId),
    });
  });

  return getPermissoesUsuario(usuarioId);
}

export function mapUsuario(u: {
  id: string;
  nomeUsuario: string;
  nome: string;
  email: string;
  tipoUsuarioId: string;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
  tipoUsuario: {
    id: string;
    descricao: string;
    perfil: PerfilTipoUsuario;
    ativo: boolean;
  };
}, usuarios?: UsuarioAuditoriaMap) {
  return {
    id: u.id,
    nomeUsuario: u.nomeUsuario,
    nome: u.nome,
    email: u.email,
    tipoUsuarioId: u.tipoUsuarioId,
    tipoUsuario: {
      id: u.tipoUsuario.id,
      descricao: u.tipoUsuario.descricao,
      perfil: u.tipoUsuario.perfil,
      ativo: u.tipoUsuario.ativo,
    },
    ativo: u.ativo,
    ...mapAuditoria(u, usuarios),
  };
}
