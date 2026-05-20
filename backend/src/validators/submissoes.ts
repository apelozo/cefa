import { z } from "zod";
import { countValoresPreenchidos } from "../lib/campo.js";

export const respostaItemSchema = z
  .object({
    perguntaId: z.string().uuid(),
    valorInteiro: z.number().int().optional(),
    valorDecimal: z.union([z.number(), z.string()]).optional(),
    valorTexto: z.string().optional(),
    valorLogico: z.boolean().optional(),
    valorData: z.string().optional(),
    valorOpcaoId: z.string().uuid().optional(),
  })
  .superRefine((data, ctx) => {
    const filled = countValoresPreenchidos(data);
    if (filled > 1) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          "Informe no máximo um valor por pergunta (inteiro, decimal, texto, lógico, data ou opção de lista)",
      });
    }
  });

export const createSubmissaoSchema = z.object({
  tipoFormularioId: z.string().uuid("tipoFormularioId inválido"),
  pessoaId: z.string().uuid("pessoaId inválido"),
  respostas: z.array(respostaItemSchema),
});

export type CreateSubmissaoInput = z.infer<typeof createSubmissaoSchema>;
