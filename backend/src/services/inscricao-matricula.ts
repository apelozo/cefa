import { Prisma } from "@prisma/client";

import { calcularIdade } from "../lib/idade.js";
import { rotuloPeriodoInscricao } from "../lib/periodo-inscricao.js";
import { prisma } from "../lib/prisma.js";
import { assertTurmaCodigo } from "./turmas.js";
import type { GravarMatriculaInput } from "../validators/inscricao-matricula.js";
import { parseDtCurso } from "../validators/inscricoes.js";

const candidatoInclude = {
  aluno: {
    select: {
      nome: true,
      dtNascimento: true,
      escolaridade: { select: { descricao: true } },
    },
  },
  rendaFamiliar: { select: { renda: true } },
  turma: {
    select: {
      codigo: true,
      nome: true,
      periodo: true,
      curso: { select: { codigo: true, descricao: true } },
    },
  },
} satisfies Prisma.InscricaoAlunoCursoInclude;

type InscricaoCandidato = Prisma.InscricaoAlunoCursoGetPayload<{
  include: typeof candidatoInclude;
}>;

function calcularRendaPerCapita(items: { renda: Prisma.Decimal }[]): number {
  if (items.length === 0) return 0;
  const total = items.reduce(
    (sum, item) => sum + Number(item.renda.toString()),
    0,
  );
  return total / items.length;
}

function ordenarCandidatos(rows: InscricaoCandidato[]): InscricaoCandidato[] {
  return [...rows].sort((a, b) => {
    if (a.possuiEncaminhamento !== b.possuiEncaminhamento) {
      return a.possuiEncaminhamento ? -1 : 1;
    }
    const rendaA = calcularRendaPerCapita(a.rendaFamiliar);
    const rendaB = calcularRendaPerCapita(b.rendaFamiliar);
    if (rendaA !== rendaB) return rendaA - rendaB;
    return a.codigo - b.codigo;
  });
}

function mapCandidato(row: InscricaoCandidato) {
  const rendaPerCapita = calcularRendaPerCapita(row.rendaFamiliar);
  return {
    id: row.id,
    codigo: row.codigo,
    alunoNome: row.aluno.nome,
    alunoIdade:
      row.aluno.dtNascimento != null
        ? calcularIdade(row.aluno.dtNascimento)
        : null,
    escolaridadeDescricao: row.aluno.escolaridade?.descricao ?? null,
    orgaoEncaminhamento: row.orgaoEncaminhamento,
    possuiEncaminhamento: row.possuiEncaminhamento,
    rendaPerCapita,
    rendaPerCapitaFormatada: rendaPerCapita.toLocaleString("pt-BR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }),
    matriculado: row.matriculado,
  };
}

export async function listMatriculaCandidatos(turmaCodigo: number) {
  await assertTurmaCodigo(turmaCodigo, { somenteAtivo: true });

  const rows = await prisma.inscricaoAlunoCurso.findMany({
    where: {
      ativo: true,
      turmaCodigo,
      matriculaCancelada: false,
    },
    include: candidatoInclude,
  });

  if (rows.length === 0) {
    const turma = await prisma.turma.findUnique({
      where: { codigo: turmaCodigo },
      include: { curso: { select: { codigo: true, descricao: true } } },
    });
    if (!turma) {
      throw new MatriculaTurmaError("Turma não encontrada");
    }
    return {
      turmaCodigo: turma.codigo,
      turmaNome: turma.nome,
      cursoCodigo: turma.curso.codigo,
      cursoDescricao: turma.curso.descricao,
      periodo: turma.periodo,
      periodoRotulo: rotuloPeriodoInscricao(turma.periodo),
      totalMatriculados: 0,
      candidatos: [] as ReturnType<typeof mapCandidato>[],
    };
  }

  const ordenados = ordenarCandidatos(rows);
  const turma = ordenados[0]!.turma;
  const totalMatriculados = ordenados.filter(
    (r) => r.matriculado && !r.matriculaCancelada,
  ).length;

  return {
    turmaCodigo: turma.codigo,
    turmaNome: turma.nome,
    cursoCodigo: turma.curso.codigo,
    cursoDescricao: turma.curso.descricao,
    periodo: turma.periodo,
    periodoRotulo: rotuloPeriodoInscricao(turma.periodo),
    totalMatriculados,
    candidatos: ordenados.map(mapCandidato),
  };
}

export async function gravarMatricula(
  data: GravarMatriculaInput,
  usuarioId: string,
) {
  await assertTurmaCodigo(data.turmaCodigo, { somenteAtivo: true });

  const dtInicio = parseDtCurso(data.dtInicioCurso);
  if (!dtInicio) {
    throw new MatriculaValidationError("Data de início do curso inválida");
  }

  const inscricoes = await prisma.inscricaoAlunoCurso.findMany({
    where: {
      ativo: true,
      turmaCodigo: data.turmaCodigo,
      matriculaCancelada: false,
    },
    select: { id: true, matriculado: true, matriculaCancelada: true },
  });

  const idsTurma = new Set(inscricoes.map((i) => i.id));
  for (const id of data.inscricaoIds) {
    if (!idsTurma.has(id)) {
      const cancelada = await prisma.inscricaoAlunoCurso.findFirst({
        where: {
          id,
          ativo: true,
          turmaCodigo: data.turmaCodigo,
          matriculaCancelada: true,
        },
        select: { id: true },
      });
      if (cancelada) {
        throw new MatriculaValidationError(
          "Não é possível matricular aluno com matrícula cancelada nesta turma",
        );
      }
      throw new MatriculaValidationError(
        "Uma ou mais inscrições não pertencem à turma selecionada",
      );
    }
  }

  const matriculadosAtuais = inscricoes.filter(
    (i) => i.matriculado && !i.matriculaCancelada,
  );
  const idsMatriculadosAtuais = new Set(matriculadosAtuais.map((i) => i.id));
  const vagasDisponiveis = data.vagas - matriculadosAtuais.length;

  if (vagasDisponiveis <= 0) {
    throw new MatriculaVagasPreenchidasError(
      "A quantidade de vagas já está preenchida — não há vagas para novas matrículas",
    );
  }

  const idsParaMatricular = data.inscricaoIds.filter(
    (id) => !idsMatriculadosAtuais.has(id),
  );

  if (idsParaMatricular.length === 0) {
    throw new MatriculaValidationError(
      "Nenhum aluno novo selecionado para matrícula",
    );
  }

  if (idsParaMatricular.length > vagasDisponiveis) {
    throw new MatriculaValidationError(
      `Só há ${vagasDisponiveis} vaga(s) disponível(is) — selecionados para matricular: ${idsParaMatricular.length}`,
    );
  }

  const agora = new Date();

  await prisma.$transaction(async (tx) => {
    await tx.inscricaoAlunoCurso.updateMany({
      where: { id: { in: idsParaMatricular } },
      data: {
        matriculado: true,
        dtInicioCurso: dtInicio,
        usuarioMatriculaId: usuarioId,
        dataHoraMatricula: agora,
      },
    });
  });

  return listMatriculaCandidatos(data.turmaCodigo);
}

export class MatriculaValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MatriculaValidationError";
  }
}

export class MatriculaVagasPreenchidasError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MatriculaVagasPreenchidasError";
  }
}

export class MatriculaTurmaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MatriculaTurmaError";
  }
}
