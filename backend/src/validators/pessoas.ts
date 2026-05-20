import { z } from "zod";
import { parseDataBr } from "../lib/campo.js";
import { isValidCpf, normalizeCpf } from "../lib/cpf.js";
import {
  emptyToNull,
  normalizeNis,
  normalizeTelefone,
  URBANO_RURAL_VALUES,
} from "../lib/pessoa-campos.js";
import { normalizeRg } from "../lib/rg.js";

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

const cpfSchema = z
  .string()
  .trim()
  .min(1, "CPF é obrigatório")
  .transform(normalizeCpf)
  .refine((cpf) => cpf.length === 11, { message: "CPF deve ter 11 dígitos" })
  .refine(isValidCpf, { message: "CPF inválido" });

const textoOpcional = (max: number, label: string) =>
  z
    .string()
    .max(max, `${label} muito longo`)
    .optional()
    .nullable()
    .transform((v) => emptyToNull(v ?? undefined));

const bairroCodigoOpcional = z
  .number({ invalid_type_error: "Código do bairro inválido" })
  .int("Código do bairro inválido")
  .positive("Código do bairro inválido")
  .optional()
  .nullable();

const cidadeCodigoOpcional = z
  .number({ invalid_type_error: "Código do município inválido" })
  .int("Código do município inválido")
  .positive("Código do município inválido")
  .optional()
  .nullable();

const nisOpcional = z
  .string()
  .optional()
  .nullable()
  .transform((v) => {
    const n = emptyToNull(v ?? undefined);
    if (!n) return null;
    const digits = normalizeNis(n);
    return digits.length > 0 ? digits : null;
  })
  .refine((v) => v === null || v.length === 11, {
    message: "NIS deve ter 11 dígitos",
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

const urbanoRuralOpcional = z
  .enum(URBANO_RURAL_VALUES, { errorMap: () => ({ message: "Valor inválido" }) })
  .optional()
  .nullable();

const camposOpcionaisPessoa = {
  nomeSocial: textoOpcional(200, "Nome social"),
  nomeMae: textoOpcional(200, "Nome da mãe"),
  nomePai: textoOpcional(200, "Nome do pai"),
  nis: nisOpcional,
  rgOrgaoEmissao: textoOpcional(50, "Órgão emissor do RG"),
  endereco: textoOpcional(200, "Endereço"),
  enderecoNumero: textoOpcional(20, "Número"),
  enderecoComplemento: textoOpcional(100, "Complemento"),
  bairroCodigo: bairroCodigoOpcional,
  cidadeCodigo: cidadeCodigoOpcional,
  telefone: telefoneOpcional,
  telefone2: telefoneOpcional,
  urbanoRural: urbanoRuralOpcional,
};

export const createPessoaSchema = z.object({
  nome: z.string().trim().min(1, "Nome é obrigatório"),
  dtNascimento: dataNascimentoSchema,
  cpf: cpfSchema,
  rg: z
    .string()
    .trim()
    .min(1, "RG é obrigatório")
    .max(20, "RG muito longo")
    .transform(normalizeRg)
    .refine((rg) => rg.length >= 4, { message: "RG inválido" }),
  ativo: z.boolean().optional().default(true),
  ...camposOpcionaisPessoa,
});

export const updatePessoaSchema = z
  .object({
    nome: z.string().trim().min(1).optional(),
    dtNascimento: dataNascimentoSchema.optional(),
    cpf: cpfSchema.optional(),
    rg: z
      .string()
      .trim()
      .min(1)
      .max(20)
      .transform(normalizeRg)
      .refine((rg) => rg.length >= 4)
      .optional(),
    ativo: z.boolean().optional(),
    ...camposOpcionaisPessoa,
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreatePessoaInput = z.infer<typeof createPessoaSchema>;
export type UpdatePessoaInput = z.infer<typeof updatePessoaSchema>;

export function parseDtNascimento(input: string): Date {
  return parseDataBr(input);
}
