import { z } from "zod";

import { parseDtCurso } from "./inscricoes.js";

const dataAtendimentoSchema = z
  .string()
  .min(1, "Data do atendimento é obrigatória")
  .refine((v) => parseDtCurso(v) != null, "Data do atendimento inválida");

export const listInscricaoAtendimentosQuerySchema = z
  .object({
    inscricaoId: z.string().uuid().optional(),
    turmaCodigo: z.coerce.number().int().positive().optional(),
    alunoId: z.string().uuid().optional(),
  })
  .refine(
    (q) =>
      q.inscricaoId != null ||
      (q.turmaCodigo != null && q.alunoId != null),
    {
      message:
        "Informe inscricaoId ou turmaCodigo com alunoId para listar atendimentos",
    },
  );

export const listAlunosMatriculadosQuerySchema = z.object({
  turmaCodigo: z.coerce
    .number()
    .int()
    .positive("Turma é obrigatória"),
  nome: z.string().optional(),
  cpf: z.string().optional(),
});

const descricaoSchema = z
  .string()
  .trim()
  .min(1, "Descrição do atendimento é obrigatória")
  .max(2000, "Descrição deve ter no máximo 2000 caracteres");

export const createInscricaoAtendimentoSchema = z
  .object({
    inscricaoId: z.string().uuid().optional(),
    turmaCodigo: z.number().int().positive().optional(),
    alunoId: z.string().uuid().optional(),
    dataAtendimento: dataAtendimentoSchema,
    descricao: descricaoSchema,
  })
  .refine(
    (b) =>
      b.inscricaoId != null || (b.turmaCodigo != null && b.alunoId != null),
    {
      message:
        "Informe inscricaoId ou turmaCodigo com alunoId para registrar atendimento",
    },
  );

export const updateInscricaoAtendimentoSchema = z.object({
  dataAtendimento: dataAtendimentoSchema,
  descricao: descricaoSchema,
});

export type CreateInscricaoAtendimentoInput = z.infer<
  typeof createInscricaoAtendimentoSchema
>;
export type UpdateInscricaoAtendimentoInput = z.infer<
  typeof updateInscricaoAtendimentoSchema
>;
