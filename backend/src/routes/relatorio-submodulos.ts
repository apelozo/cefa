import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { DeleteBlockedError } from "../lib/delete-guard.js";
import { ZodError } from "zod";
import {
  RelatorioSubmoduloConflictError,
  createRelatorioSubmodulo,
  deleteRelatorioSubmodulo,
  getRelatorioSubmoduloById,
  listRelatorioSubmodulos,
  mapRelatorioSubmodulo,
  updateRelatorioSubmodulo,
} from "../services/relatorio-submodulos.js";
import {
  createRelatorioSubmoduloSchema,
  updateRelatorioSubmoduloSchema,
} from "../validators/relatorio-submodulos.js";

export const relatorioSubmodulosRoutes: FastifyPluginAsync = async (app) => {
  app.get("/relatorio-submodulos", async (request, reply) => {
    const query = request.query as {
      ativo?: string;
      codigo?: string;
      nome?: string;
    };
    let ativo: boolean | undefined;
    if (query.ativo === "true") ativo = true;
    else if (query.ativo === "false") ativo = false;

    const items = await listRelatorioSubmodulos({
      ativo,
      codigo: query.codigo,
      nome: query.nome,
    });
    return replyMappedList(reply, items, mapRelatorioSubmodulo);
  });

  app.get("/relatorio-submodulos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getRelatorioSubmoduloById(id);
    if (!item) {
      return reply.status(404).send({ error: "Submódulo não encontrado" });
    }
    return replyMapped(reply, item, mapRelatorioSubmodulo);
  });

  app.post("/relatorio-submodulos", async (request, reply) => {
    try {
      const body = createRelatorioSubmoduloSchema.parse(request.body);
      const item = await createRelatorioSubmodulo(body, request.usuarioId!);
      return replyMapped(reply, item, mapRelatorioSubmodulo, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof RelatorioSubmoduloConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/relatorio-submodulos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateRelatorioSubmoduloSchema.parse(request.body);
      const item = await updateRelatorioSubmodulo(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Submódulo não encontrado" });
      }
      return replyMapped(reply, item, mapRelatorioSubmodulo);
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

  app.delete("/relatorio-submodulos/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const item = await deleteRelatorioSubmodulo(id);
      if (!item) {
        return reply.status(404).send({ error: "Submódulo não encontrado" });
      }
      return replyMapped(reply, item, mapRelatorioSubmodulo);
    } catch (err) {
      if (err instanceof DeleteBlockedError) {
        return reply.status(409).send({ error: err.message });
      }
      throw err;
    }
  });
};
