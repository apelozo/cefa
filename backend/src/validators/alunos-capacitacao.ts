import { z } from "zod";
import { parseDataBr } from "../lib/campo.js";
import { isValidCpf, normalizeCpf } from "../lib/cpf.js";
import { ESTADO_CIVIL_VOLUNTARIO_VALUES } from "../lib/estado-civil-voluntario.js";
import { TIPO_CASA_ALUNO_CAPACITACAO_VALUES } from "../lib/tipo-casa-aluno-capacitacao.js";
import {
  emptyToNull,
  normalizeTelefone,
  parseMoedaBr,
} from "../lib/pessoa-campos.js";
import { normalizeRg } from "../lib/rg.js";

const textoOpcional = (max: number, label: string) =>
  z
    .string()
    .max(max, `${label} muito longo`)
    .optional()
    .nullable()
    .transform((v) => emptyToNull(v ?? undefined));

const nomeSchema = z.string().trim().min(1, "Nome é obrigatório").max(200);

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

const cpfOpcional = z
  .string()
  .optional()
  .nullable()
  .transform((v) => {
    const n = emptyToNull(v ?? undefined);
    if (!n) return null;
    return normalizeCpf(n);
  })
  .refine((v) => v === null || v.length === 11, {
    message: "CPF deve ter 11 dígitos",
  })
  .refine((v) => v === null || isValidCpf(v), { message: "CPF inválido" });

