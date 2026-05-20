import {
  EscolaridadeFamiliar,
  OcupacaoFamiliar,
  RespostaSimNao,
  TipoDeficienciaFamiliar,
} from "@prisma/client";
import { z } from "zod";
import { parseDataBr } from "../lib/campo.js";
import { isValidCpf, normalizeCpf } from "../lib/cpf.js";
import { ESCOLARIDADES_FAMILIAR } from "../lib/escolaridade-familiar.js";
import { OCUPACOES_FAMILIAR } from "../lib/ocupacao-familiar.js";
import { RESPOSTAS_SIM_NAO } from "../lib/resposta-sim-nao.js";
import { TIPOS_DEFICIENCIA_FAMILIAR } from "../lib/tipo-deficiencia-familiar.js";
import { emptyToNull, parseMoedaBr } from "../lib/pessoa-campos.js";

const OCUPACAO_VALUES = OCUPACOES_FAMILIAR.map((o) => o.valor) as [
  OcupacaoFamiliar,
  ...OcupacaoFamiliar[],
];

const ESCOLARIDADE_VALUES = ESCOLARIDADES_FAMILIAR.map((e) => e.valor) as [
  EscolaridadeFamiliar,
  ...EscolaridadeFamiliar[],
];

const TIPO_DEFICIENCIA_VALUES = TIPOS_DEFICIENCIA_FAMILIAR.map((t) => t.valor) as [
  TipoDeficienciaFamiliar,
  ...TipoDeficienciaFamiliar[],
];

const respostaSimNaoSchema = z.enum(RESPOSTAS_SIM_NAO, {
  errorMap: () => ({ message: "Resposta inválida (use Sim ou Não)" }),
});

const respostaSimNaoOpcional = respostaSimNaoSchema.optional().nullable();

const dataNascimentoSchema = z
  .string()
  .trim()
  .min(1, "Data de nascimento é obrigatória")
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

const cpfOpcionalComposicao = z
  .string()
  .optional()
  .nullable()
  .transform((v) => {
    const n = emptyToNull(v ?? undefined);
    if (!n) return null;
    return normalizeCpf(n);
  })
  .refine((cpf) => cpf === null || cpf.length === 11, {
    message: "CPF deve ter 11 dígitos",
  })
  .refine((cpf) => cpf === null || isValidCpf(cpf), { message: "CPF inválido" });

const textoOpcional = (max: number, label: string) =>
  z
    .string()
    .max(max, `${label} muito longo`)
    .optional()
    .nullable()
    .transform((v) => emptyToNull(v ?? undefined));

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

export const composicaoFamiliarItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  cpf: cpfOpcionalComposicao,
  dtNascimento: dataNascimentoSchema,
  parentesco: z.string().trim().min(1, "Parentesco é obrigatório"),
});

export const condicaoTrabalhoItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  ocupacao: z.enum(OCUPACAO_VALUES, {
    errorMap: () => ({ message: "Ocupação inválida" }),
  }),
  condicoesTrabalho: textoOpcional(500, "Condições de trabalho"),
  vrBeneficioSocial: moedaSchema,
  rendaMensal: moedaSchema,
});

export const condicaoEducacionalItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  idade: z
    .union([z.number(), z.string()])
    .transform((v, ctx) => {
      const n = typeof v === "number" ? v : parseInt(String(v).trim(), 10);
      if (!Number.isFinite(n) || n < 0 || n > 150) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Idade inválida (0 a 150)",
        });
        return z.NEVER;
      }
      return n;
    }),
  escolaridade: z.enum(ESCOLARIDADE_VALUES, {
    errorMap: () => ({ message: "Escolaridade inválida" }),
  }),
  sabeLerEscrever: z.boolean().optional().default(false),
  frequentaEscola: z.boolean().optional().default(false),
});

export const deficienciaFamiliarItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  tipoDeficiencia: z.enum(TIPO_DEFICIENCIA_VALUES, {
    errorMap: () => ({ message: "Tipo de deficiência inválido" }),
  }),
  necessitaCuidadosConstantes: z.boolean().optional().default(false),
  quemECuidador: textoOpcional(500, "Quem é o cuidador"),
});

