import { z } from "zod";

const nomeSchema = z
  .string()
  .trim()
  .min(1, "Nome do bairro é obrigatório")
  .max(200, "Nome do bairro muito longo");

export const createBairroSchema = z.object({
  nome: nomeSchema,
});

export const updateBairroSchema = z
  .object({
    nome: nomeSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateBairroInput = z.infer<typeof createBairroSchema>;
export type UpdateBairroInput = z.infer<typeof updateBairroSchema>;
