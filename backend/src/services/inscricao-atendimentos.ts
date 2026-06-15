import { Prisma } from "@prisma/client";

import {
  auditAlteracao,
  auditInclusao,
  mapAuditoria,
  type UsuarioAuditoriaMap,
} from "../lib/auditoria.js";
import { formatDataBr } from "../lib/campo.js";
import { normalizeCpf } from "../lib/cpf.js";
import { prisma } from "../lib/prisma.js";
import { assertTurmaCodigo } from "./turmas.js";
import { parseDtCurso } from "../validators/inscricoes.js";
import type {
  CreateInscricaoAtendimentoInput,
  UpdateInscricaoAtendimentoInput,
} from "../validators/inscricao-atendimentos.js";

const RESUMO_MAX = 50;

function descricaoResumo(texto: string): string {
  const t = texto.trim();
  if (t.length <= RESUMO_MAX) return t;
  return `${t.slice(0, RESUMO_MAX)}…`;
}

export async function resolveInscricaoParaAtendimento(params: {
  inscricaoId?: string;
  turmaCodigo?: number;
  alunoId?: string;
}) {
  if (params.inscricaoId) {
    const row = await prisma.inscricaoAlunoCurso.findUnique({
      where: { id: params.inscricaoId },
      include: {
        aluno: { select: { id: true, nome: true, cpf: true } },
        turma: {
          select: {
            codigo: true,
            nome: true,
            curso: { select: { codigo: true, descricao: true } },
          },
        },
      },
    });
    if (!row || !row.ativo) {
      throw new AtendimentoValidationError("Inscrição não encontrada");
    }
    return row;
  }

  if (params.turmaCodigo == null || !params.alunoId) {
    throw new AtendimentoValidationError(
      "Informe a turma e o aluno da inscrição",
    );
  }

  await assertTurmaCodigo(params.turmaCodigo, { somenteAtivo: true });

  const row = await prisma.inscricaoAlunoCurso.findFirst({
    where: {
      ativo: true,
      turmaCodigo: params.turmaCodigo,
      alunoId: params.alunoId,
    },
    include: {
      aluno: { select: { id: true, nome: true, cpf: true } },
      turma: {
        select: {
          codigo: true,
          nome: true,
          curso: { select: { codigo: true, descricao: true } },
        },
      },
    },
  });

  if (!row) {
    throw new AtendimentoValidationError(
      "Inscrição não encontrada para esta turma e aluno",
    );
  }

  return row;
}

function assertInscricaoMatriculadaAtiva(inscricao: {
  matriculado: boolean;
  matriculaCancelada: boolean;
}) {
  if (!inscricao.matriculado || inscricao.matriculaCancelada) {
    throw new AtendimentoValidationError(
      "O aluno não está matriculado nesta turma",
    );
  }
}

export type ListAlunosMatriculadosFilters = {
  turmaCodigo: number;
  nome?: string;
  cpf?: string;
};

export async function listAlunosMatriculados(
  filters: ListAlunosMatriculadosFilters,
) {
  await assertTurmaCodigo(filters.turmaCodigo, { somenteAtivo: true });

  const nome = filters.nome?.trim();
  const cpfDigits = filters.cpf ? normalizeCpf(filters.cpf) : "";

  const where: Prisma.InscricaoAlunoCursoWhereInput = {
    ativo: true,
    turmaCodigo: filters.turmaCodigo,
    OR: [{ matriculado: true }, { matriculaCancelada: true }],
  };

  if (nome || cpfDigits.length > 0) {
    where.aluno = {
      ...(nome && { nome: { contains: nome, mode: "insensitive" } }),
      ...(cpfDigits.length > 0 && { cpf: { contains: cpfDigits } }),
    };
  } else {
    return [];
  }

  const rows = await prisma.inscricaoAlunoCurso.findMany({
    where,
    orderBy: [{ aluno: { nome: "asc" } }],
    include: {
      aluno: { select: { id: true, nome: true, cpf: true } },
    },
  });

  return rows.map((row) => ({
    inscricaoId: row.id,
    inscricaoCodigo: row.codigo,
    alunoId: row.aluno.id,
    alunoNome: row.aluno.nome,
    alunoCpf: row.aluno.cpf,
    matriculado: row.matriculado,
    matriculaCancelada: row.matriculaCancelada,
  }));
}

