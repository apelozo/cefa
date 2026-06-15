import { z } from "zod";
import { parseDataBr } from "../lib/campo.js";
import { isValidCpf, normalizeCpf } from "../lib/cpf.js";
import { ESTADO_CIVIL_VOLUNTARIO_VALUES } from "../lib/estado-civil-voluntario.js";
import { emptyToNull, normalizeTelefone } from "../lib/pessoa-campos.js";
import { normalizeRg } from "../lib/rg.js";

const textoOpcional = (max: number, label: string) =>
  z
    .string()
    .max(max, `${label} muito longo`)
    .optional()
    .nullable()
    .transform((v) => emptyToNull(v ?? undefined));

const nomeSchema = z.string().trim().min(1, "Nome é obrigatório").max(200);

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

const dataBrOpcionalSchema = z
  .string()
  .optional()
  .nullable()
  .transform((v) => emptyToNull(v ?? undefined))
  .refine(
    (val) => {
      if (!val) return true;
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

const emailOpcional = z
  .string()
  .max(200, "E-mail muito longo")
  .optional()
  .nullable()
  .transform((v) => emptyToNull(v ?? undefined))
  .refine((v) => v === null || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), {
    message: "E-mail inválido",
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
  dtExpedicaoRg: dataBrOpcionalSchema,
  cpf: cpfOpcional,
  dtNascimento: dataBrObrigatoriaSchema("Data de nascimento"),
  nacionalidade: textoOpcional(100, "Nacionalidade"),
  naturalidadeCodigo: codigoCidadeOpcional,
  nomeMae: textoOpcional(200, "Nome da mãe"),
  nomePai: textoOpcional(200, "Nome do pai"),
  escolaridadeCodigo: escolaridadeCodigoOpcional,
  nomeUltimaEscola: textoOpcional(200, "Nome da última escola"),
  endereco: textoOpcional(200, "Endereço"),
  enderecoNumero: textoOpcional(20, "Número"),
  bairro: textoOpcional(100, "Bairro"),
  cep: cepOpcional,
  cidadeCodigo: codigoCidadeOpcional,
  telefone: telefoneOpcional,
  celular: telefoneOpcional,
  telefoneRecado: telefoneOpcional,
  email: emailOpcional,
});

export const createAlunoSchema = camposComunsSchema;

export const updateAlunoSchema = camposComunsSchema
  .partial()
  .extend({
    nome: nomeSchema.optional(),
    dtNascimento: dataBrObrigatoriaSchema("Data de nascimento").optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateAlunoInput = z.infer<typeof createAlunoSchema>;
export type UpdateAlunoInput = z.infer<typeof updateAlunoSchema>;

export function parseDataAlunoBr(
  value: string | null | undefined,
): Date | null {
  if (!value) return null;
  return parseDataBr(value);
}

export function parseDtNascimentoAluno(
  value: string | null | undefined,
): Date | null {
  return parseDataAlunoBr(value);
}

export function parseDtExpedicaoRgAluno(
  value: string | null | undefined,
): Date | null {
  return parseDataAlunoBr(value);
}
