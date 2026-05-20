import { PerfilTipoUsuario } from "@prisma/client";
import { z } from "zod";

export const createTipoUsuarioSchema = z.object({
  descricao: z.string().min(1).max(200),
  perfil: z.nativeEnum(PerfilTipoUsuario),
  ativo: z.boolean().optional().default(true),
});

export const updateTipoUsuarioSchema = z.object({
  descricao: z.string().min(1).max(200).optional(),
  perfil: z.nativeEnum(PerfilTipoUsuario).optional(),
  ativo: z.boolean().optional(),
});

export const permissoesBodySchema = z.object({
  permissoes: z.array(
    z.object({
      programaId: z.string().uuid(),
      podeIncluir: z.boolean(),
      podeAlterar: z.boolean(),
      podeConsultar: z.boolean(),
      podeExcluir: z.boolean(),
    }),
  ),
});

export type CreateTipoUsuarioInput = z.infer<typeof createTipoUsuarioSchema>;
export type UpdateTipoUsuarioInput = z.infer<typeof updateTipoUsuarioSchema>;
export type PermissoesBodyInput = z.infer<typeof permissoesBodySchema>;
