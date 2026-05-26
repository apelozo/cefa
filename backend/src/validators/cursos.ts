import { z } from "zod";

const descricaoSchema = z
  .string()
  .trim()
  .min(1, "Descrição é obrigatória")
  .max(200, "Descrição muito longa");

export const createCursoSchema = z.object({
  descricao: descricaoSchema,
});

export const updateCursoSchema = z
  .object({
    descricao: descricaoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateCursoInput = z.infer<typeof createCursoSchema>;
export type UpdateCursoInput = z.infer<typeof updateCursoSchema>;