const rgOpcional = z
  .string()
  .optional()
  .nullable()
  .transform((v) => {
    const n = emptyToNull(v ?? undefined);
    if (!n) return null;
    const digits = normalizeRg(n);
    return digits.length > 0 ? digits : null;
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

const cepOpcional = z
  .string()
  .optional()
  .nullable()
  .transform((v) => {
    const n = emptyToNull(v ?? undefined);
    if (!n) return null;
    const digits = n.replace(/\D/g, "");
    return digits.length > 0 ? digits : null;
  })
  .refine((v) => v === null || v.length === 8, {
    message: "CEP deve ter 8 dígitos",
  });

const codigoCidadeOpcional = z
  .number({ invalid_type_error: "Código do município inválido" })
  .int("Código do município inválido")
  .positive("Código do município inválido")
  .optional()
  .nullable();

const escolaridadeCodigoOpcional = z
  .number({ invalid_type_error: "Código da escolaridade inválido" })
  .int("Código da escolaridade inválido")
  .positive("Código da escolaridade inválido")
  .optional()
  .nullable();

const valorAluguelOpcional = z
  .union([z.number(), z.string()])
  .optional()
  .nullable()
  .transform((v) => {
    if (v === undefined || v === null) return null;
    if (typeof v === "number") {
      if (!Number.isFinite(v) || v < 0) return null;
      return v;
    }
    const t = v.trim();
    if (!t) return null;
    return parseMoedaBr(t);
  });

const rendaFamiliarItemSchema = z.object({
  nome: z.string().trim().min(1, "Nome do integrante é obrigatório").max(200),
  idade: z
    .number({ invalid_type_error: "Idade inválida" })
    .int("Idade inválida")
    .min(0, "Idade inválida")
    .max(150, "Idade inválida")
    .optional()
    .nullable(),
  renda: z
    .union([z.number(), z.string()])
    .optional()
    .nullable()
    .transform((v) => {
      if (v === undefined || v === null) return 0;
      if (typeof v === "number") return Number.isFinite(v) && v >= 0 ? v : 0;
      const t = String(v).trim();
      if (!t) return 0;
      return parseMoedaBr(t);
    }),
  parentesco: textoOpcional(100, "Parentesco"),
  profissao: textoOpcional(200, "Profissão"),
});

const camposComunsSchema = z.object({
  nome: nomeSchema,
  nomeSocial: textoOpcional(200, "Nome social"),
  estadoCivil: z
    .enum(ESTADO_CIVIL_VOLUNTARIO_VALUES, {
      errorMap: () => ({ message: "Estado civil inválido" }),
    })
    .optional()
    .nullable(),
  rg: rgOpcional,
  orgaoExpedidor: textoOpcional(50, "Órgão expedidor"),
  cpf: cpfOpcional,
  dtNascimento: dataNascimentoSchema,
  nacionalidade: textoOpcional(100, "Nacionalidade"),
  naturalidadeCodigo: codigoCidadeOpcional,
  nomeMae: textoOpcional(200, "Nome da mãe"),
  nomePai: textoOpcional(200, "Nome do pai"),
  escolaridadeCodigo: escolaridadeCodigoOpcional,
  nomeUltimaEscola: textoOpcional(200, "Nome da última escola"),
  endereco: textoOpcional(300, "Endereço"),
  enderecoNumero: textoOpcional(20, "Número"),
  bairro: textoOpcional(100, "Bairro"),
  cep: cepOpcional,
  cidadeCodigo: codigoCidadeOpcional,
  tipoCasa: z
    .enum(TIPO_CASA_ALUNO_CAPACITACAO_VALUES, {
      errorMap: () => ({ message: "Tipo de casa inválido" }),
    })
    .optional()
    .nullable(),
  valorAluguel: valorAluguelOpcional,
  telefone: telefoneOpcional,
  celular: telefoneOpcional,
  telefoneRecado: telefoneOpcional,
  email: textoOpcional(200, "E-mail"),
  redeSocial: textoOpcional(200, "Rede social"),
  jaFezCursoSenacSenai: z.boolean().optional().default(false),
  cursoSenacSenaiDescricao: textoOpcional(300, "Curso Senac/Senai"),
  cursoSenacSenaiAno: z
    .number({ invalid_type_error: "Ano inválido" })
    .int("Ano inválido")
    .min(1900, "Ano inválido")
    .max(2100, "Ano inválido")
    .optional()
    .nullable(),
  encaminhamento: textoOpcional(300, "Encaminhamento"),
  telefoneEncaminhamento: telefoneOpcional,
  possuiNecessidadeEspecial: z.boolean().optional().default(false),
  qualNecessidade: textoOpcional(500, "Necessidade especial"),
  fazAcompanhamentoMedico: z.boolean().optional().default(false),
  tomaMedicacao: textoOpcional(500, "Medicação"),
  vacinacao: textoOpcional(500, "Vacinação"),
  alergias: textoOpcional(500, "Alergias"),
  rendasFamiliares: z.array(rendaFamiliarItemSchema).optional().default([]),
});

function validarCondicionais(
  data: z.infer<typeof camposComunsSchema>,
  ctx: z.RefinementCtx,
) {
  if (data.tipoCasa === "ALUGUEL") {
    if (data.valorAluguel == null || data.valorAluguel <= 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Informe o valor do aluguel",
        path: ["valorAluguel"],
      });
    }
  }
  if (data.jaFezCursoSenacSenai) {
    if (!data.cursoSenacSenaiDescricao) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Informe o curso realizado",
        path: ["cursoSenacSenaiDescricao"],
      });
    }
    if (data.cursoSenacSenaiAno == null) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "Informe o ano do curso",
        path: ["cursoSenacSenaiAno"],
      });
    }
  }
  if (data.possuiNecessidadeEspecial && !data.qualNecessidade) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Descreva a necessidade especial",
      path: ["qualNecessidade"],
    });
  }
  if (data.fazAcompanhamentoMedico && !data.tomaMedicacao) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Informe a medicação",
      path: ["tomaMedicacao"],
    });
  }
}

export const createAlunoCapacitacaoSchema = camposComunsSchema.superRefine(
  validarCondicionais,
);

export const updateAlunoCapacitacaoSchema = camposComunsSchema
  .partial()
  .extend({
    nome: nomeSchema.optional(),
    dtNascimento: dataNascimentoSchema.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  })
  .superRefine((data, ctx) => {
    validarCondicionais(
      {
        ...data,
        jaFezCursoSenacSenai: data.jaFezCursoSenacSenai ?? false,
        possuiNecessidadeEspecial: data.possuiNecessidadeEspecial ?? false,
        fazAcompanhamentoMedico: data.fazAcompanhamentoMedico ?? false,
        rendasFamiliares: data.rendasFamiliares ?? [],
      } as z.infer<typeof camposComunsSchema>,
      ctx,
    );
  });

export type CreateAlunoCapacitacaoInput = z.infer<
  typeof createAlunoCapacitacaoSchema
>;
export type UpdateAlunoCapacitacaoInput = z.infer<
  typeof updateAlunoCapacitacaoSchema
>;

export function parseDtNascimentoAlunoCapacitacao(
  value: string | null | undefined,
): Date | null {
  if (!value) return null;
  return parseDataBr(value);
}
