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

export function mapSoftDeleteAuditoria(e: RegistroSoftDelete) {
  return {
    usuarioExclusaoId: e.usuarioExclusaoId,
    dataHoraExclusao: e.dataHoraExclusao?.toISOString() ?? null,
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

export type RegistroAuditoria = {
  usuarioInclusaoId: string | null;
  dataHoraInclusao: Date;
  usuarioAlteracaoId: string | null;
  dataHoraAlteracao: Date | null;
};

export function mapAuditoria(a: RegistroAuditoria) {
  return {
    usuarioInclusaoId: a.usuarioInclusaoId,
    dataHoraInclusao: a.dataHoraInclusao.toISOString(),
    usuarioAlteracaoId: a.usuarioAlteracaoId,
    dataHoraAlteracao: a.dataHoraAlteracao?.toISOString() ?? null,
    /** Compatível com clientes que ainda leem `createdAt`. */
    createdAt: a.dataHoraInclusao.toISOString(),
  };
}
