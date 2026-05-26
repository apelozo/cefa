import { z } from "zod";

const descricaoSchema = z
  .string()
  .trim()
  .min(1, "Descrição é obrigatória")
  .max(200, "Descrição muito longa");

export const createDepartamentoSchema = z.object({
  descricao: descricaoSchema,
});

export const updateDepartamentoSchema = z
  .object({
    descricao: descricaoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateDepartamentoInput = z.infer<typeof createDepartamentoSchema>;
export type UpdateDepartamentoInput = z.infer<typeof updateDepartamentoSchema>;
