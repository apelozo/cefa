import { z } from "zod";

export const createTipoFormularioSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  descricao: z.string().trim().optional(),
  ativo: z.boolean().optional().default(true),
});

const descricaoUpdateSchema = z.preprocess(
  (val) => (val === "" || val === undefined ? null : val),
  z.string().trim().nullable().optional(),
);

export const updateTipoFormularioSchema = z
  .object({
    nome: z.string().trim().min(1).optional(),
    descricao: descricaoUpdateSchema,
    ativo: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateTipoFormularioInput = z.infer<typeof createTipoFormularioSchema>;
export type UpdateTipoFormularioInput = z.infer<typeof updateTipoFormularioSchema>;
