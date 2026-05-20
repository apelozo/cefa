import { TipoCampo } from "@prisma/client";
import { Prisma } from "@prisma/client";

export const MAX_INTEIRO = 999_999_999;
export const MIN_INTEIRO = -999_999_999;
export const MAX_TAMANHO_TEXTO = 5000;
export const MAX_LINHAS_CAMPO = 20;
export const MIN_LINHAS_CAMPO = 1;
export const DEFAULT_LINHAS_CAMPO = 3;

export type ValoresResposta = {
  valorInteiro?: number;
  valorDecimal?: string | number;
  valorTexto?: string;
  valorLogico?: boolean;
  valorData?: string;
  valorOpcaoId?: string;
};

export function isRespostaVazia(v: ValoresResposta): boolean {
  return countValoresPreenchidos(v) === 0;
}

export function countValoresPreenchidos(v: ValoresResposta): number {
  let n = 0;
  if (v.valorInteiro !== undefined) n++;
  if (v.valorDecimal !== undefined && v.valorDecimal !== "") n++;
  if (v.valorTexto !== undefined && v.valorTexto !== "") n++;
  if (v.valorLogico !== undefined) n++;
  if (v.valorData !== undefined && v.valorData !== "") n++;
  if (v.valorOpcaoId !== undefined && v.valorOpcaoId !== "") n++;
  return n;
}

export function parseDataBr(input: string): Date {
  const trimmed = input.trim();
  const match = /^(\d{2})\/(\d{2})\/(\d{2}|\d{4})$/.exec(trimmed);
  if (!match) {
    throw new Error("Data inválida. Use o formato dd/mm/aa ou dd/mm/aaaa");
  }

  const day = Number(match[1]);
  const month = Number(match[2]);
  let year = Number(match[3]);
  if (year < 100) year += 2000;

  // UTC evita deslocar um dia ao gravar/ler @db.Date (PostgreSQL).
  const date = new Date(Date.UTC(year, month - 1, day));
  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new Error("Data inválida");
  }
  return date;
}

export function formatDataBr(date: Date): string {
  const d = String(date.getUTCDate()).padStart(2, "0");
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const y = date.getUTCFullYear();
  return `${d}/${m}/${y}`;
}

export function validateValorForTipo(
  tipo: TipoCampo,
  tamanhoCampo: number | null,
  valores: ValoresResposta,
): {
  valorInteiro: number | null;
  valorDecimal: Prisma.Decimal | null;
  valorTexto: string | null;
  valorLogico: boolean | null;
  valorData: Date | null;
  valorOpcaoId: string | null;
} {
  const filled = countValoresPreenchidos(valores);
  if (filled !== 1) {
    throw new Error("Informe exatamente um valor por pergunta");
  }

  switch (tipo) {
    case TipoCampo.INTEIRO: {
      if (valores.valorInteiro === undefined) {
        throw new Error("valorInteiro é obrigatório");
      }
      if (!Number.isInteger(valores.valorInteiro)) {
        throw new Error("valorInteiro deve ser um número inteiro");
      }
      if (
        valores.valorInteiro < MIN_INTEIRO ||
        valores.valorInteiro > MAX_INTEIRO
      ) {
        throw new Error("valorInteiro deve ter no máximo 9 dígitos");
      }
      return {
        valorInteiro: valores.valorInteiro,
        valorDecimal: null,
        valorTexto: null,
        valorLogico: null,
        valorData: null,
        valorOpcaoId: null,
      };
    }
    case TipoCampo.DECIMAL: {
      if (valores.valorDecimal === undefined || valores.valorDecimal === "") {
        throw new Error("valorDecimal é obrigatório");
      }
      const str = String(valores.valorDecimal).replace(",", ".");
      if (!/^-?\d+(\.\d+)?$/.test(str)) {
        throw new Error("valorDecimal inválido");
      }
      return {
        valorInteiro: null,
        valorDecimal: new Prisma.Decimal(str),
        valorTexto: null,
        valorLogico: null,
        valorData: null,
        valorOpcaoId: null,
      };
    }
    case TipoCampo.TEXTO: {
      if (!tamanhoCampo || tamanhoCampo < 1) {
        throw new Error("Pergunta de texto sem tamanho configurado");
      }
      if (valores.valorTexto === undefined || valores.valorTexto.trim() === "") {
        throw new Error("valorTexto é obrigatório");
      }
      const text = valores.valorTexto.trim();
      if (text.length > tamanhoCampo) {
        throw new Error(`valorTexto deve ter no máximo ${tamanhoCampo} caracteres`);
      }
      return {
        valorInteiro: null,
        valorDecimal: null,
        valorTexto: text,
        valorLogico: null,
        valorData: null,
        valorOpcaoId: null,
      };
    }
    case TipoCampo.LOGICO: {
      if (valores.valorLogico === undefined) {
        throw new Error("valorLogico é obrigatório");
      }
      return {
        valorInteiro: null,
        valorDecimal: null,
        valorTexto: null,
        valorLogico: valores.valorLogico,
        valorData: null,
        valorOpcaoId: null,
      };
    }
    case TipoCampo.DATA: {
      if (valores.valorData === undefined || valores.valorData.trim() === "") {
        throw new Error("valorData é obrigatório");
      }
      return {
        valorInteiro: null,
        valorDecimal: null,
        valorTexto: null,
        valorLogico: null,
        valorData: parseDataBr(valores.valorData),
        valorOpcaoId: null,
      };
    }
    case TipoCampo.LISTA: {
      if (valores.valorOpcaoId === undefined || valores.valorOpcaoId.trim() === "") {
        throw new Error("valorOpcaoId é obrigatório");
      }
      return {
        valorInteiro: null,
        valorDecimal: null,
        valorTexto: null,
        valorLogico: null,
        valorData: null,
        valorOpcaoId: valores.valorOpcaoId.trim(),
      };
    }
    default:
      throw new Error("Tipo de campo desconhecido");
  }
}
