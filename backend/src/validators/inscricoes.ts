import { z } from "zod";

import { parseDataBr } from "../lib/campo.js";

import { emptyToNull, normalizeTelefone, parseMoedaBr } from "../lib/pessoa-campos.js";



const textoOpcional = (max: number, label: string) =>

  z

    .string()

    .max(max, `${label} muito longo`)

    .optional()

    .nullable()

    .transform((v) => emptyToNull(v ?? undefined));



const dataBrObrigatoriaSchema = (label: string) =>

  z

    .string()

    .trim()

    .min(1, `${label} é obrigatória`)

    .refine(

      (val) => {

        try {

          parseDataBr(val);

          return true;

        } catch {

          return false;

        }

      },

      { message: "Data inválida. Use o formato dd/mm/aa ou dd/mm/aaaa" },

    );



const moedaSchema = z

  .union([z.number(), z.string()])

  .optional()

  .nullable()

  .transform((v, ctx) => {

    if (v === undefined || v === null || v === "") return 0;

    try {

      return parseMoedaBr(v);

    } catch {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "Valor monetário inválido",

      });

      return z.NEVER;

    }

  });



const telefoneOpcional = z

  .string()

  .optional()

  .nullable()

  .transform((v) => {

    const n = emptyToNull(v ?? undefined);

    if (!n) return null;

    const digits = normalizeTelefone(n);

    return digits.length > 0 ? digits : null;

  })

  .refine((v) => v === null || (v.length >= 10 && v.length <= 11), {

    message: "Telefone inválido",

  });



export const rendaFamiliarItemSchema = z.object({

  nome: z.string().trim().min(1, "Nome é obrigatório").max(200),

  idade: z

    .number({ invalid_type_error: "Idade inválida" })

    .int("Idade inválida")

    .min(0, "Idade inválida")

    .max(150, "Idade inválida")

    .optional()

    .nullable(),

  renda: moedaSchema,

  parentesco: textoOpcional(100, "Parentesco"),

  profissao: textoOpcional(100, "Profissão"),

});



const camposInscricaoSchema = z.object({

  alunoId: z.string().uuid("Aluno inválido"),

  turmaCodigo: z

    .number({ invalid_type_error: "Turma inválida" })

    .int("Turma inválida")

    .positive("Turma inválida"),

  dtCurso: dataBrObrigatoriaSchema("Data do curso"),

  jaFezCursoSenacSenai: z.boolean().optional().default(false),

  cursoSenacSenaiDescricao: textoOpcional(200, "Curso SENAC/SENAI"),

  possuiEncaminhamento: z.boolean().optional().default(false),

  orgaoEncaminhamento: textoOpcional(200, "Órgão de encaminhamento"),

  telefoneEncaminhamento: telefoneOpcional,

  possuiNecessidadeEspecial: z.boolean().optional().default(false),

  qualNecessidade: textoOpcional(500, "Necessidade especial"),

  fazAcompanhamentoMedico: z.boolean().optional().default(false),

  tomaMedicacao: z.boolean().optional().default(false),

  quaisMedicacoes: textoOpcional(500, "Medicações"),

  vacinacao: textoOpcional(500, "Vacinação"),

  alergias: textoOpcional(500, "Alergias"),

  rendaFamiliar: z.array(rendaFamiliarItemSchema).optional().default([]),

});



export const createInscricaoSchema = camposInscricaoSchema;



export const updateInscricaoSchema = camposInscricaoSchema

  .partial()

  .extend({

    alunoId: z.string().uuid("Aluno inválido").optional(),

    turmaCodigo: z

      .number({ invalid_type_error: "Turma inválida" })

      .int("Turma inválida")

      .positive("Turma inválida")

      .optional(),

    dtCurso: dataBrObrigatoriaSchema("Data do curso").optional(),

  })

  .refine((data) => Object.keys(data).length > 0, {

    message: "Informe ao menos um campo para atualizar",

  });



export type CreateInscricaoInput = z.infer<typeof createInscricaoSchema>;

export type UpdateInscricaoInput = z.infer<typeof updateInscricaoSchema>;

export type RendaFamiliarItemInput = z.infer<typeof rendaFamiliarItemSchema>;



export function parseDtCurso(value: string | null | undefined): Date | null {

  if (!value) return null;

  return parseDataBr(value);

}

