import { auditAlteracao, auditInclusao, mapAuditoria } from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { prisma } from "../lib/prisma.js";
import type {
  CreateTipoFormularioInput,
  UpdateTipoFormularioInput,
} from "../validators/tipos-formulario.js";
import {
  grantTipoFormularioAoTipoUsuario,
  resolveTiposFormularioIds,
} from "./tipos-formulario-acesso.js";
import { loadUsuarioComTipo } from "./permissoes.js";

export async function listTiposFormulario(
  usuarioId: string,
  options?: { ativo?: boolean; todos?: boolean },
) {
  const where: { ativo?: boolean; id?: { in: string[] } } = {};
  if (options?.ativo !== undefined) {
    where.ativo = options.ativo;
  }

  if (!options?.todos) {
    const ids = await resolveTiposFormularioIds(usuarioId);
    if (ids !== "all") {
      if (ids.length === 0) {
        return [];
      }
      where.id = { in: ids };
    }
  }

  return prisma.tipoFormulario.findMany({
    where,
    orderBy: [{ nome: "asc" }, { dataHoraInclusao: "asc" }],
  });
}

export async function getTipoFormularioById(id: string) {
  return prisma.tipoFormulario.findUnique({ where: { id } });
}

export async function createTipoFormulario(
  data: CreateTipoFormularioInput,
  usuarioId: string,
) {
  const usuario = await loadUsuarioComTipo(usuarioId);
  const item = await prisma.tipoFormulario.create({
    data: {
      ...data,
      ...auditInclusao(usuarioId),
    },
  });

  if (usuario) {
    await grantTipoFormularioAoTipoUsuario(
      usuario.tipoUsuarioId,
      item.id,
      usuarioId,
    );
  }

  return item;
}

export async function updateTipoFormulario(
  id: string,
  data: UpdateTipoFormularioInput,
  usuarioId: string,
) {
  const existing = await prisma.tipoFormulario.findUnique({ where: { id } });
  if (!existing) return null;

  return prisma.tipoFormulario.update({
    where: { id },
    data: {
      ...(data.nome !== undefined && { nome: data.nome }),
      ...(data.descricao !== undefined && { descricao: data.descricao }),
      ...(data.ativo !== undefined && { ativo: data.ativo }),
      ...auditAlteracao(usuarioId),
    },
  });
}

export async function deleteTipoFormulario(id: string) {
  const existing = await prisma.tipoFormulario.findUnique({ where: { id } });
  if (!existing) return null;

  const [perguntas, submissoes] = await Promise.all([
    prisma.pergunta.count({ where: { tipoFormularioId: id } }),
    prisma.submissao.count({ where: { tipoFormularioId: id } }),
  ]);

  if (submissoes > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem lançamentos vinculados a este tipo de formulário",
    );
  }
  if (perguntas > 0) {
    throw new DeleteBlockedError(
      "Não é possível excluir: existem perguntas vinculadas a este tipo de formulário",
    );
  }

  await prisma.tipoFormulario.delete({ where: { id } });
  return existing;
}

export function mapTipoFormulario(t: {
  id: string;
  nome: string;
  descricao: string | null;
  ativo: boolean;
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
}) {
  return {
    id: t.id,
    nome: t.nome,
    descricao: t.descricao,
    ativo: t.ativo,
    ...mapAuditoria(t),
  };
}
