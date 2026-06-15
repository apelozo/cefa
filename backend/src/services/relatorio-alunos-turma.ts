import type { Prisma } from "@prisma/client";

import { formatDataBr } from "../lib/campo.js";
import { formatCpf } from "../lib/cpf.js";
import { calcularIdade } from "../lib/idade.js";
import { rotuloPeriodoInscricao } from "../lib/periodo-inscricao.js";
import { prisma } from "../lib/prisma.js";
import { rotuloSituacaoTurma } from "../lib/situacao-turma.js";
import type { RelatorioAlunosTurmaQuery } from "../validators/relatorio-alunos-turma.js";

const inscricaoInclude = {
  aluno: {
    select: {
      nome: true,
      cpf: true,
      dtNascimento: true,
      escolaridade: { select: { descricao: true } },
    },
  },
  _count: { select: { atendimentos: true } },
} satisfies Prisma.InscricaoAlunoCursoInclude;

type InscricaoRow = Prisma.InscricaoAlunoCursoGetPayload<{
  include: typeof inscricaoInclude;
}>;

type SituacaoAlunoCodigo =
  | "MATRICULADO"
  | "MATRICULA_CANCELADA"
  | "A_MATRICULAR";

function codigoSituacaoAluno(row: {
  matriculado: boolean;
  matriculaCancelada: boolean;
}): SituacaoAlunoCodigo {
  if (row.matriculaCancelada) return "MATRICULA_CANCELADA";
  if (row.matriculado) return "MATRICULADO";
  return "A_MATRICULAR";
}

function rotuloSituacaoAluno(codigo: SituacaoAlunoCodigo): string {
  switch (codigo) {
    case "MATRICULADO":
      return "Matriculado";
    case "MATRICULA_CANCELADA":
      return "Matrícula cancelada";
    case "A_MATRICULAR":
      return "A matricular";
  }
}

function dataMatricula(row: InscricaoRow): string | null {
  if (row.dtInicioCurso != null) return formatDataBr(row.dtInicioCurso);
  if (row.dataHoraMatricula != null) return formatDataBr(row.dataHoraMatricula);
  return null;
}

function dataCancelamento(row: InscricaoRow): string | null {
  if (row.dataHoraCancelamentoMatricula == null) return null;
  return formatDataBr(row.dataHoraCancelamentoMatricula);
}

function dataUltSituacao(row: InscricaoRow): string {
  const codigo = codigoSituacaoAluno(row);
  if (codigo === "MATRICULA_CANCELADA") {
    return dataCancelamento(row) ?? formatDataBr(row.dtCurso);
  }
  if (codigo === "MATRICULADO") {
    return dataMatricula(row) ?? formatDataBr(row.dtCurso);
  }
  return formatDataBr(row.dtCurso);
}

function mapAluno(row: InscricaoRow) {
  const situacaoCodigo = codigoSituacaoAluno(row);
  return {
    inscricaoId: row.id,
    alunoNome: row.aluno.nome,
    alunoCpf: row.aluno.cpf,
    alunoCpfFormatado: row.aluno.cpf ? formatCpf(row.aluno.cpf) : null,
    alunoIdade:
      row.aluno.dtNascimento != null
        ? calcularIdade(row.aluno.dtNascimento)
        : null,
    escolaridadeDescricao: row.aluno.escolaridade?.descricao ?? null,
    dataInscricao: formatDataBr(row.dtCurso),
    dataMatricula: dataMatricula(row),
    dataCancelamento: dataCancelamento(row),
    situacao: rotuloSituacaoAluno(situacaoCodigo),
    situacaoCodigo,
    dataUltSituacao: dataUltSituacao(row),
    quantidadeAtendimentos: row._count.atendimentos,
  };
}

function contarPorSituacao(rows: InscricaoRow[]) {
  let matriculados = 0;
  let matriculasCanceladas = 0;
  let aMatricular = 0;
  for (const row of rows) {
    const codigo = codigoSituacaoAluno(row);
    if (codigo === "MATRICULADO") matriculados++;
    else if (codigo === "MATRICULA_CANCELADA") matriculasCanceladas++;
    else aMatricular++;
  }
  return { matriculados, matriculasCanceladas, aMatricular };
}

