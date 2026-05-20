import { z } from "zod";

const codigoSchema = z.coerce
  .number({ invalid_type_error: "Código deve ser um número inteiro" })
  .int("Código deve ser um número inteiro")
  .positive("Código deve ser maior que zero")
  .max(999999, "Código muito grande");

export const createModuloSistemaSchema = z.object({
  codigo: codigoSchema,
  nome: z.string().trim().min(1).max(200),
  descricao: z.string().trim().max(500).optional(),
  ordem: z.number().int().min(0).optional().default(0),
  ativo: z.boolean().optional().default(true),
});

const descricaoUpdateSchema = z.preprocess(
  (val) => (val === "" || val === undefined ? null : val),
  z.string().trim().max(500).nullable().optional(),
);

export const updateModuloSistemaSchema = z
  .object({
    nome: z.string().trim().min(1).max(200).optional(),
    descricao: descricaoUpdateSchema,
    ordem: z.number().int().min(0).optional(),
    ativo: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export const modulosProgramasBodySchema = z.object({
  programaIds: z.array(z.string().uuid()),
});

export type CreateModuloSistemaInput = z.infer<typeof createModuloSistemaSchema>;
export type UpdateModuloSistemaInput = z.infer<typeof updateModuloSistemaSchema>;
export type ModulosProgramasBodyInput = z.infer<typeof modulosProgramasBodySchema>;
