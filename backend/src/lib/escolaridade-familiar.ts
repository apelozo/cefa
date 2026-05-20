import { EscolaridadeFamiliar } from "@prisma/client";

export type EscolaridadeFamiliarDef = {
  valor: EscolaridadeFamiliar;
  rotulo: string;
};

export const ESCOLARIDADES_FAMILIAR: EscolaridadeFamiliarDef[] = [
  { valor: "NUNCA_FREQUENTOU_ESCOLA", rotulo: "Nunca Frequentou Escola" },
  { valor: "CRECHE", rotulo: "Creche" },
  { valor: "EDUCACAO_INFANTIL", rotulo: "Educação Infantil" },
  { valor: "EF_1_ANO", rotulo: "1º Ano Ens. Fund." },
  { valor: "EF_2_ANO", rotulo: "2º Ano Ens. Fund." },
  { valor: "EF_3_ANO", rotulo: "3º Ano Ens. Fund." },
  { valor: "EF_4_ANO", rotulo: "4º Ano Ens. Fund." },
  { valor: "EF_5_ANO", rotulo: "5º Ano Ens. Fund." },
  { valor: "EF_6_ANO", rotulo: "6º Ano Ens. Fund." },
  { valor: "EF_7_ANO", rotulo: "7º Ano Ens. Fund." },
  { valor: "EF_8_ANO", rotulo: "8º Ano Ens. Fund." },
  { valor: "EF_9_ANO", rotulo: "9º Ano Ens. Fund." },
  { valor: "EM_1_ANO", rotulo: "1º Ano Ens. Médio" },
  { valor: "EM_2_ANO", rotulo: "2º Ano Ens. Médio" },
  { valor: "EM_3_ANO", rotulo: "3º Ano Ens. Médio" },
  { valor: "SUPERIOR_INCOMPLETO", rotulo: "Superior Incompleto" },
  { valor: "SUPERIOR_COMPLETO", rotulo: "Superior Completo" },
  { valor: "EJA_EF", rotulo: "EJA - Ens. Fundamental" },
  { valor: "EJA_EM", rotulo: "EJA - Ens. Médio" },
  { valor: "OUTROS", rotulo: "Outros" },
];

const porValor = new Map(ESCOLARIDADES_FAMILIAR.map((e) => [e.valor, e]));

export function rotuloEscolaridadeFamiliar(valor: EscolaridadeFamiliar): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
