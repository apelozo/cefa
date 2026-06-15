import { z } from "zod";

export const SITUACAO_RELATORIO_ALUNOS_VALUES = [
  "MATRICULADO",
  "MATRICULA_CANCELADA",
  "A_MATRICULAR",
  "TODAS",
] as const;

export const relatorioAlunosTurmaQuerySchema = z
  .object({
    cursoCodigo: z.coerce.number().int().positive().optional(),
    turmaCodigo: z.coerce.number().int().positive().optional(),
    situacao: z
      .enum(SITUACAO_RELATORIO_ALUNOS_VALUES)
      .optional()
      .default("TODAS"),
  })
  .refine((data) => !data.turmaCodigo || data.cursoCodigo != null, {
    message: "Selecione um curso antes de filtrar por turma",
    path: ["turmaCodigo"],
  });

export type RelatorioAlunosTurmaQuery = z.infer<
  typeof relatorioAlunosTurmaQuerySchema
>;
