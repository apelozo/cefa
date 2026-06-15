import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  BairroConflictError,
  BairroInativoError,
  createBairro,
  getBairroById,
  listBairros,
  mapBairro,
  softDeleteBairro,
  updateBairro,
} from "../services/bairros.js";
import { createBairroSchema, updateBairroSchema } from "../validators/bairros.js";

export const bairrosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/bairros", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      nome?: string;
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

    const items = await listBairros({
      ativo,
      codigo,
      nome: query.nome,
    });
    return replyMappedList(reply, items, mapBairro);
  });

  app.get("/bairros/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getBairroById(id);
    if (!item) {
      return reply.status(404).send({ error: "Bairro não encontrado" });
    }
    return replyMapped(reply, item, mapBairro);
  });

  app.post("/bairros", async (request, reply) => {
    try {
      const body = createBairroSchema.parse(request.body);
      const item = await createBairro(body, request.usuarioId!);
      return replyMapped(reply, item, mapBairro, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof BairroConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/bairros/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateBairroSchema.parse(request.body);
      const item = await updateBairro(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Bairro não encontrado" });
      }
      return replyMapped(reply, item, mapBairro);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof BairroConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof BairroInativoError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.delete("/bairros/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await softDeleteBairro(id, request.usuarioId!);
    if (!item) {
      return reply.status(404).send({ error: "Bairro não encontrado" });
    }
    return replyMapped(reply, item, mapBairro);
  });
};
