import { z } from "zod";
import { parseDataBr } from "../lib/campo.js";
import { isValidCpf, normalizeCpf } from "../lib/cpf.js";
import { ESTADO_CIVIL_VOLUNTARIO_VALUES } from "../lib/estado-civil-voluntario.js";
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

const dataNascimentoOpcional = z
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

const cidadeCodigoOpcional = z
  .number({ invalid_type_error: "Código do município inválido" })
  .int("Código do município inválido")
  .positive("Código do município inválido")
  .optional()
  .nullable();

const estadoCivilOpcional = z
  .enum(ESTADO_CIVIL_VOLUNTARIO_VALUES, {
    errorMap: () => ({ message: "Estado civil inválido" }),
  })
  .optional()
  .nullable();

const valorContribuicaoOpcional = z
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

const diaVencimentoOpcional = z
  .number({ invalid_type_error: "Dia de vencimento inválido" })
  .int("Dia de vencimento inválido")
  .min(1, "Dia de vencimento deve ser entre 1 e 31")
  .max(31, "Dia de vencimento deve ser entre 1 e 31")
  .optional()
  .nullable();

const tempoTrabalhoCentroOpcional = z
  .number({ invalid_type_error: "Tempo no centro inválido" })
  .int("Tempo no centro inválido")
  .min(0, "Tempo no centro não pode ser negativo")
  .max(100, "Tempo no centro muito alto")
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

const camposVoluntario = {
  empresa: textoOpcional(200, "Empresa"),
  funcao: textoOpcional(200, "Função"),
  estadoCivil: estadoCivilOpcional,
  dtNascimento: dataNascimentoOpcional,
  endereco: textoOpcional(200, "Endereço"),
  enderecoNumero: textoOpcional(20, "Número"),
  bairro: textoOpcional(100, "Bairro"),
  cep: cepOpcional,
  cidadeCodigo: cidadeCodigoOpcional,
  enderecoComplemento: textoOpcional(100, "Complemento"),
  rg: rgOpcional,
  cpf: cpfOpcional,
  cnh: textoOpcional(30, "CNH"),
  celular: telefoneOpcional,
  telefoneResidencial: telefoneOpcional,
  telefoneComercial: telefoneOpcional,
  email: emailOpcional,
  valorContribuicao: valorContribuicaoOpcional,
  diaVencimento: diaVencimentoOpcional,
  tempoTrabalhoCentro: tempoTrabalhoCentroOpcional,
  nome: z
    .string()
    .trim()
    .min(1, "Nome é obrigatório")
    .max(200, "Nome muito longo"),
  nomeCracha: z
    .string()
    .trim()
    .min(1, "Nome no crachá é obrigatório")
    .max(200, "Nome no crachá muito longo"),
  fichaMedica: textoOpcional(1000, "Ficha médica"),
};

export const createVoluntarioSchema = z.object(camposVoluntario);

export const updateVoluntarioSchema = z
  .object({
    ...camposVoluntario,
    nome: camposVoluntario.nome.optional(),
    nomeCracha: camposVoluntario.nomeCracha.optional(),
    ativo: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "Informe ao menos um campo para atualizar",
  });

export type CreateVoluntarioInput = z.infer<typeof createVoluntarioSchema>;
export type UpdateVoluntarioInput = z.infer<typeof updateVoluntarioSchema>;

export function parseDtNascimentoVoluntario(value: string | null | undefined) {
  if (!value) return null;
  return parseDataBr(value);
}
