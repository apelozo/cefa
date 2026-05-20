import { UfBrasil } from "@prisma/client";

export const UFS_BRASIL = [
  "AC",
  "AL",
  "AP",
  "AM",
  "BA",
  "CE",
  "DF",
  "ES",
  "GO",
  "MA",
  "MT",
  "MS",
  "MG",
  "PA",
  "PB",
  "PR",
  "PE",
  "PI",
  "RJ",
  "RN",
  "RS",
  "RO",
  "RR",
  "SC",
  "SP",
  "SE",
  "TO",
] as const satisfies readonly UfBrasil[];

export type UfBrasilCodigo = (typeof UFS_BRASIL)[number];

export function isUfBrasil(value: string): value is UfBrasilCodigo {
  return (UFS_BRASIL as readonly string[]).includes(value);
}
