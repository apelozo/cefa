import { z } from "zod";

export const listCancelamentoMatriculaQuerySchema = z.object({
  turmaCodigo: z.coerce
    .number()
    .int()
    .positive("Turma é obrigatória"),
});

export const gravarCancelamentoMatriculaSchema = z.object({
  turmaCodigo: z.number().int().positive("Turma é obrigatória"),
  inscricaoIds: z
    .array(z.string().uuid())
    .min(1, "Selecione ao menos uma inscrição para cancelar"),
});

export type GravarCancelamentoMatriculaInput = z.infer<
  typeof gravarCancelamentoMatriculaSchema
>;
