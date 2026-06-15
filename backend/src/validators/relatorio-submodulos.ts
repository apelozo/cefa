import { z } from "zod";

const codigoSubmodulo = z
  .string()
  .trim()
  .min(1, "Código é obrigatório")
  .max(64)
  .regex(
    /^[a-z][a-z0-9_]*$/,
    "Código: letras minúsculas, números e underscore (ex.: iefa)",
  );

const nomeSchema = z
  .string()
  .trim()
  .min(1, "Nome é obrigatório")
  .max(120, "Nome muito longo");

const descricaoSchema = z
  .string()
  .trim()
  .max(500, "Descrição muito longa")
  .optional()
  .nullable();

export const createRelatorioSubmoduloSchema = z.object({
  codigo: codigoSubmodulo,
  nome: nomeSchema,
  descricao: descricaoSchema,
  ordem: z.number().int().min(0).max(9999).optional().default(0),
  ativo: z.boolean().optional().default(true),
});

export const updateRelatorioSubmoduloSchema = z
  .object({
    nome: nomeSchema.optional(),
    descricao: descricaoSchema,
    ordem: z.number().int().min(0).max(9999).optional(),
    ativo: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateRelatorioSubmoduloInput = z.infer<
  typeof createRelatorioSubmoduloSchema
>;
export type UpdateRelatorioSubmoduloInput = z.infer<
  typeof updateRelatorioSubmoduloSchema
>;
