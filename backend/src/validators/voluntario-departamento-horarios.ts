import { z } from "zod";
import { DIA_SEMANA_VALUES } from "../lib/dia-semana.js";
import {
  parseHora,
  validarIntervaloHorario,
} from "../lib/hora.js";

const diaSemanaSchema = z.enum(DIA_SEMANA_VALUES, {
  errorMap: () => ({ message: "Dia da semana inválido" }),
});

const horaSchema = z
  .string()
  .trim()
  .min(1, "Hora é obrigatória")
  .transform((v, ctx) => {
    try {
      return parseHora(v);
    } catch (err) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: err instanceof Error ? err.message : "Hora inválida",
      });
      return z.NEVER;
    }
  });

const departamentoCodigoSchema = z
  .number({ invalid_type_error: "Código do departamento inválido" })
  .int("Código do departamento inválido")
  .positive("Código do departamento inválido");

const horarioFieldsSchema = z.object({
  departamentoCodigo: departamentoCodigoSchema,
  diaSemana: diaSemanaSchema,
  horaInicio: horaSchema,
  horaTermino: horaSchema,
});

function refineIntervaloHorario<T extends { horaInicio?: Date; horaTermino?: Date }>(
  data: T,
  ctx: z.RefinementCtx,
  requireBoth = true,
) {
  if (!data.horaInicio || !data.horaTermino) {
    if (requireBoth) return;
    return;
  }
  try {
    validarIntervaloHorario(data.horaInicio, data.horaTermino);
  } catch (err) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message:
        err instanceof Error ? err.message : "Intervalo de horário inválido",
      path: ["horaTermino"],
    });
  }
}

export const createVoluntarioDepartamentoHorarioSchema = horarioFieldsSchema.superRefine(
  (data, ctx) => refineIntervaloHorario(data, ctx, true),
);

export const updateVoluntarioDepartamentoHorarioSchema = horarioFieldsSchema
  .partial()
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  })
  .superRefine((data, ctx) => refineIntervaloHorario(data, ctx, false));

export type CreateVoluntarioDepartamentoHorarioInput = z.infer<
  typeof createVoluntarioDepartamentoHorarioSchema
>;
export type UpdateVoluntarioDepartamentoHorarioInput = z.infer<
  typeof updateVoluntarioDepartamentoHorarioSchema
>;
