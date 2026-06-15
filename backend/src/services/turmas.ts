import { Prisma, type SituacaoTurma } from "@prisma/client";
import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { rotuloPeriodoInscricao } from "../lib/periodo-inscricao.js";
import { rotuloSituacaoTurma } from "../lib/situacao-turma.js";
import { prisma } from "../lib/prisma.js";
import { assertCursoCodigo } from "./cursos.js";
import type { CreateTurmaInput, UpdateTurmaInput } from "../validators/turmas.js";

export type ListTurmasFilters = {
  ativo?: boolean;
  codigo?: number;
  nome?: string;
  cursoCodigo?: number;
  cursoDescricao?: string;
  periodo?: CreateTurmaInput["periodo"];
  situacao?: SituacaoTurma;
};

const turmaIncludeLista = {
  curso: { select: { codigo: true, descricao: true } },
} satisfies Prisma.TurmaInclude;

type TurmaComCurso = Prisma.TurmaGetPayload<{
  include: typeof turmaIncludeLista;
}>;

async function nextTurmaCodigo(): Promise<number> {
  const result = await prisma.turma.aggregate({
    _max: { codigo: true },
  });
  return (result._max.codigo ?? 0) + 1;
}

async function findTurmaAbertaConflito(
  cursoCodigo: number,
  periodo: CreateTurmaInput["periodo"],
  excludeTurmaId?: string,
) {
  return prisma.turma.findFirst({
    where: {
      cursoCodigo,
      periodo,
      situacao: "ABERTA",
      ativo: true,
      ...(excludeTurmaId && { id: { not: excludeTurmaId } }),
    },
  });
}

function mensagemTurmaAbertaConflito(
  turma: { codigo: number; nome: string },
  periodo: CreateTurmaInput["periodo"],
): string {
  return (
    `Já existe uma turma aberta para este curso no período ${rotuloPeriodoInscricao(periodo)}. ` +
    `Finalize a turma ${turma.codigo} — ${turma.nome} antes de criar ou reabrir outra.`
  );
}

async function assertSemTurmaAbertaConflito(
  cursoCodigo: number,
  periodo: CreateTurmaInput["periodo"],
  situacao: SituacaoTurma,
  excludeTurmaId?: string,
) {
  if (situacao !== "ABERTA") return;

  const conflito = await findTurmaAbertaConflito(
    cursoCodigo,
    periodo,
    excludeTurmaId,
  );
  if (conflito) {
    throw new TurmaAbertaConflitoError(
      mensagemTurmaAbertaConflito(conflito, periodo),
    );
  }
}

export async function listTurmas(filters: ListTurmasFilters = {}) {
  const where: Prisma.TurmaWhereInput = {};

  if (filters.ativo !== undefined) {
    where.ativo = filters.ativo;
  }

  if (filters.codigo !== undefined) {
    where.codigo = filters.codigo;
  }

  const nome = filters.nome?.trim();
  if (nome) {
    where.nome = { contains: nome, mode: "insensitive" };
  }

  if (filters.cursoCodigo !== undefined) {
    where.cursoCodigo = filters.cursoCodigo;
  }

  if (filters.periodo !== undefined) {
    where.periodo = filters.periodo;
  }

  if (filters.situacao !== undefined) {
    where.situacao = filters.situacao;
  }

  const cursoDescricao = filters.cursoDescricao?.trim();
  if (cursoDescricao) {
    where.curso = {
      descricao: { contains: cursoDescricao, mode: "insensitive" },
    };
  }

  const rows = await prisma.turma.findMany({
    where,
    include: turmaIncludeLista,
    orderBy: [{ codigo: "desc" }],
  });

  return rows.map(mapTurmaLista);
}

export async function getTurmaById(id: string) {
  return prisma.turma.findUnique({
    where: { id },
    include: turmaIncludeLista,
  });
}

export async function getTurmaByCodigo(codigo: number) {
  return prisma.turma.findUnique({
    where: { codigo },
    include: turmaIncludeLista,
  });
}

export async function assertTurmaCodigo(
  codigo: number,
  options?: { somenteAtivo?: boolean; somenteAberta?: boolean },
) {
  const row = await prisma.turma.findUnique({
    where: { codigo },
    include: turmaIncludeLista,
  });
  if (!row) {
    throw new TurmaNaoEncontradaError("Turma não encontrada");
  }
  if (options?.somenteAtivo !== false && !row.ativo) {
    throw new TurmaInativaError("Turma inativa não pode ser utilizada");
  }
  if (options?.somenteAberta && row.situacao !== "ABERTA") {
    throw new TurmaFechadaError(
      "Somente turmas abertas podem receber novas inscrições",
    );
  }
  return row;
}

