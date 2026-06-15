import { z } from "zod";

import { parseDtCurso } from "./inscricoes.js";

const dtInicioCursoSchema = z
  .string()
  .min(1, "Data de início do curso é obrigatória")
  .refine((v) => parseDtCurso(v) != null, "Data de início inválida");

export const listMatriculaCandidatosQuerySchema = z.object({
  turmaCodigo: z.coerce
    .number()
    .int()
    .positive("Turma é obrigatória"),
});

export const gravarMatriculaSchema = z.object({
  turmaCodigo: z.number().int().positive("Turma é obrigatória"),
  dtInicioCurso: dtInicioCursoSchema,
  vagas: z
    .number()
    .int()
    .positive("Informe a quantidade de vagas (mínimo 1)"),
  inscricaoIds: z.array(z.string().uuid()).default([]),
});

export type GravarMatriculaInput = z.infer<typeof gravarMatriculaSchema>;
