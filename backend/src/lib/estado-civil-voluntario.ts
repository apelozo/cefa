import { EstadoCivilVoluntario } from "@prisma/client";

export const ESTADOS_CIVIS_VOLUNTARIO = [
  { valor: "CASADO" as const, rotulo: "Casado(a)" },
  { valor: "DIVORCIADO" as const, rotulo: "Divorciado(a)" },
  { valor: "SEPARADO" as const, rotulo: "Separado(a)" },
  { valor: "SOLTEIRO" as const, rotulo: "Solteiro(a)" },
  { valor: "VIUVO" as const, rotulo: "Viúvo(a)" },
] as const;

export const ESTADO_CIVIL_VOLUNTARIO_VALUES = ESTADOS_CIVIS_VOLUNTARIO.map(
  (e) => e.valor,
) as [EstadoCivilVoluntario, ...EstadoCivilVoluntario[]];

const porValor = new Map(ESTADOS_CIVIS_VOLUNTARIO.map((e) => [e.valor, e]));

export function rotuloEstadoCivilVoluntario(
  valor: EstadoCivilVoluntario,
): string {
  return porValor.get(valor)?.rotulo ?? valor;
}