export async function createTurma(data: CreateTurmaInput, usuarioId: string) {
  await assertCursoCodigo(data.cursoCodigo, { somenteAtivo: true });
  await assertSemTurmaAbertaConflito(
    data.cursoCodigo,
    data.periodo,
    data.situacao ?? "ABERTA",
  );

  const codigo = await nextTurmaCodigo();

  try {
    const created = await prisma.turma.create({
      data: {
        codigo,
        nome: data.nome,
        cursoCodigo: data.cursoCodigo,
        periodo: data.periodo,
        situacao: data.situacao ?? "ABERTA",
        ativo: true,
        ...auditInclusao(usuarioId),
      },
      include: turmaIncludeLista,
    });
    return created;
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      const conflito = await findTurmaAbertaConflito(
        data.cursoCodigo,
        data.periodo,
      );
      if (conflito) {
        throw new TurmaAbertaConflitoError(
          mensagemTurmaAbertaConflito(conflito, data.periodo),
        );
      }
      throw new TurmaConflictError("Já existe uma turma com este código");
    }
    throw err;
  }
}

export async function updateTurma(
  id: string,
  data: UpdateTurmaInput,
  usuarioId: string,
) {
  const existing = await prisma.turma.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    throw new TurmaInativaError("Não é possível alterar uma turma desativada");
  }

  const cursoCodigo = data.cursoCodigo ?? existing.cursoCodigo;
  const periodo = data.periodo ?? existing.periodo;
  const situacao = data.situacao ?? existing.situacao;

  if (data.cursoCodigo !== undefined) {
    await assertCursoCodigo(data.cursoCodigo, { somenteAtivo: true });
  }

  await assertSemTurmaAbertaConflito(cursoCodigo, periodo, situacao, id);

  try {
    return await prisma.turma.update({
      where: { id },
      data: {
        ...(data.nome !== undefined && { nome: data.nome }),
        ...(data.cursoCodigo !== undefined && { cursoCodigo: data.cursoCodigo }),
        ...(data.periodo !== undefined && { periodo: data.periodo }),
        ...(data.situacao !== undefined && { situacao: data.situacao }),
        ...auditAlteracao(usuarioId),
      },
      include: turmaIncludeLista,
    });
  } catch (err) {
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === "P2002"
    ) {
      const conflito = await findTurmaAbertaConflito(
        cursoCodigo,
        periodo,
        id,
      );
      if (conflito) {
        throw new TurmaAbertaConflitoError(
          mensagemTurmaAbertaConflito(conflito, periodo),
        );
      }
    }
    throw err;
  }
}

/** Desativa (`ativo = false`) — registro permanece no banco. */
export async function desativarTurma(id: string, usuarioId: string) {
  const existing = await prisma.turma.findUnique({ where: { id } });
  if (!existing) return null;
  if (!existing.ativo) {
    return getTurmaById(id);
  }

  const inscricoes = await prisma.inscricaoAlunoCurso.count({
    where: { turmaCodigo: existing.codigo, ativo: true },
  });
  if (inscricoes > 0) {
    throw new DeleteBlockedError(
      "Não é possível desativar: existem inscrições ativas vinculadas a esta turma",
    );
  }

  return prisma.turma.update({
    where: { id },
    data: {
      ativo: false,
      ...auditAlteracao(usuarioId),
    },
    include: turmaIncludeLista,
  });
}

export function mapTurmaLista(row: TurmaComCurso) {
  return {
    id: row.id,
    codigo: row.codigo,
    nome: row.nome,
    cursoCodigo: row.cursoCodigo,
    cursoDescricao: row.curso.descricao,
    periodo: row.periodo,
    periodoRotulo: rotuloPeriodoInscricao(row.periodo),
    situacao: row.situacao,
    situacaoRotulo: rotuloSituacaoTurma(row.situacao),
    ativo: row.ativo,
  };
}

export function mapTurma(
  row: TurmaComCurso,
  usuarios?: UsuarioAuditoriaMap,
) {
  return {
    ...mapTurmaLista(row),
    ...mapAuditoria(row, usuarios),
  };
}

export class TurmaConflictError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TurmaConflictError";
  }
}

export class TurmaAbertaConflitoError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TurmaAbertaConflitoError";
  }
}

export class TurmaInativaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TurmaInativaError";
  }
}

export class TurmaNaoEncontradaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TurmaNaoEncontradaError";
  }
}

export class TurmaFechadaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TurmaFechadaError";
  }
}
