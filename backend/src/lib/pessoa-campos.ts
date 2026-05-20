import { UrbanoRural } from "@prisma/client";

export const URBANO_RURAL_VALUES = ["URBANO", "RURAL"] as const;

export type UrbanoRuralInput = (typeof URBANO_RURAL_VALUES)[number];

export function emptyToNull(value: string | undefined | null): string | null {
  if (value === undefined || value === null) return null;
  const t = value.trim();
  return t.length === 0 ? null : t;
}

export function normalizeTelefone(value: string): string {
  return value.replace(/\D/g, "");
}

export function normalizeNis(value: string): string {
  return value.replace(/\D/g, "");
}

export function normalizeCodigoRef(value: string): string {
  return value.trim().toUpperCase();
}

export function isUrbanoRural(value: string): value is UrbanoRural {
  return value === "URBANO" || value === "RURAL";
}

export function parseUrbanoRural(
  value: string | null | undefined,
): UrbanoRural | null {
  if (!value) return null;
  if (isUrbanoRural(value)) return value as UrbanoRural;
  return null;
}

/** Converte valor monetário (1234,56 ou 1234.56) para número. */
export function parseMoedaBr(value: string | number): number {
  if (typeof value === "number") {
    if (!Number.isFinite(value) || value < 0) {
      throw new Error("Valor monetário inválido");
    }
    return value;
  }
  const trimmed = value.trim();
  if (!trimmed) return 0;
  const normalized = trimmed.replace(/\./g, "").replace(",", ".");
  const n = Number(normalized);
  if (!Number.isFinite(n) || n < 0) {
    throw new Error("Valor monetário inválido");
  }
  return n;
}
