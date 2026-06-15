import type { PeriodoInscricao } from "@prisma/client";

export const PERIODOS_INSCRICAO = [
  { valor: "MANHA" as const, rotulo: "Manhã" },
  { valor: "TARDE" as const, rotulo: "Tarde" },
  { valor: "NOITE" as const, rotulo: "Noite" },
] as const;

export const PERIODO_INSCRICAO_VALUES = PERIODOS_INSCRICAO.map(
  (p) => p.valor,
) as [PeriodoInscricao, ...PeriodoInscricao[]];

const porValor = new Map(PERIODOS_INSCRICAO.map((p) => [p.valor, p]));

export function rotuloPeriodoInscricao(valor: PeriodoInscricao): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