export async function listInscricaoAtendimentos(params: {
  inscricaoId?: string;
  turmaCodigo?: number;
  alunoId?: string;
}) {
  const inscricao = await resolveInscricaoParaAtendimento(params);

  const items = await prisma.inscricaoAtendimento.findMany({
    where: { inscricaoId: inscricao.id },
    orderBy: [{ dataAtendimento: "desc" }, { dataHoraInclusao: "desc" }],
  });

  return { inscricao, items };
}

export async function getInscricaoAtendimentoById(id: string) {
  return prisma.inscricaoAtendimento.findUnique({
    where: { id },
    include: {
      inscricao: {
        include: {
          aluno: { select: { id: true, nome: true } },
          turma: {
            select: {
              codigo: true,
              nome: true,
              curso: { select: { descricao: true } },
            },
          },
        },
      },
    },
  });
}

export async function createInscricaoAtendimento(
  data: CreateInscricaoAtendimentoInput,
  usuarioId: string,
) {
  const inscricao = await resolveInscricaoParaAtendimento({
    inscricaoId: data.inscricaoId,
    turmaCodigo: data.turmaCodigo,
    alunoId: data.alunoId,
  });
  assertInscricaoMatriculadaAtiva(inscricao);

  const dataAtendimento = parseDtCurso(data.dataAtendimento);
  if (!dataAtendimento) {
    throw new AtendimentoValidationError("Data do atendimento inválida");
  }

  return prisma.inscricaoAtendimento.create({
    data: {
      inscricaoId: inscricao.id,
      dataAtendimento,
      descricao: data.descricao.trim(),
      ...auditInclusao(usuarioId),
    },
  });
}

export async function updateInscricaoAtendimento(
  id: string,
  data: UpdateInscricaoAtendimentoInput,
  usuarioId: string,
) {
  const existing = await prisma.inscricaoAtendimento.findUnique({
    where: { id },
    include: {
      inscricao: { select: { ativo: true } },
    },
  });
  if (!existing) return null;

  if (!existing.inscricao.ativo) {
    throw new AtendimentoValidationError(
      "Não é possível alterar atendimento — inscrição inativa",
    );
  }

  const dataAtendimento = parseDtCurso(data.dataAtendimento);
  if (!dataAtendimento) {
    throw new AtendimentoValidationError("Data do atendimento inválida");
  }

  return prisma.inscricaoAtendimento.update({
    where: { id },
    data: {
      dataAtendimento,
      descricao: data.descricao.trim(),
      ...auditAlteracao(usuarioId),
    },
  });
}

export async function deleteInscricaoAtendimento(id: string) {
  const existing = await prisma.inscricaoAtendimento.findUnique({
    where: { id },
  });
  if (!existing) return false;

  await prisma.inscricaoAtendimento.delete({ where: { id } });
  return true;
}

export function mapInscricaoAtendimento(
  row: {
    id: string;
    inscricaoId: string;
    dataAtendimento: Date;
    descricao: string;
    usuarioInclusaoId: string | null;
    dataHoraInclusao: Date;
    usuarioAlteracaoId: string | null;
    dataHoraAlteracao: Date | null;
  },
  usuarios: UsuarioAuditoriaMap,
) {
  return {
    id: row.id,
    inscricaoId: row.inscricaoId,
    dataAtendimento: formatDataBr(row.dataAtendimento),
    descricao: row.descricao,
    descricaoResumo: descricaoResumo(row.descricao),
    ...mapAuditoria(row, usuarios),
    createdAt: row.dataHoraInclusao.toISOString(),
  };
}

export function mapInscricaoAtendimentoLista(
  row: {
    id: string;
    inscricaoId: string;
    dataAtendimento: Date;
    descricao: string;
  },
) {
  return {
    id: row.id,
    inscricaoId: row.inscricaoId,
    dataAtendimento: formatDataBr(row.dataAtendimento),
    descricaoResumo: descricaoResumo(row.descricao),
  };
}

export function mapAlunoMatriculadoResumo(
  row: {
    inscricaoId: string;
    inscricaoCodigo: number;
    alunoId: string;
    alunoNome: string;
    alunoCpf: string | null;
    matriculado: boolean;
    matriculaCancelada: boolean;
  },
) {
  return {
    inscricaoId: row.inscricaoId,
    inscricaoCodigo: row.inscricaoCodigo,
    alunoId: row.alunoId,
    alunoNome: row.alunoNome,
    alunoCpf: row.alunoCpf,
    matriculado: row.matriculado,
    matriculaCancelada: row.matriculaCancelada,
  };
}

export class AtendimentoValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AtendimentoValidationError";
  }
}
