import { TipoCasaAlunoCapacitacao } from "@prisma/client";

export const TIPOS_CASA_ALUNO_CAPACITACAO = [
  { valor: "PROPRIA" as const, rotulo: "Própria" },
  { valor: "CEDIDA" as const, rotulo: "Cedida" },
  { valor: "ALUGUEL" as const, rotulo: "Aluguel" },
] as const;

export const TIPO_CASA_ALUNO_CAPACITACAO_VALUES =
  TIPOS_CASA_ALUNO_CAPACITACAO.map((e) => e.valor) as [
    TipoCasaAlunoCapacitacao,
    ...TipoCasaAlunoCapacitacao[],
  ];

const porValor = new Map(TIPOS_CASA_ALUNO_CAPACITACAO.map((e) => [e.valor, e]));

export function rotuloTipoCasaAlunoCapacitacao(
  valor: TipoCasaAlunoCapacitacao,
): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
