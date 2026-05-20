import { z } from "zod";
import { FORMAS_ACESSO_INSTITUICAO } from "../lib/entrevista-assistido.js";
import {
  composicaoFamiliarItemSchema,
  condicaoEducacionalItemSchema,
  condicaoTrabalhoItemSchema,
  deficienciaFamiliarItemSchema,
  gestanteFamiliarItemSchema,
  programasSociaisSchema,
  saudeFamiliaSchema,
} from "./familia-entrevista.js";

const formaAcessoSchema = z.enum(FORMAS_ACESSO_INSTITUICAO);

export const createEntrevistaAssistidoSchema = z
  .object({
    pessoaId: z.string().uuid(),
    dataEntrevista: z.string().min(1),
    formasAcesso: z.array(formaAcessoSchema).min(1),
    outrosTexto: z.string().max(500).optional().nullable(),
    composicaoFamiliar: z.array(composicaoFamiliarItemSchema).optional().default([]),
    condicoesTrabalho: z.array(condicaoTrabalhoItemSchema).optional().default([]),
    condicoesEducacionais: z
      .array(condicaoEducacionalItemSchema)
      .optional()
      .default([]),
    deficienciasFamilia: z
      .array(deficienciaFamiliarItemSchema)
      .optional()
      .default([]),
    gestantesFamilia: z
      .array(gestanteFamiliarItemSchema)
      .optional()
      .default([]),
    programasSociais: programasSociaisSchema,
    saudeFamilia: saudeFamiliaSchema,
  })
  .superRefine((data, ctx) => {
    const unique = new Set(data.formasAcesso);
    if (unique.size !== data.formasAcesso.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Formas de acesso duplicadas",
        path: ["formasAcesso"],
      });
    }
    const temOutros = data.formasAcesso.includes("OUTROS");
    const texto = data.outrosTexto?.trim() ?? "";
    if (temOutros && texto.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Informe a descrição quando selecionar Outros",
        path: ["outrosTexto"],
      });
    }
    if (!temOutros && texto.length > 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Descrição de Outros só é permitida quando a opção Outros estiver marcada",
        path: ["outrosTexto"],
      });
    }

    const temGestante = data.saudeFamilia?.temGestante;
    const gestantes = data.gestantesFamilia ?? [];
    if (temGestante === "SIM") {
      if (gestantes.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Informe ao menos uma gestante na família",
          path: ["gestantesFamilia"],
        });
      }
    } else if (gestantes.length > 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          "Registros de gestante só são permitidos quando a resposta for Sim em gestante na família",
        path: ["gestantesFamilia"],
      });
    }
  });

export type CreateEntrevistaAssistidoInput = z.infer<
  typeof createEntrevistaAssistidoSchema
>;

export const updateEntrevistaAssistidoSchema = createEntrevistaAssistidoSchema;

export type UpdateEntrevistaAssistidoInput = z.infer<
  typeof updateEntrevistaAssistidoSchema
>;

export const listEntrevistasAssistidoQuerySchema = z.object({
  pessoaId: z.string().uuid().optional(),
  nome: z.string().optional(),
  cpf: z.string().optional(),
});

export type ListEntrevistasAssistidoQuery = z.infer<
  typeof listEntrevistasAssistidoQuerySchema
>;
