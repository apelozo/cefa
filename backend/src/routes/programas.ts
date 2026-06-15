import type { FastifyPluginAsync } from "fastify";
import { replyMapped, replyMappedList } from "../lib/resposta-api.js";
import { ZodError } from "zod";
import {
  createPrograma,
  getProgramaById,
  listProgramas,
  mapPrograma,
  ProgramaConflictError,
  ProgramaReferenciaError,
  updatePrograma,
} from "../services/programas.js";
import {
  createProgramaSchema,
  updateProgramaSchema,
} from "../validators/programas.js";

export const programasRoutes: FastifyPluginAsync = async (app) => {
  app.get("/programas", async (_request, reply) => {
    const items = await listProgramas();
    return replyMappedList(reply, items, mapPrograma);
  });

  app.get("/programas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await getProgramaById(id);
    if (!item) {
      return reply.status(404).send({ error: "Programa não encontrado" });
    }
    return replyMapped(reply, item, mapPrograma);
  });

  app.post("/programas", async (request, reply) => {
    try {
      const body = createProgramaSchema.parse(request.body);
      const item = await createPrograma(body, request.usuarioId!);
      return replyMapped(reply, item, mapPrograma, 201);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof ProgramaConflictError) {
        return reply.status(409).send({ error: err.message });
      }
      if (err instanceof ProgramaReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });

  app.put("/programas/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    try {
      const body = updateProgramaSchema.parse(request.body);
      const item = await updatePrograma(id, body, request.usuarioId!);
      if (!item) {
        return reply.status(404).send({ error: "Programa não encontrado" });
      }
      return replyMapped(reply, item, mapPrograma);
    } catch (err) {
      if (err instanceof ZodError) {
        return reply.status(400).send({
          error: "Validação falhou",
          details: err.flatten(),
        });
      }
      if (err instanceof ProgramaReferenciaError) {
        return reply.status(400).send({ error: err.message });
      }
      throw err;
    }
  });
};
