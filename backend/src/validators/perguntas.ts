import { z } from "zod";

import {
  MAX_LINHAS_CAMPO,
  MAX_TAMANHO_TEXTO,
  MIN_LINHAS_CAMPO,
} from "../lib/campo.js";



export const tipoCampoSchema = z.enum([

  "INTEIRO",

  "DECIMAL",

  "TEXTO",

  "LOGICO",

  "DATA",

  "LISTA",

]);



export const opcaoPerguntaSchema = z.object({

  id: z.string().uuid().optional(),

  rotulo: z.string().trim().min(1, "Rótulo da opção é obrigatório"),

  ordem: z.number().int().min(0).optional().default(0),

  ativo: z.boolean().optional().default(true),

});



function refineOpcoesLista(

  tipoCampo: string,

  opcoes: z.infer<typeof opcaoPerguntaSchema>[] | undefined,

  ctx: z.RefinementCtx,

  pathPrefix = "opcoes",

) {

  if (tipoCampo !== "LISTA") {

    if (opcoes !== undefined && opcoes.length > 0) {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "opcoes só se aplica ao tipo LISTA",

        path: [pathPrefix],

      });

    }

    return;

  }

  if (!opcoes || opcoes.length === 0) {

    ctx.addIssue({

      code: z.ZodIssueCode.custom,

      message: "Informe ao menos uma opção para tipo LISTA",

      path: [pathPrefix],

    });

    return;

  }

  const ativas = opcoes.filter((o) => o.ativo !== false);

  if (ativas.length === 0) {

    ctx.addIssue({

      code: z.ZodIssueCode.custom,

      message: "Informe ao menos uma opção ativa",

      path: [pathPrefix],

    });

  }

}



const perguntaBaseSchema = z.object({

  enunciado: z.string().trim().min(1, "Enunciado é obrigatório"),

  tipoCampo: tipoCampoSchema,

  tipoFormularioId: z.string().uuid("tipoFormularioId inválido"),

  tamanhoCampo: z.number().int().min(1).max(MAX_TAMANHO_TEXTO).optional(),

  linhasCampo: z
    .number()
    .int()
    .min(MIN_LINHAS_CAMPO)
    .max(MAX_LINHAS_CAMPO)
    .optional(),

  ordem: z.number().int().min(0).optional().default(0),

  ativo: z.boolean().optional().default(true),

  opcoes: z.array(opcaoPerguntaSchema).optional(),

});



export const createPerguntaSchema = perguntaBaseSchema.superRefine((data, ctx) => {

  if (data.tipoCampo === "TEXTO") {

    if (data.tamanhoCampo === undefined) {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "tamanhoCampo é obrigatório para tipo TEXTO",

        path: ["tamanhoCampo"],

      });

    }

    if (data.linhasCampo === undefined) {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "linhasCampo é obrigatório para tipo TEXTO",

        path: ["linhasCampo"],

      });

    }

  } else {

    if (data.tamanhoCampo !== undefined) {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "tamanhoCampo só se aplica ao tipo TEXTO",

        path: ["tamanhoCampo"],

      });

    }

    if (data.linhasCampo !== undefined) {

      ctx.addIssue({

        code: z.ZodIssueCode.custom,

        message: "linhasCampo só se aplica ao tipo TEXTO",

        path: ["linhasCampo"],

      });

    }

  }

  refineOpcoesLista(data.tipoCampo, data.opcoes, ctx);

});



export const updatePerguntaSchema = z

  .object({

    enunciado: z.string().trim().min(1).optional(),

    tipoCampo: tipoCampoSchema.optional(),

    tipoFormularioId: z.string().uuid().optional(),

    tamanhoCampo: z.number().int().min(1).max(MAX_TAMANHO_TEXTO).nullable().optional(),

    linhasCampo: z
      .number()
      .int()
      .min(MIN_LINHAS_CAMPO)
      .max(MAX_LINHAS_CAMPO)
      .nullable()
      .optional(),

    ordem: z.number().int().min(0).optional(),

    ativo: z.boolean().optional(),

    opcoes: z.array(opcaoPerguntaSchema).optional(),

  })

  .refine((data) => Object.keys(data).length > 0, {

    message: "Informe ao menos um campo para atualizar",

  })

  .superRefine((data, ctx) => {

    if (data.tipoCampo !== undefined) {

      refineOpcoesLista(data.tipoCampo, data.opcoes, ctx);

    } else if (data.opcoes !== undefined) {

      refineOpcoesLista("LISTA", data.opcoes, ctx);

    }

  });



export type CreatePerguntaInput = z.infer<typeof createPerguntaSchema>;

export type UpdatePerguntaInput = z.infer<typeof updatePerguntaSchema>;

export type OpcaoPerguntaInput = z.infer<typeof opcaoPerguntaSchema>;