const mesesGestacaoSchema = z
  .union([z.number(), z.string()])
  .transform((v) => {
    if (v === undefined || v === null || v === "") return NaN;
    const n = typeof v === "number" ? v : parseInt(String(v).trim(), 10);
    return Number.isFinite(n) ? n : NaN;
  })
  .pipe(
    z
      .number()
      .int()
      .min(0)
      .max(10, { message: "Informe os meses de gestação (0 a 10)" }),
  );

export const gestanteFamiliarItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  mesesGestacao: mesesGestacaoSchema,
  iniciouPreNatal: respostaSimNaoSchema,
});

export const programasSociaisSchema = z
  .object({
    bolsaFamilia: z.boolean().optional().default(false),
    peti: z.boolean().optional().default(false),
    bpc: z.boolean().optional().default(false),
    outrosProgramas: z.boolean().optional().default(false),
    outrosProgramasSociais: textoOpcional(30, "Outros programas"),
    cras: z.boolean().optional().default(false),
    centroPop: z.boolean().optional().default(false),
    conselhoTutelar: z.boolean().optional().default(false),
    ubs: z.boolean().optional().default(false),
    creas: z.boolean().optional().default(false),
    caps: z.boolean().optional().default(false),
    craf: z.boolean().optional().default(false),
    outrosAtendimentoFamilia: z.boolean().optional().default(false),
    outrosOrgaosSociais: textoOpcional(30, "Outros órgãos"),
  })
  .default({})
  .superRefine((data, ctx) => {
    if (data.outrosProgramas) {
      const t = data.outrosProgramasSociais?.trim() ?? "";
      if (t.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Informe a descrição quando selecionar Outros Programas",
          path: ["outrosProgramasSociais"],
        });
      }
    }
    if (!data.outrosProgramas && data.outrosProgramasSociais) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          "Descrição de Outros Programas só é permitida quando a opção estiver marcada",
        path: ["outrosProgramasSociais"],
      });
    }

    if (data.outrosAtendimentoFamilia) {
      const t = data.outrosOrgaosSociais?.trim() ?? "";
      if (t.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Informe a descrição quando selecionar Outros órgãos",
          path: ["outrosOrgaosSociais"],
        });
      }
    }
    if (!data.outrosAtendimentoFamilia && data.outrosOrgaosSociais) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          "Descrição de Outros órgãos só é permitida quando a opção estiver marcada",
        path: ["outrosOrgaosSociais"],
      });
    }
  });

export const saudeFamiliaSchema = z
  .object({
    remediosControladosMental: respostaSimNaoOpcional,
    remediosControladosQuais: textoOpcional(500, "Quais remédios"),
    usoAbusivoAlcool: respostaSimNaoOpcional,
    usoAbusivoDrogas: respostaSimNaoOpcional,
    usoAbusivoDrogasQuais: textoOpcional(500, "Quais drogas"),
    temGestante: respostaSimNaoOpcional,
  })
  .default({})
  .superRefine((data, ctx) => {
    if (data.remediosControladosMental === "SIM") {
      const q = data.remediosControladosQuais?.trim() ?? "";
      if (q.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Informe quais remédios",
          path: ["remediosControladosQuais"],
        });
      }
    }
    if (data.remediosControladosMental !== "SIM" && data.remediosControladosQuais) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Quais remédios só é permitido quando a resposta for Sim",
        path: ["remediosControladosQuais"],
      });
    }

    if (data.usoAbusivoDrogas === "SIM") {
      const q = data.usoAbusivoDrogasQuais?.trim() ?? "";
      if (q.length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "Informe quais drogas",
          path: ["usoAbusivoDrogasQuais"],
        });
      }
    }
    if (data.usoAbusivoDrogas !== "SIM" && data.usoAbusivoDrogasQuais) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Quais drogas só é permitido quando a resposta for Sim",
        path: ["usoAbusivoDrogasQuais"],
      });
    }

  });
