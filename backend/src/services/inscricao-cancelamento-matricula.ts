import { Prisma } from "@prisma/client";

import { formatDataBr } from "../lib/campo.js";
import { formatCpf } from "../lib/cpf.js";
import { calcularIdade } from "../lib/idade.js";
import { rotuloPeriodoInscricao } from "../lib/periodo-inscricao.js";
import { prisma } from "../lib/prisma.js";
import { assertTurmaCodigo } from "./turmas.js";
import type { GravarCancelamentoMatriculaInput } from "../validators/inscricao-cancelamento-matricula.js";

const matriculadoInclude = {
  aluno: {
    select: {
      nome: true,
      cpf: true,
      dtNascimento: true,
      escolaridade: { select: { descricao: true } },
    },
  },
  turma: {
    select: {
      codigo: true,
      nome: true,
      periodo: true,
      curso: { select: { codigo: true, descricao: true } },
    },
  },
} satisfies Prisma.InscricaoAlunoCursoInclude;

type InscricaoMatriculada = Prisma.InscricaoAlunoCursoGetPayload<{
  include: typeof matriculadoInclude;
}>;

function mapMatriculado(row: InscricaoMatriculada) {
  const dataMatricula =
    row.dtInicioCurso != null
      ? formatDataBr(row.dtInicioCurso)
      : row.dataHoraMatricula != null
        ? formatDataBr(row.dataHoraMatricula)
        : null;

  return {
    id: row.id,
    codigo: row.codigo,
    alunoNome: row.aluno.nome,
    alunoCpf: row.aluno.cpf,
    alunoCpfFormatado: row.aluno.cpf ? formatCpf(row.aluno.cpf) : null,
    dataMatricula,
    alunoIdade:
      row.aluno.dtNascimento != null
        ? calcularIdade(row.aluno.dtNascimento)
        : null,
    escolaridadeDescricao: row.aluno.escolaridade?.descricao ?? null,
    orgaoEncaminhamento: row.orgaoEncaminhamento,
    matriculado: row.matriculado,
    matriculaCancelada: row.matriculaCancelada,
  };
}

function mapTurmaResumo(turma: InscricaoMatriculada["turma"], total: number) {
  return {
    turmaCodigo: turma.codigo,
    turmaNome: turma.nome,
    cursoCodigo: turma.curso.codigo,
    cursoDescricao: turma.curso.descricao,
    periodo: turma.periodo,
    periodoRotulo: rotuloPeriodoInscricao(turma.periodo),
    totalMatriculados: total,
  };
}

export async function listCancelamentoMatriculaMatriculados(turmaCodigo: number) {
  await assertTurmaCodigo(turmaCodigo, { somenteAtivo: true });

  const rows = await prisma.inscricaoAlunoCurso.findMany({
    where: {
      ativo: true,
      turmaCodigo,
      matriculado: true,
      matriculaCancelada: false,
    },
    include: matriculadoInclude,
    orderBy: [{ aluno: { nome: "asc" } }, { codigo: "asc" }],
  });

  if (rows.length === 0) {
    const turma = await prisma.turma.findUnique({
      where: { codigo: turmaCodigo },
      include: { curso: { select: { codigo: true, descricao: true } } },
    });
    if (!turma) {
      throw new CancelamentoMatriculaTurmaError("Turma não encontrada");
    }
    return {
      ...mapTurmaResumo(
        {
          codigo: turma.codigo,
          nome: turma.nome,
          periodo: turma.periodo,
          curso: turma.curso,
        },
        0,
      ),
      matriculados: [] as ReturnType<typeof mapMatriculado>[],
    };
  }

  const turma = rows[0]!.turma;

  return {
    ...mapTurmaResumo(turma, rows.length),
    matriculados: rows.map(mapMatriculado),
  };
}

export async function gravarCancelamentoMatricula(
  data: GravarCancelamentoMatriculaInput,
  usuarioId: string,
) {
  await assertTurmaCodigo(data.turmaCodigo, { somenteAtivo: true });

  const inscricoes = await prisma.inscricaoAlunoCurso.findMany({
    where: {
      ativo: true,
      turmaCodigo: data.turmaCodigo,
      matriculado: true,
      matriculaCancelada: false,
    },
    select: { id: true },
  });

  const idsTurma = new Set(inscricoes.map((i) => i.id));
  for (const id of data.inscricaoIds) {
    if (!idsTurma.has(id)) {
      throw new CancelamentoMatriculaValidationError(
        "Uma ou mais inscrições não estão matriculadas nesta turma",
      );
    }
  }

  const agora = new Date();

  await prisma.$transaction(async (tx) => {
    await tx.inscricaoAlunoCurso.updateMany({
      where: { id: { in: data.inscricaoIds } },
      data: {
        matriculado: false,
        matriculaCancelada: true,
        usuarioCancelamentoMatriculaId: usuarioId,
        dataHoraCancelamentoMatricula: agora,
      },
    });
  });

  return listCancelamentoMatriculaMatriculados(data.turmaCodigo);
}

export class CancelamentoMatriculaValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CancelamentoMatriculaValidationError";
  }
}

export class CancelamentoMatriculaTurmaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CancelamentoMatriculaTurmaError";
  }
}
