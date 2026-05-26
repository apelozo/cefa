import { DiaSemana } from "@prisma/client";

export const DIAS_SEMANA = [
  { valor: "DOMINGO" as const, rotulo: "Domingo" },
  { valor: "SEGUNDA_FEIRA" as const, rotulo: "Segunda-feira" },
  { valor: "TERCA_FEIRA" as const, rotulo: "Terça-feira" },
  { valor: "QUARTA_FEIRA" as const, rotulo: "Quarta-feira" },
  { valor: "QUINTA_FEIRA" as const, rotulo: "Quinta-feira" },
  { valor: "SEXTA_FEIRA" as const, rotulo: "Sexta-feira" },
  { valor: "SABADO" as const, rotulo: "Sábado" },
] as const;

export const DIA_SEMANA_VALUES = DIAS_SEMANA.map((d) => d.valor) as [
  DiaSemana,
  ...DiaSemana[],
];

const porValor = new Map(DIAS_SEMANA.map((d) => [d.valor, d]));

export function rotuloDiaSemana(valor: DiaSemana): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
