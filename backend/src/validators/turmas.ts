import { z } from "zod";
import { PERIODO_INSCRICAO_VALUES } from "../lib/periodo-inscricao.js";
import { SITUACAO_TURMA_VALUES } from "../lib/situacao-turma.js";

const nomeSchema = z
  .string()
  .trim()
  .min(1, "Nome da turma é obrigatório")
  .max(200, "Nome da turma muito longo");

const cursoCodigoSchema = z
  .number({ invalid_type_error: "Curso inválido" })
  .int("Curso inválido")
  .positive("Curso inválido");

const periodoSchema = z.enum(PERIODO_INSCRICAO_VALUES, {
  errorMap: () => ({ message: "Período inválido" }),
});

const situacaoSchema = z.enum(SITUACAO_TURMA_VALUES, {
  errorMap: () => ({ message: "Situação inválida" }),
});

export const createTurmaSchema = z.object({
  nome: nomeSchema,
  cursoCodigo: cursoCodigoSchema,
  periodo: periodoSchema,
  situacao: situacaoSchema.optional().default("ABERTA"),
});

export const updateTurmaSchema = z
  .object({
    nome: nomeSchema.optional(),
    cursoCodigo: cursoCodigoSchema.optional(),
    periodo: periodoSchema.optional(),
    situacao: situacaoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateTurmaInput = z.infer<typeof createTurmaSchema>;
export type UpdateTurmaInput = z.infer<typeof updateTurmaSchema>;
