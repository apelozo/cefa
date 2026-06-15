import type { SituacaoTurma } from "@prisma/client";

export const SITUACOES_TURMA = [
  { valor: "ABERTA" as const, rotulo: "Aberta" },
  { valor: "FECHADA" as const, rotulo: "Fechada" },
] as const;

export const SITUACAO_TURMA_VALUES = SITUACOES_TURMA.map(
  (s) => s.valor,
) as [SituacaoTurma, ...SituacaoTurma[]];

const porValor = new Map(SITUACOES_TURMA.map((s) => [s.valor, s]));

export function rotuloSituacaoTurma(valor: SituacaoTurma): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
