import type { FastifyPluginAsync } from "fastify";
import { ZodError } from "zod";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import {
  createTipoFormulario,
  getTipoFormularioById,
  listTiposFormulario,
  mapTipoFormulario,
  deleteTipoFormulario,
  updateTipoFormulario,
} from "../services/tipos-formulario.js";
import {
  createTipoFormularioSchema,
  updateTipoFormularioSchema,
} from "../validators/tipos-formulario.js";

export const tiposFormularioRoutes: FastifyPluginAsync = async (app) => {
  app.get("/tipos-formulario", async (request, reply) => {
    const query = request.query as { ativo?: string };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listTiposFormulario(ativo);
    return reply.send(items.map(mapTipoFormulario));
  });

  app.get("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getTipoFormularioById(id);
    if (!item) {
      return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
    }
    return reply.send(mapTipoFormulario(item));
  });

  app.post("/tipos-formulario", async (request, reply) => {
    try {
      const body = createTipoFormularioSchema.parse(request.body);
      const item = await createTipoFormulario(body, request.usuarioId!);
      return reply.status(201).send(mapTipoFormulario(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      throw err;
    }
  });

  app.put("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateTipoFormularioSchema.parse(request.body);
      const item = await updateTipoFormulario(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
      }
      return reply.send(mapTipoFormulario(item));
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      throw err;
    }
  });

  app.delete("/tipos-formulario/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteTipoFormulario(id);
      if (!item) {
        return reply.status(404).send({ error: "Tipo de formulário não encontrado" });
      }
      return reply.send(mapTipoFormulario(item));
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
