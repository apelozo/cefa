import { TipoDeficienciaFamiliar } from "@prisma/client";

export type TipoDeficienciaFamiliarDef = {
  valor: TipoDeficienciaFamiliar;
  rotulo: string;
};

export const TIPOS_DEFICIENCIA_FAMILIAR: TipoDeficienciaFamiliarDef[] = [
  { valor: "CEGUEIRA", rotulo: "Cegueira" },
  { valor: "BAIXA_VISAO", rotulo: "Baixa Visão" },
  { valor: "SURDEZ_LEVE_MODERADA", rotulo: "Surdez leve/moderada" },
  { valor: "DEFICIENCIA_FISICA", rotulo: "Deficiencia Fisica" },
  {
    valor: "DEFICIENCIA_MENTAL_INTELECTUAL",
    rotulo: "Deficiencia Mental ou Intelectual",
  },
  { valor: "SINDROME_DOWN", rotulo: "Sindrome de Down" },
  { valor: "TRANSTORNO_MENTAL", rotulo: "Transtorno Mental" },
];

const porValor = new Map(TIPOS_DEFICIENCIA_FAMILIAR.map((t) => [t.valor, t]));

export function rotuloTipoDeficienciaFamiliar(
  valor: TipoDeficienciaFamiliar,
): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
