import { z } from "zod";

const descricaoSchema = z
  .string()
  .trim()
  .min(1, "Descrição é obrigatória")
  .max(200, "Descrição muito longa");

export const createEscolaridadeSchema = z.object({
  descricao: descricaoSchema,
});

export const updateEscolaridadeSchema = z
  .object({
    descricao: descricaoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateEscolaridadeInput = z.infer<typeof createEscolaridadeSchema>;
export type UpdateEscolaridadeInput = z.infer<typeof updateEscolaridadeSchema>;
