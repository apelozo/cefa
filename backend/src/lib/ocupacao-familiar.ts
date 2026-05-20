import { OcupacaoFamiliar } from "@prisma/client";

export type OcupacaoFamiliarDef = {
  codigo: number;
  valor: OcupacaoFamiliar;
  rotulo: string;
};

export const OCUPACOES_FAMILIAR: OcupacaoFamiliarDef[] = [
  { codigo: 0, valor: "NAO_TRABALHA", rotulo: "0 - Não Trabalha" },
  {
    codigo: 1,
    valor: "CONTA_PROPRIA",
    rotulo: "1 - Trabalhador por conta própria (bico, autônomo)",
  },
  {
    codigo: 2,
    valor: "TEMPORARIO_RURAL",
    rotulo: "2 - Trabalhador Temporário em área rural",
  },
  {
    codigo: 3,
    valor: "EMPREGADO_SEM_CARTEIRA",
    rotulo: "3 - Empregado sem carteira de trabalho assinada",
  },
  {
    codigo: 4,
    valor: "EMPREGADO_COM_CARTEIRA",
    rotulo: "4 - Empregado com carteira de trabalho assinada",
  },
  {
    codigo: 5,
    valor: "DOMESTICO_SEM_CARTEIRA",
    rotulo: "5 - Trabalhador doméstico sem carteira e trabalho assinada",
  },
  {
    codigo: 6,
    valor: "DOMESTICO_COM_CARTEIRA",
    rotulo: "6 - Trabalhador doméstico com carteira de trabalho assinada",
  },
  {
    codigo: 7,
    valor: "NAO_REMUNERADO",
    rotulo: "7 - Trabalhador não remunerado",
  },
  {
    codigo: 8,
    valor: "MILITAR_SERVIDOR_PUBLICO",
    rotulo: "8 - Militar ou Servidor Público",
  },
  { codigo: 9, valor: "EMPREGADOR", rotulo: "9 - Empregador" },
  { codigo: 10, valor: "ESTAGIARIO", rotulo: "10 - Estagiário" },
  { codigo: 11, valor: "APRENDIZ", rotulo: "11 - Aprendiz" },
];

const porValor = new Map(OCUPACOES_FAMILIAR.map((o) => [o.valor, o]));

export function rotuloOcupacaoFamiliar(valor: OcupacaoFamiliar): string {
  return porValor.get(valor)?.rotulo ?? valor;
}

export function codigoOcupacaoFamiliar(valor: OcupacaoFamiliar): number {
  return porValor.get(valor)?.codigo ?? -1;
}
