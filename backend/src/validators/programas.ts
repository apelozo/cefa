import { z } from "zod";

const codigoPrograma = z
  .string()
  .min(1, "Código é obrigatório")
  .max(64)
  .regex(
    /^[a-z][a-z0-9_]*$/,
    "Código: letras minúsculas, números e underscore (ex.: meu_programa)",
  );

export const createProgramaSchema = z.object({
  codigo: codigoPrograma,
  nome: z.string().min(1, "Nome é obrigatório").max(120),
  autoListagem: z.boolean().optional().default(false),
  moduloSistemaId: z.string().uuid().nullable().optional(),
  relatorioSubmoduloId: z.string().uuid().nullable().optional(),
});

export const updateProgramaSchema = z.object({
  nome: z.string().min(1).max(120).optional(),
  autoListagem: z.boolean().optional(),
  moduloSistemaId: z.string().uuid().nullable().optional(),
  relatorioSubmoduloId: z.string().uuid().nullable().optional(),
});

export type CreateProgramaInput = z.infer<typeof createProgramaSchema>;
export type UpdateProgramaInput = z.infer<typeof updateProgramaSchema>;
