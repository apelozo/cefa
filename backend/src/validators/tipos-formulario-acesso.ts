import { z } from "zod";

export const tiposFormularioAcessoBodySchema = z.object({
  tipoFormularioIds: z.array(z.string().uuid("tipoFormularioId inválido")),
});

export type TiposFormularioAcessoBodyInput = z.infer<
  typeof tiposFormularioAcessoBodySchema
>;
