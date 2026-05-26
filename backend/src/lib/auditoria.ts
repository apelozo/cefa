import { prisma } from "./prisma.js";

/** Retorna instante UTC para gravação em `timestamptz`. */
export function utcNow(): Date {
  return new Date();
}

/** Dados de auditoria na inclusão (inclusão + alteração inicial iguais). */
export function auditInclusao(usuarioId: string) {
  const now = utcNow();
  return {
    usuarioInclusaoId: usuarioId,
    dataHoraInclusao: now,
    usuarioAlteracaoId: usuarioId,
    dataHoraAlteracao: now,
  };
}

/** Dados de auditoria na alteração. */
export function auditAlteracao(usuarioId: string) {
  return {
    usuarioAlteracaoId: usuarioId,
    dataHoraAlteracao: utcNow(),
  };
}

/** Soft delete: desativa o registro e grava quem/quando excluiu (sem apagar do banco). */
export function auditSoftDelete(usuarioId: string) {
  const now = utcNow();
  return {
    ativo: false,
    usuarioExclusaoId: usuarioId,
    dataHoraExclusao: now,
    usuarioAlteracaoId: usuarioId,
    dataHoraAlteracao: now,
  };
}

export type RegistroSoftDelete = {
  usuarioExclusaoId: string | null;
  dataHoraExclusao: Date | null;
};

export type RegistroAuditoria = {
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
};

export type RegistroComAuditoriaIds = RegistroAuditoria &
  Partial<RegistroSoftDelete>;

export type UsuarioAuditoriaResumo = {
  nomeUsuario: string;
  nome: string;
};

export type UsuarioAuditoriaMap = Map<string, UsuarioAuditoriaResumo>;

/** Carrega `nomeUsuario` e nome completo para os IDs de auditoria informados. */
export async function enrichUsuarioMap(
  records: Iterable<RegistroComAuditoriaIds>,
): Promise<UsuarioAuditoriaMap> {
  const ids = new Set<string>();
  for (const r of records) {
    if (r.usuarioInclusaoId) ids.add(r.usuarioInclusaoId);
    if (r.usuarioAlteracaoId) ids.add(r.usuarioAlteracaoId);
    if (r.usuarioExclusaoId) ids.add(r.usuarioExclusaoId);
  }
  if (ids.size === 0) return new Map();

  const rows = await prisma.usuario.findMany({
    where: { id: { in: [...ids] } },
    select: { id: true, nomeUsuario: true, nome: true },
  });

  return new Map(
    rows.map((u) => [
      u.id,
      { nomeUsuario: u.nomeUsuario, nome: u.nome },
    ]),
  );
}

function usuarioCampos(
  usuarios: UsuarioAuditoriaMap | undefined,
  prefix: "Inclusao" | "Alteracao" | "Exclusao",
  userId: string | null,
) {
  const u = userId && usuarios ? usuarios.get(userId) : undefined;
  return {
    [`usuario${prefix}NomeUsuario`]: u?.nomeUsuario ?? null,
    [`usuario${prefix}Nome`]: u?.nome ?? null,
  };
}

export function mapSoftDeleteAuditoria(
  e: RegistroSoftDelete,
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    usuarioExclusaoId: e.usuarioExclusaoId,
    dataHoraExclusao: e.dataHoraExclusao?.toISOString() ?? null,
    ...usuarioCampos(usuarios, "Exclusao", e.usuarioExclusaoId),
  };
}

/** Bootstrap / sync sem usuário autenticado (ex.: seed, catálogo). */
export function auditSistema() {
  const now = utcNow();
  return {
    usuarioInclusaoId: null as string | null,
    dataHoraInclusao: now,
    usuarioAlteracaoId: null as string | null,
    dataHoraAlteracao: now,
  };
}

/** Apenas alteração em operações de sistema (sync). */
export function auditAlteracaoSistema() {
  return {
    usuarioAlteracaoId: null as string | null,
    dataHoraAlteracao: utcNow(),
  };
}

export function mapAuditoria(
  a: RegistroAuditoria,
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    usuarioInclusaoId: a.usuarioInclusaoId,
    dataHoraInclusao: a.dataHoraInclusao.toISOString(),
    usuarioAlteracaoId: a.usuarioAlteracaoId,
    dataHoraAlteracao: a.dataHoraAlteracao?.toISOString() ?? null,
    ...usuarioCampos(usuarios, "Inclusao", a.usuarioInclusaoId),
    ...usuarioCampos(usuarios, "Alteracao", a.usuarioAlteracaoId),
    /** Compatível com clientes que ainda leem `createdAt`. */
    createdAt: a.dataHoraInclusao.toISOString(),
  };
}
