import { z } from "zod";
import { UFS_BRASIL } from "../lib/uf-brasil.js";

const estadoSchema = z.enum(UFS_BRASIL, {
  errorMap: () => ({ message: "Estado inválido" }),
});

const nomeMunicipioSchema = z
  .string()
  .trim()
  .min(1, "Nome do município é obrigatório")
  .max(200, "Nome do município muito longo");

export const createCidadeSchema = z.object({
  nomeMunicipio: nomeMunicipioSchema,
  estado: estadoSchema,
});

export const updateCidadeSchema = z
  .object({
    nomeMunicipio: nomeMunicipioSchema.optional(),
    estado: estadoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateCidadeInput = z.infer<typeof createCidadeSchema>;
export type UpdateCidadeInput = z.infer<typeof updateCidadeSchema>;
