import { z } from "zod";

export const createUsuarioSchema = z.object({
  nomeUsuario: z
    .string()
    .min(3)
    .max(50)
    .regex(/^[a-zA-Z0-9._-]+$/, "Nome de usuário inválido"),
  nome: z.string().min(1).max(200),
  email: z.string().email().max(200),
  senha: z.string().min(6).max(100),
  tipoUsuarioId: z.string().uuid(),
  ativo: z.boolean().optional().default(true),
});

export const updateUsuarioSchema = z.object({
  nomeUsuario: z
    .string()
    .min(3)
    .max(50)
    .regex(/^[a-zA-Z0-9._-]+$/)
    .optional(),
  nome: z.string().min(1).max(200).optional(),
  email: z.string().email().max(200).optional(),
  senha: z.string().min(6).max(100).optional(),
  tipoUsuarioId: z.string().uuid().optional(),
  ativo: z.boolean().optional(),
});

export const loginSchema = z.object({
  nomeUsuario: z.string().min(1),
  senha: z.string().min(1),
});

export type CreateUsuarioInput = z.infer<typeof createUsuarioSchema>;
export type UpdateUsuarioInput = z.infer<typeof updateUsuarioSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