function filtrarPorSituacao(
  rows: InscricaoRow[],
  situacao: RelatorioAlunosTurmaQuery["situacao"],
) {
  if (situacao === "TODAS") return rows;
  return rows.filter((row) => codigoSituacaoAluno(row) === situacao);
}

async function listarTurmas(filtros: RelatorioAlunosTurmaQuery) {
  if (filtros.turmaCodigo != null) {
    const turma = await prisma.turma.findFirst({
      where: {
        codigo: filtros.turmaCodigo,
        ativo: true,
        ...(filtros.cursoCodigo != null
          ? { cursoCodigo: filtros.cursoCodigo }
          : {}),
      },
      include: {
        curso: { select: { codigo: true, descricao: true } },
      },
    });
    return turma ? [turma] : [];
  }

  return prisma.turma.findMany({
    where: {
      ativo: true,
      ...(filtros.cursoCodigo != null
        ? { cursoCodigo: filtros.cursoCodigo }
        : {}),
    },
    include: {
      curso: { select: { codigo: true, descricao: true } },
    },
    orderBy: [
      { curso: { descricao: "asc" } },
      { codigo: "asc" },
    ],
  });
}

export async function gerarRelatorioAlunosTurma(
  filtros: RelatorioAlunosTurmaQuery,
) {
  const turmas = await listarTurmas(filtros);

  if (filtros.turmaCodigo != null && turmas.length === 0) {
    throw new RelatorioAlunosTurmaError("Turma não encontrada para o curso informado");
  }

  const turmaCodigos = turmas.map((t) => t.codigo);
  const inscricoesPorTurma = new Map<number, InscricaoRow[]>();

  if (turmaCodigos.length > 0) {
    const todasInscricoes = await prisma.inscricaoAlunoCurso.findMany({
      where: {
        ativo: true,
        turmaCodigo: { in: turmaCodigos },
      },
      include: inscricaoInclude,
      orderBy: [{ aluno: { nome: "asc" } }, { codigo: "asc" }],
    });

    for (const row of todasInscricoes) {
      const lista = inscricoesPorTurma.get(row.turmaCodigo) ?? [];
      lista.push(row);
      inscricoesPorTurma.set(row.turmaCodigo, lista);
    }
  }

  const secoes = turmas.map((turma) => {
    const todas = inscricoesPorTurma.get(turma.codigo) ?? [];
    const filtradas = filtrarPorSituacao(todas, filtros.situacao);
    const resumo = contarPorSituacao(todas);

    return {
      cursoCodigo: turma.curso.codigo,
      cursoDescricao: turma.curso.descricao,
      turmaCodigo: turma.codigo,
      turmaNome: turma.nome,
      periodo: turma.periodo,
      periodoRotulo: rotuloPeriodoInscricao(turma.periodo),
      situacaoTurma: turma.situacao,
      situacaoTurmaRotulo: rotuloSituacaoTurma(turma.situacao),
      alunos: filtradas.map(mapAluno),
      resumo: {
        matriculados: resumo.matriculados,
        matriculasCanceladas: resumo.matriculasCanceladas,
        ...(turma.situacao === "ABERTA"
          ? { aMatricular: resumo.aMatricular }
          : {}),
      },
    };
  });

  return {
    filtros: {
      cursoCodigo: filtros.cursoCodigo ?? null,
      turmaCodigo: filtros.turmaCodigo ?? null,
      situacao: filtros.situacao,
      todosCursos: filtros.cursoCodigo == null,
      todasTurmas: filtros.turmaCodigo == null,
    },
    secoes,
    resumoGeral: secoes.map((s) => ({
      cursoCodigo: s.cursoCodigo,
      cursoDescricao: s.cursoDescricao,
      turmaCodigo: s.turmaCodigo,
      turmaNome: s.turmaNome,
      periodoRotulo: s.periodoRotulo,
      situacaoTurma: s.situacaoTurma,
      situacaoTurmaRotulo: s.situacaoTurmaRotulo,
      matriculados: s.resumo.matriculados,
      matriculasCanceladas: s.resumo.matriculasCanceladas,
      ...(s.situacaoTurma === "ABERTA"
        ? { aMatricular: s.resumo.aMatricular ?? 0 }
        : {}),
    })),
  };
}

export class RelatorioAlunosTurmaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RelatorioAlunosTurmaError";
  }
}
