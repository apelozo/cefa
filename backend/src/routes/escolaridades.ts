import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  EscolaridadeConflictError,
  EscolaridadeInativaError,
  createEscolaridade,
  getEscolaridadeById,
  listEscolaridades,
  mapEscolaridade,
  softDeleteEscolaridade,
  updateEscolaridade,
} from "../services/escolaridades.js";
import {
  createEscolaridadeSchema,
  updateEscolaridadeSchema,
} from "../validators/escolaridades.js";

export const escolaridadesRoutes: FastifyPluginAsync = async (app) => {
  app.get("/escolaridades", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      descricao?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    let codigo: number | undefined;
    if (query.codigo?.trim()) {
      const parsed = Number.parseInt(query.codigo.trim(), 10);
      if (!Number.isNaN(parsed) && parsed > 0) {
        codigo = parsed;
      }
    }

    const items = await listEscolaridades({
      ativo,
      codigo,
      descricao: query.descricao,
    });
    return replyMappedList(reply, items, mapEscolaridade);
  });

  app.get("/escolaridades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getEscolaridadeById(id);
    if (!item) {
      return reply.status(404).send({ error: "Escolaridade não encontrada" });
    }
    return replyMapped(reply, item, mapEscolaridade);
  });

  app.post("/escolaridades", async (request, reply) => {
    try {
      const body = createEscolaridadeSchema.parse(request.body);
      const item = await createEscolaridade(body, request.usuarioId!);
      return replyMapped(reply, item, mapEscolaridade, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof EscolaridadeConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/escolaridades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateEscolaridadeSchema.parse(request.body);
      const item = await updateEscolaridade(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Escolaridade não encontrada" });
      }
      return replyMapped(reply, item, mapEscolaridade);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof EscolaridadeConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof EscolaridadeInativaError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/escolaridades/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await softDeleteEscolaridade(id, request.usuarioId!);
    if (!item) {
      return reply.status(404).send({ error: "Escolaridade não encontrada" });
    }
    return replyMapped(reply, item, mapEscolaridade);
  });
};
